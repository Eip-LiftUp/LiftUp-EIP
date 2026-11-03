//! Tests of the AI proxy routes: upload size limit and generic error messages.
//!
//! The AI engine is not running in these tests (the URL points to a closed port),
//! so a request that gets through the limit ends with `503`.

use axum::http::{header::AUTHORIZATION, StatusCode};
use axum_test::multipart::{MultipartForm, Part};
use serde_json::Value;
use sqlx::PgPool;

use crate::tests::common::{
    build_test_state, register_and_login, server_from_state, server_with_upload_limit,
};

const MB: usize = 1024 * 1024;

/// Builds a multipart form with a `video` field of `size` bytes.
fn video_form(size: usize) -> MultipartForm {
    let part = Part::bytes(vec![0u8; size]).file_name("video.mp4").mime_type("video/mp4");
    MultipartForm::new().add_part("video", part)
}

/// Given the default limit (50 MB), when a 3 MB video is posted, then it is not rejected by
/// the size limit (the 2 MB Axum default): the answer is the 503 of the unreachable AI engine.
#[sqlx::test]
async fn upload_of_3_mb_passes_the_body_limit(pool: PgPool) {
    let server = server_from_state(build_test_state(pool));
    let (_, auth) = register_and_login(&server, "a@example.com", "alice").await;

    let response = server
        .post("/ai/analyze")
        .add_header(AUTHORIZATION, auth)
        .multipart(video_form(3 * MB))
        .await;

    response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(response.json::<Value>()["error"], "AI service unavailable");
}

/// Given a limit of 1 MB, when a 2 MB video is posted, then the answer is 413.
#[sqlx::test]
async fn upload_above_the_configured_limit_returns_413(pool: PgPool) {
    let server = server_with_upload_limit(build_test_state(pool), MB);
    let (_, auth) = register_and_login(&server, "a@example.com", "alice").await;

    let response = server
        .post("/ai/analyze")
        .add_header(AUTHORIZATION, auth)
        .multipart(video_form(2 * MB))
        .await;

    response.assert_status(StatusCode::PAYLOAD_TOO_LARGE);
}

/// Given a body above 2 MB on another route, when it is posted, then the default limit still
/// applies (the upload limit is only set on `/ai/analyze`).
#[sqlx::test]
async fn other_routes_keep_the_default_limit(pool: PgPool) {
    let server = server_with_upload_limit(build_test_state(pool), 50 * MB);
    let (id, auth) = register_and_login(&server, "a@example.com", "alice").await;

    let response = server
        .post(&format!("/users/{id}/workouts"))
        .add_header(AUTHORIZATION, auth)
        .content_type("application/json")
        .bytes(vec![b' '; 3 * MB].into())
        .await;

    response.assert_status(StatusCode::PAYLOAD_TOO_LARGE);
}

/// Given an unreachable AI engine, when analysing or listing exercises, then the client gets a
/// generic message and the internal URL appears nowhere in the body.
#[sqlx::test]
async fn ai_errors_do_not_leak_the_internal_url(pool: PgPool) {
    let server = server_from_state(build_test_state(pool));
    let (_, auth) = register_and_login(&server, "a@example.com", "alice").await;

    let analyze = server
        .post("/ai/analyze")
        .add_header(AUTHORIZATION, auth.clone())
        .multipart(video_form(1024))
        .await;
    let exercises = server.get("/ai/exercises").add_header(AUTHORIZATION, auth).await;
    let health = server.get("/ai/health").await;

    for response in [&analyze, &exercises] {
        response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
        assert_eq!(response.json::<Value>()["error"], "AI service unavailable");
    }
    for response in [&analyze, &exercises, &health] {
        assert!(!response.text().contains("127.0.0.1"), "{}", response.text());
    }
}
