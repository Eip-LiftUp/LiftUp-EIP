use axum::{routing::{get, post, patch}, Router};

use crate::{
    handlers::{
        analysis::{analyze_video, get_supported_exercises, ai_health_check},
        health::health_check,
        user::{create_user, get_user, login, update_user},
        workout::{
            create_workout, get_user_workouts, get_workout, update_workout, delete_workout,
            add_exercise, update_exercise, delete_exercise,
        },
    },
    AppState
};

/// Build and return the application router with all registered routes.
///
/// Current routes:
/// - `GET  /health` → [`health_check`]
/// - `POST /users`  → [`create_user`]
/// - `GET  /users/:id` → [`get_user`]
/// - `PATCH /users/:id` → [`update_user`]
/// - `POST /auth/login` → [`login`]
/// - `POST /users/:user_id/workouts` → [`create_workout`]
/// - `GET  /users/:user_id/workouts` → [`get_user_workouts`]
/// - `GET  /users/:user_id/workouts/:workout_id` → [`get_workout`]
/// - `PATCH /users/:user_id/workouts/:workout_id` → [`update_workout`]
/// - `DELETE /users/:user_id/workouts/:workout_id` → [`delete_workout`]
/// - `POST /users/:user_id/workouts/:workout_id/exercises` → [`add_exercise`]
/// - `PATCH /users/:user_id/exercises/:exercise_id` → [`update_exercise`]
/// - `DELETE /users/:user_id/exercises/:exercise_id` → [`delete_exercise`]
pub fn build_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health_check))
        .route("/users", post(create_user))
        .route("/users/:id", get(get_user).patch(update_user))
        .route("/auth/login", post(login))
        // Workout routes
        .route("/users/:user_id/workouts", post(create_workout).get(get_user_workouts))
        .route("/users/:user_id/workouts/:workout_id", get(get_workout).patch(update_workout).delete(delete_workout))
        .route("/users/:user_id/workouts/:workout_id/exercises", post(add_exercise))
        .route("/users/:user_id/exercises/:exercise_id", patch(update_exercise).delete(delete_exercise))
        // AI Analysis routes (proxied to Python service)
        .route("/ai/analyze", post(analyze_video))
        .route("/ai/exercises", get(get_supported_exercises))
        .route("/ai/health", get(ai_health_check))
        .with_state(state)
}
