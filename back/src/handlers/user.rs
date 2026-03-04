use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};

use crate::{
    errors::AppResult,
    models::user::{CreateUserRequest, CreateUserResponse},
    AppState,
};

/// `POST /users`
///
/// Registers a new user profile.
///
/// # Request body
/// JSON body matching [`CreateUserRequest`].
///
/// # Responses
/// - `201 Created` — user successfully registered, returns [`CreateUserResponse`].
/// - `409 Conflict` — email already in use.
/// - `422 Unprocessable Entity` — validation failed.
/// - `500 Internal Server Error` — unexpected error.
pub async fn create_user(
    State(state): State<AppState>,
    Json(body): Json<CreateUserRequest>,
) -> AppResult<impl IntoResponse> {
    let user = state.user_service.create_user(body).await?;
    let response: CreateUserResponse = user.into();
    Ok((StatusCode::CREATED, Json(response)))
}
