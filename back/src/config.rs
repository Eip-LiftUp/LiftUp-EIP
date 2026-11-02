//! Application configuration loaded from environment variables.

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
}

impl Config {
    /// Load configuration from the environment (requires dotenvy to have loaded .env).
    ///
    /// # Errors
    /// Returns an error if a numeric variable cannot be parsed, if `JWT_SECRET`
    /// is missing or shorter than 32 characters, or if `JWT_EXPIRATION_DAYS` or
    /// `LOGIN_RATE_LIMIT_PER_MINUTE` or `AI_TIMEOUT_SECS` is not a positive integer.
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

        let ai_timeout_secs: u64 = match env::var("AI_TIMEOUT_SECS") {
            Ok(value) => value.parse()?,
            Err(_) => DEFAULT_AI_TIMEOUT_SECS,
        };
        if ai_timeout_secs == 0 {
            anyhow::bail!("AI_TIMEOUT_SECS must be a positive integer");
        }

        // A trailing slash is removed so that `{url}/api/...` never contains `//`.
        let ai_service_url = env::var("AI_SERVICE_URL")
            .unwrap_or_else(|_| DEFAULT_AI_SERVICE_URL.to_string())
            .trim_end_matches('/')
            .to_string();

        Ok(Self {
            ai_service_url,
            ai_timeout_secs,
            server_host: env::var("SERVER_HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
            server_port: env::var("SERVER_PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()?,
            database_url: env::var("DATABASE_URL")
                .expect("DATABASE_URL must be set"),
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
