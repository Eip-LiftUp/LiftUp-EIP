//! Access control tests: which routes need a token, and who may touch whose data.

use axum::http::{header::AUTHORIZATION, StatusCode};
use axum_test::TestServer;
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

use crate::tests::common::{register_and_login, test_server, TEST_PASSWORD};

/// Creates a workout (and one exercise in it) for `owner`, returns `(workout_id, exercise_id)`.
async fn seed_workout(server: &TestServer, owner: Uuid, auth: &axum::http::HeaderValue) -> (String, String) {
    let workout: Value = server
        .post(&format!("/users/{owner}/workouts"))
        .add_header(AUTHORIZATION, auth.clone())
        .json(&json!({ "name": "Push day" }))
        .await
        .json();
    let workout_id = workout["id"].as_str().unwrap().to_string();
    let exercise: Value = server
        .post(&format!("/users/{owner}/workouts/{workout_id}/exercises"))
        .add_header(AUTHORIZATION, auth.clone())
        .json(&json!({ "exerciseName": "Squat", "sets": 3, "reps": 5 }))
        .await
        .json();
    (workout_id, exercise["id"].as_str().unwrap().to_string())
}

/// Public routes answer without any token.
#[sqlx::test]
async fn public_routes_need_no_token(pool: PgPool) {
    let server = test_server(pool);

    server.get("/health").await.assert_status_ok();
    server
        .post("/users")
        .json(&json!({ "email": "a@example.com", "username": "alice", "password": TEST_PASSWORD }))
        .await
        .assert_status(StatusCode::CREATED);
    server
        .post("/auth/login")
        .add_header("x-forwarded-for".parse().unwrap(), "203.0.113.10".parse().unwrap())
        .json(&json!({ "email": "a@example.com", "password": TEST_PASSWORD }))
        .await
        .assert_status_ok();
}

/// Every protected route family answers 401 without a token (even with an invalid body).
#[sqlx::test]
async fn protected_routes_return_401_without_token(pool: PgPool) {
    let server = test_server(pool);
    let (id, auth) = register_and_login(&server, "a@example.com", "alice").await;
    let (workout_id, exercise_id) = seed_workout(&server, id, &auth).await;
    let w = format!("/users/{id}/workouts/{workout_id}");

    server.get(&format!("/users/{id}")).await.assert_status(StatusCode::UNAUTHORIZED);
    // Invalid body on purpose: the 401 must win over body parsing errors.
    server.patch(&format!("/users/{id}")).text("not json").await.assert_status(StatusCode::UNAUTHORIZED);
    server.post(&format!("/users/{id}/workouts")).text("not json").await.assert_status(StatusCode::UNAUTHORIZED);
    server.get(&format!("/users/{id}/workouts")).await.assert_status(StatusCode::UNAUTHORIZED);
    server.get(&w).await.assert_status(StatusCode::UNAUTHORIZED);
    server.patch(&w).text("not json").await.assert_status(StatusCode::UNAUTHORIZED);
    server.delete(&w).await.assert_status(StatusCode::UNAUTHORIZED);
    server.post(&format!("{w}/exercises")).text("not json").await.assert_status(StatusCode::UNAUTHORIZED);
    let e = format!("/users/{id}/exercises/{exercise_id}");
    server.patch(&e).text("not json").await.assert_status(StatusCode::UNAUTHORIZED);
    server.delete(&e).await.assert_status(StatusCode::UNAUTHORIZED);
    server.post("/ai/analyze").await.assert_status(StatusCode::UNAUTHORIZED);
    server.get("/ai/exercises").await.assert_status(StatusCode::UNAUTHORIZED);
}

