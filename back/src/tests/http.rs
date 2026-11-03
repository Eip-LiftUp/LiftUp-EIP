//! HTTP tests: real router, in-memory server (`axum-test`), temporary database.

use axum::http::{header::AUTHORIZATION, HeaderValue, StatusCode};
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    auth::jwt::verify_token,
    tests::common::{bearer_for, register_and_login, test_jwt_config, test_server, TEST_PASSWORD},
};

/// Header read by the login rate limiter. The in-memory test server has no peer
/// address, so login requests must carry a client IP, as they would behind a proxy.
const FORWARDED_FOR: &str = "x-forwarded-for";

/// Client IP sent by the login tests.
const TEST_CLIENT_IP: &str = "203.0.113.10";

/// Request body for `POST /users` (snake_case, like the DTO).
fn new_user_body(email: &str, username: &str) -> Value {
    json!({ "email": email, "username": username, "password": TEST_PASSWORD })
}

/// Given valid data, when `POST /users`, then 201 and the body never contains the password hash.
#[sqlx::test]
async fn post_users_returns_201_without_password_hash(pool: PgPool) {
    let server = test_server(pool);

    let response = server.post("/users").json(&new_user_body("alice@example.com", "alice")).await;

    response.assert_status(StatusCode::CREATED);
    let body: Value = response.json();
    assert_eq!(body["email"], "alice@example.com");
    assert!(body["id"].is_string());
    // The response is camelCase, so check both spellings plus the raw text.
    assert!(body.get("password_hash").is_none());
    assert!(body.get("passwordHash").is_none());
    assert!(!response.text().contains("$2"));
}

/// Given an existing email, when `POST /users` again, then 409.
#[sqlx::test]
async fn post_users_duplicate_returns_409(pool: PgPool) {
    let server = test_server(pool);
    let body = new_user_body("alice@example.com", "alice");
    server.post("/users").json(&body).await.assert_status(StatusCode::CREATED);

    let response = server.post("/users").json(&body).await;

    response.assert_status(StatusCode::CONFLICT);
    assert!(response.json::<Value>()["error"].is_string());
}

/// Given a registered user, when `POST /auth/login` with the right password, then 200
/// and a token that verifies and belongs to that user.
#[sqlx::test]
async fn login_returns_200_with_valid_token(pool: PgPool) {
    let server = test_server(pool);
    let created: Value = server
        .post("/users")
        .json(&new_user_body("alice@example.com", "alice"))
        .await
        .json();

    let response = server
        .post("/auth/login")
        .add_header(FORWARDED_FOR.parse().unwrap(), HeaderValue::from_static(TEST_CLIENT_IP))
        .json(&json!({ "email": "alice@example.com", "password": TEST_PASSWORD }))
        .await;

    response.assert_status_ok();
    let body: Value = response.json();
    let token = body["token"].as_str().unwrap();
    let claims = verify_token(token, &test_jwt_config()).unwrap();
    assert_eq!(claims.sub.to_string(), created["id"].as_str().unwrap());
}

/// Given a registered user, when `POST /auth/login` with a wrong password, then 401.
#[sqlx::test]
async fn login_with_wrong_password_returns_401(pool: PgPool) {
    let server = test_server(pool);
    server
        .post("/users")
        .json(&new_user_body("alice@example.com", "alice"))
        .await
        .assert_status(StatusCode::CREATED);

    let response = server
        .post("/auth/login")
        .add_header(FORWARDED_FOR.parse().unwrap(), HeaderValue::from_static(TEST_CLIENT_IP))
        .json(&json!({ "email": "alice@example.com", "password": "wrong-password" }))
        .await;

    response.assert_status(StatusCode::UNAUTHORIZED);
}

/// Given a registered user, when `GET /users/:id` with its own token, then 200;
/// for an unknown id carried by a token of that same id, 404.
#[sqlx::test]
async fn get_user_returns_200_then_404_for_unknown(pool: PgPool) {
    let server = test_server(pool);
    let (id, auth) = register_and_login(&server, "alice@example.com", "alice").await;

    let found = server.get(&format!("/users/{id}")).add_header(AUTHORIZATION, auth).await;
    found.assert_status_ok();
    assert_eq!(found.json::<Value>()["username"], "alice");

    // A valid token whose user does not exist: the id check passes, the lookup gives 404.
    let ghost = Uuid::new_v4();
    let missing = server.get(&format!("/users/{ghost}")).add_header(AUTHORIZATION, bearer_for(ghost)).await;
    missing.assert_status(StatusCode::NOT_FOUND);
}

/// Given a user, when a workout is posted then listed with its own token, then the list contains it.
#[sqlx::test]
async fn post_then_get_user_workouts(pool: PgPool) {
    let server = test_server(pool);
    let (id, auth) = register_and_login(&server, "alice@example.com", "alice").await;

    // Workout DTOs are camelCase.
    let posted = server
        .post(&format!("/users/{id}/workouts"))
        .add_header(AUTHORIZATION, auth.clone())
        .json(&json!({ "name": "Push day", "durationMinutes": 45 }))
        .await;
    posted.assert_status(StatusCode::CREATED);

    let listed = server.get(&format!("/users/{id}/workouts")).add_header(AUTHORIZATION, auth).await;
    listed.assert_status_ok();
    let workouts = listed.json::<Value>();
    let workouts = workouts.as_array().unwrap();
    assert_eq!(workouts.len(), 1);
    assert_eq!(workouts[0]["name"], "Push day");
    assert_eq!(workouts[0]["durationMinutes"], 45);
}

/// Given a valid token for an id that has no user row, when `POST /users/:id/workouts`, then 404 (not a 500 from the foreign key).
#[sqlx::test]
async fn post_workout_for_unknown_user_returns_404(pool: PgPool) {
    let server = test_server(pool);
    let unknown = Uuid::new_v4();

    let response = server
        .post(&format!("/users/{unknown}/workouts"))
        .add_header(AUTHORIZATION, bearer_for(unknown))
        .json(&json!({ "name": "Ghost workout" }))
        .await;

    response.assert_status(StatusCode::NOT_FOUND);
    assert_eq!(
        response.json::<Value>(),
        json!({ "error": format!("User with id '{unknown}' not found") })
    );
}
