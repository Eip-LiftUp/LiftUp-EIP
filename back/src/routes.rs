use axum::{routing::{get, post, patch}, Router};

use crate::{
    handlers::{
        analysis::{analyze_video, get_supported_exercises, ai_health_check},
        health::health_check,
        program::get_program,
        user::{create_user, get_user, login, update_user},
        workout::{
            create_workout, get_user_workouts, get_workout, update_workout, delete_workout,
            add_exercise, update_exercise, delete_exercise,
        },
    },
    rate_limit::login_rate_limit_layer,
    AppState
};

/// Build and return the application router with all registered routes.
///
/// Current routes:
/// - `GET  /health` → [`health_check`]
/// - `POST /users`  → [`create_user`]
/// - `GET  /users/:id` → [`get_user`]
/// - `PATCH /users/:id` → [`update_user`]
/// - `POST /auth/login` → [`login`] (rate limited per IP)
/// - `POST /users/:user_id/workouts` → [`create_workout`]
/// - `GET  /users/:user_id/workouts` → [`get_user_workouts`]
/// - `GET  /users/:user_id/workouts/:workout_id` → [`get_workout`]
/// - `PATCH /users/:user_id/workouts/:workout_id` → [`update_workout`]
/// - `DELETE /users/:user_id/workouts/:workout_id` → [`delete_workout`]
/// - `POST /users/:user_id/workouts/:workout_id/exercises` → [`add_exercise`]
/// - `PATCH /users/:user_id/exercises/:exercise_id` → [`update_exercise`]
/// - `DELETE /users/:user_id/exercises/:exercise_id` → [`delete_exercise`]
/// - `GET  /workouts/program` → [`get_program`] (Bearer token required; ML engine with cache fallback)
///
/// Only `POST /auth/login` is rate limited (`login_rate_limit_per_minute` attempts
/// per minute and per IP).
///
/// # Errors
/// Returns an error if `login_rate_limit_per_minute` is invalid (see [`login_rate_limit_layer`]).
/// Must be called inside a tokio runtime (the rate limiter spawns a cleanup task).
pub fn build_router(state: AppState, login_rate_limit_per_minute: u32) -> anyhow::Result<Router> {
    // The layer wraps only this sub-router, so the other routes are not limited.
    // Both routers still wait for the same `AppState`, given once by `with_state` below.
    let login_router = Router::new()
        .route("/auth/login", post(login))
        .layer(login_rate_limit_layer(login_rate_limit_per_minute)?);

    Ok(Router::new()
        .merge(login_router)
        .route("/health", get(health_check))
        .route("/users", post(create_user))
        .route("/users/:id", get(get_user).patch(update_user))
        // Workout routes
        .route("/users/:user_id/workouts", post(create_workout).get(get_user_workouts))
        .route("/users/:user_id/workouts/:workout_id", get(get_workout).patch(update_workout).delete(delete_workout))
        .route("/users/:user_id/workouts/:workout_id/exercises", post(add_exercise))
        .route("/users/:user_id/exercises/:exercise_id", patch(update_exercise).delete(delete_exercise))
        // Program route (skeleton)
        .route("/workouts/program", get(get_program))
        // AI Analysis routes (proxied to Python service)
        .route("/ai/analyze", post(analyze_video))
        .route("/ai/exercises", get(get_supported_exercises))
        .route("/ai/health", get(ai_health_check))
        .with_state(state))
}
