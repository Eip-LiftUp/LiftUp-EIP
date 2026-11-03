//! Application configuration loaded from environment variables.

use anyhow::Context;
use std::env;
use std::fmt;

/// Minimum accepted length (in characters) of `JWT_SECRET`.
const JWT_SECRET_MIN_LEN: usize = 32;

/// Default JWT lifetime in days when `JWT_EXPIRATION_DAYS` is not set.
const DEFAULT_JWT_EXPIRATION_DAYS: i64 = 7;

/// Settings used to sign and verify JWTs.
#[derive(Clone)]
pub struct JwtConfig {
    /// Secret key used for HS256 signing. Never log it.
    pub secret: String,
    /// Token lifetime, in days.
    pub expiration_days: i64,
}

// `Debug` is written by hand (instead of derived) so the secret can never
// end up in logs, even if a parent struct is printed with `{:?}`.
impl fmt::Debug for JwtConfig {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("JwtConfig")
            .field("secret", &"[REDACTED]")
            .field("expiration_days", &self.expiration_days)
            .finish()
    }
}

/// Default CORS origins for local development (Flutter web served by nginx on port 8090).
const DEFAULT_CORS_ALLOWED_ORIGINS: &str = "http://localhost:8090,http://127.0.0.1:8090";

/// Default number of login attempts allowed per minute and per IP.
const DEFAULT_LOGIN_RATE_LIMIT_PER_MINUTE: u32 = 5;

/// Default base URL of the Python AI service (local development).
const DEFAULT_AI_SERVICE_URL: &str = "http://localhost:8000";

/// Default timeout, in seconds, of a call to the AI service.
const DEFAULT_AI_TIMEOUT_SECS: u64 = 5;

/// Default timeout, in seconds, of a video analysis call (much longer than
/// `AI_TIMEOUT_SECS`: uploading and analysing a video takes time).
const DEFAULT_AI_ANALYSIS_TIMEOUT_SECS: u64 = 120;

/// Application configuration loaded from environment variables.
#[derive(Debug, Clone)]
pub struct Config {
    pub server_host: String,
    pub server_port: u16,
    pub database_url: String,
    pub database_max_connections: u32,
    /// JWT signing settings (the secret is masked in `Debug` output).
    pub jwt: JwtConfig,
    /// Origins allowed to call the API from a browser (raw values, validated in `cors.rs`).
    pub cors_allowed_origins: Vec<String>,
    /// Login attempts allowed per minute and per IP (burst size of the rate limiter).
    pub login_rate_limit_per_minute: u32,
    /// Base URL of the Python AI service, without trailing slash.
    pub ai_service_url: String,
    /// Timeout of a call to the AI service, in seconds.
    pub ai_timeout_secs: u64,
    /// Timeout of a video analysis call to the AI service, in seconds.
    pub ai_analysis_timeout_secs: u64,
}

/// Parses an optional environment value as a strictly positive number of seconds.
///
/// `raw` is the value read from the environment (`None` if the variable is not
/// set); `name` is only used in the error message. Taking the value as a
/// parameter, instead of reading the environment here, keeps this testable
/// without touching global process state.
///
/// # Errors
/// Returns an error if the value is not an integer, or is zero.
fn parse_positive_secs(name: &str, raw: Option<String>, default: u64) -> anyhow::Result<u64> {
    let secs: u64 = match raw {
        Some(value) => value
            .parse()
            .with_context(|| format!("{name} must be a positive integer"))?,
        None => default,
    };
    if secs == 0 {
        anyhow::bail!("{name} must be a positive integer");
    }
    Ok(secs)
}

