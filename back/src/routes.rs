use axum::{routing::{get, post}, Router};

use crate::{handlers::{health::health_check, user::{create_user, get_user, login, update_user}}, AppState};

/// Build and return the application router with all registered routes.
///
/// Current routes:
/// - `GET  /health` → [`health_check`]
/// - `POST /users`  → [`create_user`]
/// - `GET  /users/:id` → [`get_user`]
/// - `PATCH /users/:id` → [`update_user`]
/// - `POST /auth/login` → [`login`]
pub fn build_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health_check))
        .route("/users", post(create_user))
        .route("/users/:id", get(get_user).patch(update_user))
        .route("/auth/login", post(login))
        .with_state(state)
}