/// Another user's token gets 403 on every route that has a user id in its path.
#[sqlx::test]
async fn other_users_token_returns_403(pool: PgPool) {
    let server = test_server(pool);
    let (alice, alice_auth) = register_and_login(&server, "a@example.com", "alice").await;
    let (_bob, bob_auth) = register_and_login(&server, "b@example.com", "bob").await;
    let (workout_id, exercise_id) = seed_workout(&server, alice, &alice_auth).await;
    let w = format!("/users/{alice}/workouts/{workout_id}");
    let e = format!("/users/{alice}/exercises/{exercise_id}");
    let forbidden = StatusCode::FORBIDDEN;

    server.get(&format!("/users/{alice}")).add_header(AUTHORIZATION, bob_auth.clone()).await.assert_status(forbidden);
    server.patch(&format!("/users/{alice}")).add_header(AUTHORIZATION, bob_auth.clone()).json(&json!({})).await.assert_status(forbidden);
    server.get(&format!("/users/{alice}/workouts")).add_header(AUTHORIZATION, bob_auth.clone()).await.assert_status(forbidden);
    server.post(&format!("/users/{alice}/workouts")).add_header(AUTHORIZATION, bob_auth.clone()).json(&json!({ "name": "x" })).await.assert_status(forbidden);
    server.get(&w).add_header(AUTHORIZATION, bob_auth.clone()).await.assert_status(forbidden);
    server.patch(&w).add_header(AUTHORIZATION, bob_auth.clone()).json(&json!({ "name": "x" })).await.assert_status(forbidden);
    server.delete(&w).add_header(AUTHORIZATION, bob_auth.clone()).await.assert_status(forbidden);
    server
        .post(&format!("{w}/exercises"))
        .add_header(AUTHORIZATION, bob_auth.clone())
        .json(&json!({ "exerciseName": "x", "sets": 1, "reps": 1 }))
        .await
        .assert_status(forbidden);
    server.patch(&e).add_header(AUTHORIZATION, bob_auth.clone()).json(&json!({ "sets": 2 })).await.assert_status(forbidden);
    server.delete(&e).add_header(AUTHORIZATION, bob_auth).await.assert_status(forbidden);

    // Nothing was modified: the owner still sees the workout.
    server.get(&w).add_header(AUTHORIZATION, alice_auth).await.assert_status_ok();
}

/// A user can use every route on its own data.
#[sqlx::test]
async fn own_token_gives_access(pool: PgPool) {
    let server = test_server(pool);
    let (id, auth) = register_and_login(&server, "a@example.com", "alice").await;
    let (workout_id, exercise_id) = seed_workout(&server, id, &auth).await;
    let w = format!("/users/{id}/workouts/{workout_id}");
    let e = format!("/users/{id}/exercises/{exercise_id}");

    server.get(&format!("/users/{id}")).add_header(AUTHORIZATION, auth.clone()).await.assert_status_ok();
    server.patch(&format!("/users/{id}")).add_header(AUTHORIZATION, auth.clone()).json(&json!({ "username": "alice2" })).await.assert_status_ok();
    server.get(&format!("/users/{id}/workouts")).add_header(AUTHORIZATION, auth.clone()).await.assert_status_ok();
    server.get(&w).add_header(AUTHORIZATION, auth.clone()).await.assert_status_ok();
    server.patch(&w).add_header(AUTHORIZATION, auth.clone()).json(&json!({ "name": "Pull day" })).await.assert_status_ok();
    server.patch(&e).add_header(AUTHORIZATION, auth.clone()).json(&json!({ "sets": 4 })).await.assert_status_ok();
    server.delete(&e).add_header(AUTHORIZATION, auth.clone()).await.assert_status(StatusCode::NO_CONTENT);
    server.delete(&w).add_header(AUTHORIZATION, auth.clone()).await.assert_status(StatusCode::NO_CONTENT);
    // The AI engine is unreachable in tests (503): what matters is that auth let the request through.
    let ai = server.get("/ai/exercises").add_header(AUTHORIZATION, auth).await;
    assert_ne!(ai.status_code(), StatusCode::UNAUTHORIZED);
    assert_ne!(ai.status_code(), StatusCode::FORBIDDEN);
}
