//! JWT creation and verification (HS256).
//!
//! Tokens carry the user id (`sub`), the issue time (`iat`) and the expiry
//! time (`exp`). Every verification failure is mapped to one generic
//! `401 Unauthorized` error so that no internal detail leaks to clients.

use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    config::JwtConfig,
    errors::{AppError, AppResult},
};

/// Payload stored inside every LiftUp JWT.
#[derive(Debug, Serialize, Deserialize, PartialEq)]
pub struct Claims {
    /// Subject: the id of the authenticated user.
    pub sub: Uuid,
    /// Issued-at time, as a Unix timestamp in seconds.
    pub iat: i64,
    /// Expiry time, as a Unix timestamp in seconds.
    pub exp: i64,
}

/// Creates a signed JWT for `user_id`, valid for `config.expiration_days` days.
///
/// # Errors
/// Returns [`AppError::Internal`] if the token cannot be signed.
pub fn create_token(user_id: Uuid, config: &JwtConfig) -> AppResult<String> {
    let now = Utc::now();
    let claims = Claims {
        sub: user_id,
        iat: now.timestamp(),
        exp: (now + Duration::days(config.expiration_days)).timestamp(),
    };

    // `map_err` turns the library error into our `AppError`. `AppError::Internal`
    // logs the details and sends a generic 500 to the client.
    encode(
        &Header::new(Algorithm::HS256),
        &claims,
        &EncodingKey::from_secret(config.secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(format!("Failed to sign JWT: {e}")))
}

/// Verifies the signature and the expiry of `token` and returns its [`Claims`].
///
/// # Errors
/// Returns [`AppError::Unauthorized`] with the message `"Invalid or expired token"`
/// for any failure (bad format, bad signature, wrong secret, expired token).
pub fn verify_token(token: &str, config: &JwtConfig) -> AppResult<Claims> {
    // Only HS256 is accepted, which prevents algorithm-confusion attacks.
    let mut validation = Validation::new(Algorithm::HS256);
    validation.validate_exp = true;
    // The default leeway is 60 s, which would accept tokens expired a minute ago.
    validation.leeway = 0;

    decode::<Claims>(
        token,
        &DecodingKey::from_secret(config.secret.as_bytes()),
        &validation,
    )
    .map(|data| data.claims)
    // The `|_|` deliberately drops the library error: clients must not learn why it failed.
    .map_err(|_| AppError::Unauthorized("Invalid or expired token".to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    const SECRET: &str = "0123456789abcdef0123456789abcdef";

    /// Builds a test config with the given secret and a 7-day expiry.
    fn test_config(secret: &str) -> JwtConfig {
        JwtConfig {
            secret: secret.to_string(),
            expiration_days: 7,
        }
    }

    /// Asserts that `result` is the generic unauthorized error.
    fn assert_unauthorized<T: std::fmt::Debug>(result: AppResult<T>) {
        match result {
            Err(AppError::Unauthorized(msg)) => assert_eq!(msg, "Invalid or expired token"),
            other => panic!("expected Unauthorized, got {other:?}"),
        }
    }

    #[test]
    fn round_trip_returns_same_user() {
        let config = test_config(SECRET);
        let user_id = Uuid::new_v4();

        let token = create_token(user_id, &config).unwrap();
        let claims = verify_token(&token, &config).unwrap();

        assert_eq!(claims.sub, user_id);
    }

    #[test]
    fn tampered_signature_is_rejected() {
        let config = test_config(SECRET);
        let token = create_token(Uuid::new_v4(), &config).unwrap();

        // Alter the first character of the signature (the part after the last '.').
        // The last character is avoided: its low bits are base64 padding and may be ignored.
        let sig_start = token.rfind('.').unwrap() + 1;
        let first = token.as_bytes()[sig_start] as char;
        let replacement = if first == 'A' { 'B' } else { 'A' };
        let mut tampered = token.clone();
        tampered.replace_range(sig_start..sig_start + 1, &replacement.to_string());

        assert_unauthorized(verify_token(&tampered, &config));
    }

    #[test]
    fn expired_token_is_rejected() {
        let config = test_config(SECRET);
        let now = Utc::now();
        // Expired one second ago: must fail because leeway is 0.
        let claims = Claims {
            sub: Uuid::new_v4(),
            iat: (now - Duration::days(1)).timestamp(),
            exp: (now - Duration::seconds(1)).timestamp(),
        };
        let token = encode(
            &Header::new(Algorithm::HS256),
            &claims,
            &EncodingKey::from_secret(SECRET.as_bytes()),
        )
        .unwrap();

        assert_unauthorized(verify_token(&token, &config));
    }

    #[test]
    fn wrong_secret_is_rejected() {
        let token = create_token(Uuid::new_v4(), &test_config(SECRET)).unwrap();
        let other = test_config("another-secret-of-at-least-32-chars!!");

        assert_unauthorized(verify_token(&token, &other));
    }

    #[test]
    fn expiry_is_issue_time_plus_seven_days() {
        let config = test_config(SECRET);
        let token = create_token(Uuid::new_v4(), &config).unwrap();
        let claims = verify_token(&token, &config).unwrap();

        assert_eq!(claims.exp - claims.iat, Duration::days(7).num_seconds());
    }
}
