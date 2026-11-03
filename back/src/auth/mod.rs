//! Authentication module: JWT helpers and the [`AuthUser`] Axum extractor.

pub mod jwt;

use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{header::AUTHORIZATION, request::Parts},
};
use uuid::Uuid;

use crate::{
    errors::{AppError, AppResult},
    AppState,
};

/// Id of the authenticated user, extracted from the `Authorization: Bearer <token>` header.
///
/// Add it as a handler argument to require authentication: a request without a
/// valid token is rejected with `401` before the handler body runs.
/// Put it before body extractors such as `Json`, so the `401` wins over body
/// parsing errors.
pub struct AuthUser(pub Uuid);

impl AuthUser {
    /// Checks that the authenticated user is the user identified by `user_id`
    /// (usually the id found in the request path).
    ///
    /// # Errors
    /// Returns [`AppError::Forbidden`] if `user_id` differs from the token's user.
    pub fn ensure_user(&self, user_id: Uuid) -> AppResult<()> {
        if self.0 == user_id {
            Ok(())
        } else {
            Err(AppError::Forbidden("You can only access your own data".to_string()))
        }
    }
}

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
