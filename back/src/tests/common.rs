//! Shared helpers for the database tests: state wiring, test server, fixtures.

use std::{sync::Arc, time::Duration};

use axum::http::HeaderValue;
use axum_test::TestServer;
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    auth::jwt::create_token,
    config::JwtConfig,
    models::user::{CreateUserRequest, User},
    repositories::{program::ProgramRepository, user::UserRepository, workout::WorkoutRepository},
    routes,
    services::{program::ProgramService, user::UserService, workout::WorkoutService},
    AppState,
};

/// Password used by [`register_user`].
pub const TEST_PASSWORD: &str = "password123";

/// JWT settings used by the tests (secret of 32 characters, 7 days).
pub fn test_jwt_config() -> JwtConfig {
    JwtConfig {
        secret: "0123456789abcdef0123456789abcdef".to_string(),
        expiration_days: 7,
    }
}

/// Builds the same dependency graph as `main.rs`, on top of a test database pool.
///
/// The ML engine URL points to a closed port: tests that need a working (or slow)
/// engine use [`build_test_state_with_ai`] instead.
pub fn build_test_state(pool: PgPool) -> AppState {
    build_test_state_with_ai(pool, "http://127.0.0.1:9".to_string(), Duration::from_millis(200))
}

/// Same as [`build_test_state`], with a custom ML engine URL and timeout.
pub fn build_test_state_with_ai(pool: PgPool, ai_service_url: String, ai_timeout: Duration) -> AppState {
    // `PgPool` is a cheap handle (reference-counted inside), so cloning it
    // shares the same connections instead of opening new ones.
    let user_service = Arc::new(UserService::new(UserRepository::new(pool.clone())));
    let workout_service = Arc::new(WorkoutService::new(WorkoutRepository::new(pool.clone())));
    let program_service = Arc::new(
        ProgramService::new(
            ai_service_url.clone(),
            ai_timeout,
            UserRepository::new(pool.clone()),
            ProgramRepository::new(pool),
        )
        .unwrap(),
    );

    AppState {
        jwt_config: Arc::new(test_jwt_config()),
        user_service,
        workout_service,
        program_service,
        ai_service_url: Arc::new(ai_service_url),
        analysis_client: reqwest::Client::new(),
    }
}

/// Starts an in-memory HTTP server serving the real router (no network port needed).
pub fn test_server(pool: PgPool) -> TestServer {
    server_from_state(build_test_state(pool))
}

/// Starts an in-memory HTTP server for a given state (e.g. with a mock ML engine).
pub fn server_from_state(state: AppState) -> TestServer {
    server_with_upload_limit(state, 50 * 1024 * 1024)
}

/// Same as [`server_from_state`], with a custom `/ai/analyze` upload limit in bytes.
pub fn server_with_upload_limit(state: AppState, max_upload_bytes: usize) -> TestServer {
    let app = routes::build_router(state, 100, max_upload_bytes).unwrap();
    TestServer::new(app).unwrap()
}

/// Builds a [`CreateUserRequest`] from a JSON object.
///
/// Going through `serde_json` avoids listing every optional field, and it
/// also exercises the real (snake_case) deserialization of the DTO.
pub fn create_user_request(email: &str, username: &str, password: &str) -> CreateUserRequest {
    serde_json::from_value(json!({
        "email": email,
        "username": username,
        "password": password,
    }))
    .unwrap()
}

/// Creates a valid user through the service and returns it.
///
/// The password is [`TEST_PASSWORD`].
pub async fn register_user(state: &AppState, email: &str, username: &str) -> User {
    state
        .user_service
        .create_user(create_user_request(email, username, TEST_PASSWORD))
        .await
        .unwrap()
}

/// Builds the `Authorization` header value (`Bearer <token>`) for a user id.
///
/// The token is signed with [`test_jwt_config`], exactly like a real login would.
pub fn bearer_for(user_id: Uuid) -> HeaderValue {
    let token = create_token(user_id, &test_jwt_config()).unwrap();
    HeaderValue::from_str(&format!("Bearer {token}")).unwrap()
}

/// Registers a user through `POST /users`, then returns its id and its `Authorization` header value.
///
/// The token is created directly (not through `/auth/login`) so that tests do not
/// depend on the login rate limiter.
pub async fn register_and_login(server: &TestServer, email: &str, username: &str) -> (Uuid, HeaderValue) {
    let response = server
        .post("/users")
        .json(&json!({ "email": email, "username": username, "password": TEST_PASSWORD }))
        .await;
    let body: serde_json::Value = response.json();
    let id: Uuid = body["id"].as_str().unwrap().parse().unwrap();
    (id, bearer_for(id))
}
