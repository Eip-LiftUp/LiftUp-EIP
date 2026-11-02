//! Authentication module: JWT helpers and the [`AuthUser`] Axum extractor.

pub mod jwt;

use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{header::AUTHORIZATION, request::Parts},
};
use uuid::Uuid;

use crate::{errors::AppError, AppState};

/// Id of the authenticated user, extracted from the `Authorization: Bearer <token>` header.
///
/// Add it as a handler argument to require authentication. It is not used
/// by any route yet (the front-end does not send the header for now).
pub struct AuthUser(pub Uuid);

// `#[async_trait]` is required: Axum 0.7 declares this trait with it, so the
// implementation must use the same macro to have a matching signature.
#[async_trait]
impl FromRequestParts<AppState> for AuthUser {
    type Rejection = AppError;

    /// Reads and verifies the bearer token of the request.
    ///
    /// # Errors
    /// Returns [`AppError::Unauthorized`] if the header is missing, is not a
    /// `Bearer` header, or contains an invalid or expired token.
    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        // `to_str` fails on non-ASCII values; `strip_prefix` returns `None` without "Bearer ".
        let token = parts
            .headers
            .get(AUTHORIZATION)
            .and_then(|value| value.to_str().ok())
            .and_then(|value| value.strip_prefix("Bearer "))
            .ok_or_else(|| AppError::Unauthorized("Invalid or expired token".to_string()))?;

        let claims = jwt::verify_token(token, &state.jwt_config)?;
        Ok(AuthUser(claims.sub))
    }
}
