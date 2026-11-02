//! Handler of `GET /workouts/program` (skeleton: always answers 501).

use axum::response::IntoResponse;

use crate::errors::{AppError, AppResult};

/// `GET /workouts/program`
///
/// Will return the training program of the authenticated user
/// (see `openapi.yaml`). For now it is only a skeleton.
///
/// # Responses
/// - `501 Not Implemented` — always, until the ML engine is wired in.
///
/// # Errors
/// Always returns [`AppError::NotImplemented`].
pub async fn get_program() -> AppResult<impl IntoResponse> {
    // TODO(M2): resolve user from JWT (AuthUser)

    // The annotation fixes the success type, which Rust cannot infer when
    // the function only ever returns `Err`.
    Err::<(), _>(AppError::NotImplemented(
        "GET /workouts/program is not implemented yet".to_string(),
    ))
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{routing::get, Router};
    use axum_test::TestServer;
    use serde_json::json;

    #[tokio::test]
    async fn get_program_returns_501_with_json_error() {
        // Mini router: no AppState and no database needed.
        let app = Router::new().route("/workouts/program", get(get_program));
        let server = TestServer::new(app).unwrap();

        let response = server.get("/workouts/program").await;

        response.assert_status(axum::http::StatusCode::NOT_IMPLEMENTED);
        response.assert_json(&json!({
            "error": "GET /workouts/program is not implemented yet"
        }));
    }
}
