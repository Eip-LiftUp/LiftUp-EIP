use axum::{extract::{State, Path}, http::StatusCode, response::IntoResponse, Json};
use uuid::Uuid;

use crate::{
    auth::AuthUser,
    auth::jwt::create_token,
    errors::AppResult,
    models::user::{CreateUserRequest, CreateUserResponse, LoginRequest, LoginResponse, UpdateUserRequest, UserProfileResponse},
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

/// `POST /auth/login`
///
/// Authenticates a user with email and password.
///
/// # Request body
/// JSON body matching [`LoginRequest`].
///
/// # Responses
/// - `200 OK` — login successful, returns [`LoginResponse`] with a signed JWT (valid 7 days by default).
/// - `401 Unauthorized` — invalid credentials.
/// - `422 Unprocessable Entity` — validation failed.
/// - `500 Internal Server Error` — unexpected error.
pub async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginRequest>,
) -> AppResult<impl IntoResponse> {
    let user = state.user_service.login(body).await?;
    
    // Signed JWT (HS256); `?` returns the `AppError` straight to the client as a response.
    let token = create_token(user.id, &state.jwt_config)?;

    let response = LoginResponse {
        token,
        user_id: user.id,
        email: user.email,
        username: user.username,
        display_name: user.display_name,
        onboarding_completed: user.onboarding_completed,
    };
    
    Ok((StatusCode::OK, Json(response)))
}

/// `GET /users/:id`
///
/// Get user profile information by ID.
///
/// # Path parameters
/// - `id` — User UUID.
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — the path user id is not the token's user.
/// - `200 OK` — returns [`UserProfileResponse`].
/// - `404 Not Found` — user not found.
/// - `500 Internal Server Error` — unexpected error.
pub async fn get_user(
    auth: AuthUser,
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    let user = state.user_service.get_user_by_id(user_id).await?;
    let response: UserProfileResponse = user.into();
    Ok((StatusCode::OK, Json(response)))
}

/// `PATCH /users/:id`
///
/// Update user profile information.
///
/// # Path parameters
/// - `id` — User UUID.
///
/// # Request body
/// JSON body matching [`UpdateUserRequest`].
///
/// # Responses
/// - `401 Unauthorized` — missing or invalid Bearer token.
/// - `403 Forbidden` — the path user id is not the token's user.
/// - `200 OK` — profile updated, returns [`UserProfileResponse`].
/// - `404 Not Found` — user not found.
/// - `422 Unprocessable Entity` — validation failed.
/// - `500 Internal Server Error` — unexpected error.
pub async fn update_user(
    auth: AuthUser,
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
    Json(body): Json<UpdateUserRequest>,
) -> AppResult<impl IntoResponse> {
    auth.ensure_user(user_id)?;
    // Only the id is logged: the body holds health data (height, weight, goals).
    tracing::info!(%user_id, "update_user called");
    let user = state.user_service.update_user(user_id, body).await?;
    let response: UserProfileResponse = user.into();
    Ok((StatusCode::OK, Json(response)))
}

