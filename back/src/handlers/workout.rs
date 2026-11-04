use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use uuid::Uuid;

use crate::{
    auth::AuthUser,
    errors::AppResult,
    models::workout::{CreateExerciseRequest, CreateWorkoutRequest, UpdateExerciseRequest, UpdateWorkoutRequest},
    AppState,
};

// ==================== WORKOUT ENDPOINTS ====================

/// `POST /workouts`
///
/// Create a new workout for the authenticated user.
///
/// # Request body
/// JSON body matching [`CreateWorkoutRequest`].
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — the path user id is not the token's user.
/// - `201 Created` — workout created successfully.
/// - `404 Not Found` — user not found.
/// - `422 Unprocessable Entity` — validation failed.
/// - `500 Internal Server Error` — unexpected error.
pub async fn create_workout(
    auth: AuthUser,
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
    Json(body): Json<CreateWorkoutRequest>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    let workout = state.workout_service.create_workout(user_id, body).await?;
    Ok((StatusCode::CREATED, Json(workout)))
}

/// `GET /users/:user_id/workouts`
///
/// Get all workouts for a user.
///
/// # Path parameters
/// - `user_id` — User UUID.
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — the path user id is not the token's user.
/// - `200 OK` — returns list of workouts.
/// - `404 Not Found` — user not found.
/// - `500 Internal Server Error` — unexpected error.
pub async fn get_user_workouts(
    auth: AuthUser,
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    let workouts = state.workout_service.get_user_workouts(user_id).await?;
    Ok((StatusCode::OK, Json(workouts)))
}

/// `GET /workouts/:workout_id`
///
/// Get a specific workout by ID.
///
/// # Path parameters
/// - `workout_id` — Workout UUID.
/// - `user_id` — User UUID (from query or auth token).
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — also returned when the path user id is not the token's user.
/// - `200 OK` — returns workout with exercises.
/// - `403 Forbidden` — user doesn't own this workout.
/// - `404 Not Found` — workout not found.
/// - `500 Internal Server Error` — unexpected error.
pub async fn get_workout(
    auth: AuthUser,
    State(state): State<AppState>,
    Path((user_id, workout_id)): Path<(Uuid, Uuid)>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    let workout = state.workout_service.get_workout(workout_id, user_id).await?;
    Ok((StatusCode::OK, Json(workout)))
}

/// `PATCH /workouts/:workout_id`
///
/// Update a workout.
///
/// # Path parameters
/// - `workout_id` — Workout UUID.
///
/// # Request body
/// JSON body matching [`UpdateWorkoutRequest`].
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — also returned when the path user id is not the token's user.
/// - `200 OK` — workout updated.
/// - `403 Forbidden` — user doesn't own this workout.
/// - `404 Not Found` — workout not found.
/// - `500 Internal Server Error` — unexpected error.
pub async fn update_workout(
    auth: AuthUser,
    State(state): State<AppState>,
    Path((user_id, workout_id)): Path<(Uuid, Uuid)>,
    Json(body): Json<UpdateWorkoutRequest>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    let workout = state.workout_service.update_workout(workout_id, user_id, body).await?;
    Ok((StatusCode::OK, Json(workout)))
}

/// `DELETE /workouts/:workout_id`
///
/// Delete a workout.
///
/// # Path parameters
/// - `workout_id` — Workout UUID.
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — also returned when the path user id is not the token's user.
/// - `204 No Content` — workout deleted.
/// - `403 Forbidden` — user doesn't own this workout.
/// - `404 Not Found` — workout not found.
/// - `500 Internal Server Error` — unexpected error.
pub async fn delete_workout(
    auth: AuthUser,
    State(state): State<AppState>,
    Path((user_id, workout_id)): Path<(Uuid, Uuid)>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    state.workout_service.delete_workout(workout_id, user_id).await?;
    Ok(StatusCode::NO_CONTENT)
}

// ==================== EXERCISE ENDPOINTS ====================

/// `POST /workouts/:workout_id/exercises`
///
/// Add an exercise to a workout.
///
/// # Path parameters
/// - `workout_id` — Workout UUID.
///
/// # Request body
/// JSON body matching [`CreateExerciseRequest`].
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — also returned when the path user id is not the token's user.
/// - `201 Created` — exercise added.
/// - `403 Forbidden` — user doesn't own this workout.
/// - `404 Not Found` — workout not found.
/// - `500 Internal Server Error` — unexpected error.
pub async fn add_exercise(
    auth: AuthUser,
    State(state): State<AppState>,
    Path((user_id, workout_id)): Path<(Uuid, Uuid)>,
    Json(body): Json<CreateExerciseRequest>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    let exercise = state.workout_service.add_exercise(workout_id, user_id, body).await?;
    Ok((StatusCode::CREATED, Json(exercise)))
}

/// `PATCH /exercises/:exercise_id`
///
/// Update an exercise.
///
/// # Path parameters
/// - `exercise_id` — Exercise UUID.
///
/// # Request body
/// JSON body matching [`UpdateExerciseRequest`].
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — also returned when the path user id is not the token's user.
/// - `200 OK` — exercise updated.
/// - `403 Forbidden` — user doesn't own this exercise.
/// - `404 Not Found` — exercise not found.
/// - `500 Internal Server Error` — unexpected error.
pub async fn update_exercise(
    auth: AuthUser,
    State(state): State<AppState>,
    Path((user_id, exercise_id)): Path<(Uuid, Uuid)>,
    Json(body): Json<UpdateExerciseRequest>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    let exercise = state.workout_service.update_exercise(exercise_id, user_id, body).await?;
    Ok((StatusCode::OK, Json(exercise)))
}

/// `DELETE /exercises/:exercise_id`
///
/// Delete an exercise.
///
/// # Path parameters
/// - `exercise_id` — Exercise UUID.
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — also returned when the path user id is not the token's user.
/// - `204 No Content` — exercise deleted.
/// - `403 Forbidden` — user doesn't own this exercise.
/// - `404 Not Found` — exercise not found.
/// - `500 Internal Server Error` — unexpected error.
pub async fn delete_exercise(
    auth: AuthUser,
    State(state): State<AppState>,
    Path((user_id, exercise_id)): Path<(Uuid, Uuid)>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    state.workout_service.delete_exercise(exercise_id, user_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
