//! End-to-end tests: create a user, log in, then ask for a program.
//!
//! They go through the real router (handlers, services, repositories, JWT, rate
//! limiter) with a real temporary database. Only the Python ML engine is replaced
//! by a small axum server started on `127.0.0.1:0`.

use std::time::Duration;

use axum::{
    http::{header::AUTHORIZATION, HeaderName, HeaderValue, StatusCode},
    Router,
};
use axum_test::TestServer;
use chrono::Utc;
use jsonwebtoken::{encode, EncodingKey, Header};
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio::{net::TcpListener, sync::oneshot, task::JoinHandle};
use uuid::Uuid;

use super::{
    common::{build_test_state_with_ai, test_jwt_config, TEST_PASSWORD},
    program_endpoint::ok_mock,
};
use crate::{auth::jwt::Claims, routes};

/// Timeout used by the tests for the ML engine.
const TEST_TIMEOUT: Duration = Duration::from_millis(500);

/// Header read by the rate limiter to identify the client.
const FORWARDED_FOR: &str = "x-forwarded-for";

/// Fake client IP used by the tests.
const CLIENT_IP: &str = "203.0.113.7";

/// A mock ML engine that can be stopped from the test.
struct StoppableMock {
    /// Base URL of the mock.
    url: String,
    /// Sending on this channel starts a graceful shutdown.
    stop_signal: oneshot::Sender<()>,
    /// Finishes once the server has really stopped.
    task: JoinHandle<()>,
}

impl StoppableMock {
    /// Starts `router` on a free local port.
    async fn start(router: Router) -> Self {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let url = format!("http://{}", listener.local_addr().unwrap());
        let (stop_signal, stop_receiver) = oneshot::channel::<()>();

        let task = tokio::spawn(async move {
            axum::serve(listener, router)
                // Graceful shutdown also closes idle keep-alive connections.
                // Aborting the task would not: the reqwest client could keep
                // reusing its open connection and the "outage" would not happen.
                .with_graceful_shutdown(async {
                    let _ = stop_receiver.await;
                })
                .await
                .unwrap();
        });

        Self { url, stop_signal, task }
    }

    /// Stops the server and waits until the port is closed.
    async fn stop(self) {
        // `self` is consumed (moved) so the mock cannot be used after being stopped.
        let _ = self.stop_signal.send(());
        self.task.await.unwrap();
    }
}

/// Builds the real router for `pool`, with a login limit of `login_limit` per minute.
fn server(pool: PgPool, ai_url: String, login_limit: u32) -> TestServer {
    let state = build_test_state_with_ai(pool, ai_url, TEST_TIMEOUT);
    TestServer::new(routes::build_router(state, login_limit).unwrap()).unwrap()
}

/// Header name/value pair for `X-Forwarded-For`.
fn forwarded_for() -> (HeaderName, HeaderValue) {
    (FORWARDED_FOR.parse().unwrap(), HeaderValue::from_static(CLIENT_IP))
}

/// Header value `Bearer <token>`.
fn bearer(token: &str) -> HeaderValue {
    HeaderValue::from_str(&format!("Bearer {token}")).unwrap()
}

/// Creates a user through `POST /users` and logs in; returns the user id and the token.
async fn create_and_login(server: &TestServer) -> (Uuid, String) {
    let created = server
        .post("/users")
        .json(&json!({
            "email": "e2e@example.com",
            "username": "e2euser",
            "password": TEST_PASSWORD,
        }))
        .await;
    created.assert_status(StatusCode::CREATED);
    let user_id: Uuid = created.json::<Value>()["id"].as_str().unwrap().parse().unwrap();

    let (name, value) = forwarded_for();
    let login = server
        .post("/auth/login")
        .add_header(name, value)
        .json(&json!({ "email": "e2e@example.com", "password": TEST_PASSWORD }))
        .await;
    login.assert_status_ok();
    let token = login.json::<Value>()["token"].as_str().unwrap().to_string();

    (user_id, token)
}

