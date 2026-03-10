use axum::{http::StatusCode, response::IntoResponse, Json};
use serde_json::json;

/// `GET /health`
///
/// Returns a simple JSON payload confirming the service is up.
pub async fn health_check() -> impl IntoResponse {
    (
        StatusCode::OK,
        Json(json!({
            "status": "ok",
            "service": "liftup-backend"
        })),
    )
}
