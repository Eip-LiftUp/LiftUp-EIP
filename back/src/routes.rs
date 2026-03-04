use axum::{routing::{get, post}, Router};

use crate::{handlers::{health::health_check, user::create_user}, AppState};

/// Build and return the application router with all registered routes.
///
/// Current routes:
/// - `GET  /health` → [`health_check`]
/// - `POST /users`  → [`create_user`]
pub fn build_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health_check))
        .route("/users", post(create_user))
        .with_state(state)
}