impl Config {
    /// Load configuration from the environment (requires dotenvy to have loaded .env).
    ///
    /// # Errors
    /// Returns an error if `DATABASE_URL` is missing, if `JWT_SECRET` is missing or
    /// shorter than 32 characters, or if a numeric variable (`JWT_EXPIRATION_DAYS`,
    /// `LOGIN_RATE_LIMIT_PER_MINUTE`, `AI_TIMEOUT_SECS`, `AI_ANALYSIS_TIMEOUT_SECS`,
    /// ports, pool size) cannot be parsed or is not a positive integer.
    pub fn from_env() -> anyhow::Result<Self> {
        // No default value on purpose: a built-in secret would be public knowledge.
        let jwt_secret = env::var("JWT_SECRET")
            .map_err(|_| anyhow::anyhow!("JWT_SECRET must be set"))?;
        // `chars().count()` counts characters, not bytes.
        if jwt_secret.chars().count() < JWT_SECRET_MIN_LEN {
            anyhow::bail!("JWT_SECRET must be at least {JWT_SECRET_MIN_LEN} characters long");
        }

        let jwt_expiration_days: i64 = match env::var("JWT_EXPIRATION_DAYS") {
            Ok(value) => value.parse()?,
            Err(_) => DEFAULT_JWT_EXPIRATION_DAYS,
        };
        if jwt_expiration_days <= 0 {
            anyhow::bail!("JWT_EXPIRATION_DAYS must be a positive integer");
        }

        let login_rate_limit_per_minute: u32 = match env::var("LOGIN_RATE_LIMIT_PER_MINUTE") {
            Ok(value) => value.parse()?,
            Err(_) => DEFAULT_LOGIN_RATE_LIMIT_PER_MINUTE,
        };
        if login_rate_limit_per_minute == 0 {
            anyhow::bail!("LOGIN_RATE_LIMIT_PER_MINUTE must be a positive integer");
        }

        let ai_timeout_secs =
            parse_positive_secs("AI_TIMEOUT_SECS", env::var("AI_TIMEOUT_SECS").ok(), DEFAULT_AI_TIMEOUT_SECS)?;
        let ai_analysis_timeout_secs = parse_positive_secs(
            "AI_ANALYSIS_TIMEOUT_SECS",
            env::var("AI_ANALYSIS_TIMEOUT_SECS").ok(),
            DEFAULT_AI_ANALYSIS_TIMEOUT_SECS,
        )?;

        // A trailing slash is removed so that `{url}/api/...` never contains `//`.
        let ai_service_url = env::var("AI_SERVICE_URL")
            .unwrap_or_else(|_| DEFAULT_AI_SERVICE_URL.to_string())
            .trim_end_matches('/')
            .to_string();

        Ok(Self {
            ai_service_url,
            ai_timeout_secs,
            ai_analysis_timeout_secs,
            server_host: env::var("SERVER_HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
            server_port: env::var("SERVER_PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()?,
            // `context` turns the `VarError` into an `anyhow::Error` with a clear message.
            database_url: env::var("DATABASE_URL").context("DATABASE_URL must be set")?,
            database_max_connections: env::var("DATABASE_MAX_CONNECTIONS")
                .unwrap_or_else(|_| "10".to_string())
                .parse()?,
            // Split on commas and trim spaces; empty entries (e.g. trailing comma) are dropped.
            cors_allowed_origins: env::var("CORS_ALLOWED_ORIGINS")
                .unwrap_or_else(|_| DEFAULT_CORS_ALLOWED_ORIGINS.to_string())
                .split(',')
                .map(|origin| origin.trim().to_string())
                .filter(|origin| !origin.is_empty())
                .collect(),
            login_rate_limit_per_minute,
            jwt: JwtConfig {
                secret: jwt_secret,
                expiration_days: jwt_expiration_days,
            },
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Given no value, when parsed, then the default is used.
    #[test]
    fn parse_positive_secs_uses_default_when_unset() {
        assert_eq!(parse_positive_secs("X", None, 120).unwrap(), 120);
    }

    /// Given a valid number, when parsed, then it overrides the default.
    #[test]
    fn parse_positive_secs_reads_value() {
        assert_eq!(parse_positive_secs("X", Some("30".to_string()), 120).unwrap(), 30);
    }

    /// Given a non-numeric, negative or zero value, when parsed, then an error
    /// naming the variable is returned.
    #[test]
    fn parse_positive_secs_rejects_invalid_values() {
        for raw in ["abc", "-5", "0", ""] {
            let error = parse_positive_secs("AI_ANALYSIS_TIMEOUT_SECS", Some(raw.to_string()), 120)
                .unwrap_err();
            assert!(error.to_string().contains("AI_ANALYSIS_TIMEOUT_SECS"), "{raw}: {error}");
        }
    }
}