/// Given a working ML engine, when a user registers, logs in and asks for a program,
/// then the program is `generated`; when the engine stops, the same program is
/// served from the `cache`.
#[sqlx::test]
async fn create_login_get_program_then_cache_fallback(pool: PgPool) {
    let mock = StoppableMock::start(ok_mock()).await;
    let server = server(pool, mock.url.clone(), 100);
    let (_user_id, token) = create_and_login(&server).await;

    let first = server.get("/workouts/program").add_header(AUTHORIZATION, bearer(&token)).await;
    first.assert_status_ok();
    let first: Value = first.json();
    assert_eq!(first["source"], "generated");
    assert_eq!(first["workouts"][0]["name"], "Push day");

    mock.stop().await;

    let second = server.get("/workouts/program").add_header(AUTHORIZATION, bearer(&token)).await;
    second.assert_status_ok();
    let second: Value = second.json();
    assert_eq!(second["source"], "cache");
    // Same program: only `source` (and the date precision) may differ.
    assert_eq!(second["workouts"], first["workouts"]);
}

/// Given a program endpoint, when the request has no token, then 401.
#[sqlx::test]
async fn program_without_token_returns_401(pool: PgPool) {
    let mock = StoppableMock::start(ok_mock()).await;
    let server = server(pool, mock.url.clone(), 100);

    server.get("/workouts/program").await.assert_status(StatusCode::UNAUTHORIZED);
}

/// Given a valid token whose signature was altered, when asking for a program, then 401.
#[sqlx::test]
async fn program_with_tampered_token_returns_401(pool: PgPool) {
    let mock = StoppableMock::start(ok_mock()).await;
    let server = server(pool, mock.url.clone(), 100);
    let (_user_id, token) = create_and_login(&server).await;

    // The signature is the last of the 3 dot-separated parts. The FIRST of its
    // characters is changed: the last one carries unused bits and may not matter.
    let (signed_part, signature) = token.rsplit_once('.').unwrap();
    let first_char = if signature.starts_with('A') { 'B' } else { 'A' };
    let tampered = format!("{signed_part}.{first_char}{}", &signature[1..]);

    let response = server
        .get("/workouts/program")
        .add_header(AUTHORIZATION, bearer(&tampered))
        .await;
    response.assert_status(StatusCode::UNAUTHORIZED);
}

/// Given a token signed with the right secret but already expired, when asking
/// for a program, then 401.
#[sqlx::test]
async fn program_with_expired_token_returns_401(pool: PgPool) {
    let mock = StoppableMock::start(ok_mock()).await;
    let server = server(pool, mock.url.clone(), 100);
    let (user_id, _token) = create_and_login(&server).await;

    let now = Utc::now().timestamp();
    // Expired one hour ago, far beyond any leeway.
    let claims = Claims { sub: user_id, iat: now - 7200, exp: now - 3600 };
    let expired = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(test_jwt_config().secret.as_bytes()),
    )
    .unwrap();

    let response = server
        .get("/workouts/program")
        .add_header(AUTHORIZATION, bearer(&expired))
        .await;
    response.assert_status(StatusCode::UNAUTHORIZED);
}

/// Given a limit of 3 logins per minute, when the same IP fails 3 logins,
/// then the 4th attempt gets 429.
#[sqlx::test]
async fn too_many_failed_logins_return_429(pool: PgPool) {
    let server = server(pool, "http://127.0.0.1:9".to_string(), 3);
    let body = json!({ "email": "nobody@example.com", "password": "wrong-password" });

    for _ in 0..3 {
        let (name, value) = forwarded_for();
        let response = server.post("/auth/login").add_header(name, value).json(&body).await;
        response.assert_status(StatusCode::UNAUTHORIZED);
    }

    let (name, value) = forwarded_for();
    let blocked = server.post("/auth/login").add_header(name, value).json(&body).await;
    blocked.assert_status(StatusCode::TOO_MANY_REQUESTS);
}
