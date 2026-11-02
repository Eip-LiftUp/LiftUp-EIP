//! Tests of `GET /workouts/program`: ML engine call, cache fallback, authentication.
//!
//! The ML engine is replaced by a tiny axum server started on `127.0.0.1:0`
//! (the OS picks a free port), so no new dependency is needed.

use std::time::Duration;

use axum::{
    http::{header::AUTHORIZATION, HeaderValue, StatusCode},
    routing::post,
    Json, Router,
};
use axum_test::TestServer;
use serde_json::{json, Value};
use sqlx::PgPool;
use tokio::net::TcpListener;

use super::common::{build_test_state_with_ai, register_user, server_from_state, test_jwt_config};
use crate::{auth::jwt::create_token, models::user::User, repositories::program::ProgramRepository, AppState};

/// Path of the provisional ML endpoint.
const ML_PATH: &str = "/api/v1/program/generate";

/// Timeout used by the tests for the ML engine.
const TEST_TIMEOUT: Duration = Duration::from_millis(200);

/// Starts `router` on a free local port and returns its base URL.
async fn spawn_mock(router: Router) -> String {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let address = listener.local_addr().unwrap();
    // The server runs in a background task and ends with the test runtime.
    tokio::spawn(async move {
        axum::serve(listener, router).await.unwrap();
    });
    format!("http://{address}")
}

/// Returns a URL whose port is closed (nothing listens on it).
async fn closed_port_url() -> String {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let address = listener.local_addr().unwrap();
    // Dropping the listener closes the port, so connecting is refused.
    drop(listener);
    format!("http://{address}")
}

/// Mock engine that answers with a valid program, after checking the request shape.
pub(super) fn ok_mock() -> Router {
    Router::new().route(
        ML_PATH,
        post(|Json(body): Json<Value>| async move {
            if body.get("fitness_level").is_none() || body.get("injured_zones").is_none() {
                return (StatusCode::UNPROCESSABLE_ENTITY, Json(json!({})));
            }
            (
                StatusCode::OK,
                Json(json!({
                    "workouts": [{
                        "name": "Push day",
                        "exercises": [{
                            "exercise_name": "Bench press",
                            "sets": 4,
                            "reps": 8,
                            "weight": 60.0,
                            "weight_unit": "kg"
                        }]
                    }]
                })),
            )
        }),
    )
}

/// Mock engine that answers after 2 seconds, far longer than [`TEST_TIMEOUT`].
fn slow_mock() -> Router {
    Router::new().route(
        ML_PATH,
        post(|| async {
            tokio::time::sleep(Duration::from_secs(2)).await;
            Json(json!({ "workouts": [] }))
        }),
    )
}

/// Builds a state/server pair pointing to the given ML engine URL, with one registered user.
async fn setup(pool: PgPool, ai_url: String) -> (AppState, TestServer, User, HeaderValue) {
    let state = build_test_state_with_ai(pool, ai_url, TEST_TIMEOUT);
    let user = register_user(&state, "program@example.com", "programuser").await;
    let token = create_token(user.id, &test_jwt_config()).unwrap();
    let server = server_from_state(state.clone());
    (state, server, user, HeaderValue::from_str(&format!("Bearer {token}")).unwrap())
}

/// Saves a program in the cache the way the service would.
async fn seed_cache(pool: &PgPool, user: &User) {
    let program = json!({
        "generatedAt": "2020-01-01T00:00:00Z",
        "source": "generated",
        "workouts": [{
            "name": "Cached day",
            "exercises": [{
                "exerciseName": "Squat",
                "sets": 5,
                "reps": 5,
                "weight": null,
                "weightUnit": "kg"
            }]
        }]
    });
    ProgramRepository::new(pool.clone()).upsert(user.id, &program).await.unwrap();
}

/// Given a working ML engine, when the user asks for a program,
/// then the answer is 200 `generated` and one row is saved in `cached_programs`.
#[sqlx::test]
async fn ml_ok_returns_generated_and_fills_cache(pool: PgPool) {
    let url = spawn_mock(ok_mock()).await;
    let (_state, server, user, auth) = setup(pool.clone(), url).await;

    let response = server.get("/workouts/program").add_header(AUTHORIZATION, auth).await;

    response.assert_status_ok();
    let body: Value = response.json();
    assert_eq!(body["source"], "generated");
    assert_eq!(body["workouts"][0]["name"], "Push day");
    assert_eq!(body["workouts"][0]["exercises"][0]["exerciseName"], "Bench press");
    assert_eq!(body["workouts"][0]["exercises"][0]["weightUnit"], "kg");

    let rows: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM cached_programs WHERE user_id = $1")
        .bind(user.id)
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(rows, 1);
}

/// Given an ML engine that is down and a cached program,
/// when the user asks for a program, then the answer is 200 `cache`
/// with the date of the cache.
#[sqlx::test]
async fn ml_down_with_cache_returns_cache(pool: PgPool) {
    let url = closed_port_url().await;
    let (_state, server, user, auth) = setup(pool.clone(), url).await;
    seed_cache(&pool, &user).await;

    let response = server.get("/workouts/program").add_header(AUTHORIZATION, auth).await;

    response.assert_status_ok();
    let body: Value = response.json();
    assert_eq!(body["source"], "cache");
    assert_eq!(body["workouts"][0]["name"], "Cached day");
    // The date comes from the `generated_at` column (now), not from the JSON (2020).
    assert!(!body["generatedAt"].as_str().unwrap().starts_with("2020"));
}

/// Given an ML engine that is down and no cached program,
/// when the user asks for a program, then the answer is 503 (never 500).
#[sqlx::test]
async fn ml_down_without_cache_returns_503(pool: PgPool) {
    let url = closed_port_url().await;
    let (_state, server, _user, auth) = setup(pool, url).await;

    let response = server.get("/workouts/program").add_header(AUTHORIZATION, auth).await;

    response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
    let body: Value = response.json();
    assert!(body["error"].is_string());
}

/// Given an ML engine slower than the timeout and a cached program,
/// when the user asks for a program, then the cache is served quickly (< 3 s).
#[sqlx::test]
async fn slow_ml_falls_back_to_cache(pool: PgPool) {
    let url = spawn_mock(slow_mock()).await;
    let (_state, server, user, auth) = setup(pool.clone(), url).await;
    seed_cache(&pool, &user).await;

    let started = std::time::Instant::now();
    let response = server.get("/workouts/program").add_header(AUTHORIZATION, auth).await;

    response.assert_status_ok();
    assert_eq!(response.json::<Value>()["source"], "cache");
    assert!(started.elapsed() < Duration::from_secs(1));
}

/// Given an ML engine that answers 500, when the user asks for a program
/// without cache, then the answer is 503.
#[sqlx::test]
async fn ml_error_status_without_cache_returns_503(pool: PgPool) {
    let failing = Router::new().route(ML_PATH, post(|| async { StatusCode::INTERNAL_SERVER_ERROR }));
    let url = spawn_mock(failing).await;
    let (_state, server, _user, auth) = setup(pool, url).await;

    let response = server.get("/workouts/program").add_header(AUTHORIZATION, auth).await;

    response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
}

/// Given no Authorization header, when the user asks for a program, then the answer is 401.
#[sqlx::test]
async fn missing_token_returns_401(pool: PgPool) {
    let url = closed_port_url().await;
    let (_state, server, _user, _auth) = setup(pool, url).await;

    let response = server.get("/workouts/program").await;

    response.assert_status(StatusCode::UNAUTHORIZED);
}
