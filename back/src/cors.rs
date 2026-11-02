//! CORS configuration: only whitelisted browser origins may read API responses.
//!
//! The server never "rejects" a request itself. For an origin that is not in
//! the whitelist, the response simply has no `Access-Control-Allow-Origin`
//! header, and the *browser* then blocks the page from reading it. The native
//! Flutter mobile app sends no `Origin` header at all, so only the Flutter web
//! build is affected by this layer.

use anyhow::{bail, Context};
use axum::http::{
    header::{AUTHORIZATION, CONTENT_TYPE},
    HeaderValue, Method,
};
use std::time::Duration;
use tower_http::cors::{AllowOrigin, CorsLayer};

use crate::config::Config;

/// Builds the CORS layer from `config.cors_allowed_origins`.
///
/// Credentials are not allowed on purpose: authentication uses a Bearer token
/// in the `Authorization` header, not cookies.
///
/// # Errors
/// Returns an error if the list is empty, contains `*`, or contains a value that
/// is not a valid origin (`http://` or `https://` host, without trailing slash).
pub fn build_cors_layer(config: &Config) -> anyhow::Result<CorsLayer> {
    if config.cors_allowed_origins.is_empty() {
        bail!("CORS_ALLOWED_ORIGINS must contain at least one origin");
    }

    // `iter()` borrows the strings; each one is parsed into an owned `HeaderValue`.
    // `collect` into `Result<Vec<_>, _>` stops at the first invalid origin.
    let origins = config
        .cors_allowed_origins
        .iter()
        .map(|origin| parse_origin(origin))
        .collect::<anyhow::Result<Vec<HeaderValue>>>()?;

    tracing::info!("CORS allowed origins: {:?}", config.cors_allowed_origins);

    Ok(CorsLayer::new()
        .allow_origin(AllowOrigin::list(origins))
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PATCH,
            Method::DELETE,
            Method::OPTIONS,
        ])
        .allow_headers([CONTENT_TYPE, AUTHORIZATION])
        .max_age(Duration::from_secs(3600)))
}

/// Checks one origin string and converts it to a header value.
fn parse_origin(origin: &str) -> anyhow::Result<HeaderValue> {
    if origin == "*" {
        bail!("CORS_ALLOWED_ORIGINS must not contain '*': list each allowed origin explicitly");
    }
    if !(origin.starts_with("http://") || origin.starts_with("https://")) {
        bail!("Invalid CORS origin '{origin}': it must start with http:// or https://");
    }
    // A browser sends origins without a trailing slash; with one, the match would never succeed.
    if origin.ends_with('/') {
        bail!("Invalid CORS origin '{origin}': remove the trailing '/'");
    }
    // `with_context` adds our message on top of the underlying parsing error.
    HeaderValue::from_str(origin).with_context(|| format!("Invalid CORS origin '{origin}'"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::JwtConfig;
    use axum::{routing::get, Router};
    use axum_test::TestServer;

    const ALLOWED: &str = "http://localhost:8090";

    /// Builds a `Config` that only matters for its CORS origins.
    fn test_config(origins: &[&str]) -> Config {
        Config {
            server_host: "127.0.0.1".to_string(),
            server_port: 8080,
            database_url: String::new(),
            database_max_connections: 1,
            jwt: JwtConfig {
                secret: "0123456789abcdef0123456789abcdef".to_string(),
                expiration_days: 7,
            },
            login_rate_limit_per_minute: 5,
            ai_service_url: "http://localhost:8000".to_string(),
            ai_timeout_secs: 5,
            cors_allowed_origins: origins.iter().map(|o| o.to_string()).collect(),
        }
    }

    /// Mini server with a single `/health` route and the CORS layer (no database).
    fn test_server() -> TestServer {
        let layer = build_cors_layer(&test_config(&[ALLOWED])).unwrap();
        let app = Router::new().route("/health", get(|| async { "ok" })).layer(layer);
        TestServer::new(app).unwrap()
    }

    #[tokio::test]
    async fn allowed_origin_gets_cors_header() {
        let response = test_server()
            .get("/health")
            .add_header("origin".parse().unwrap(), HeaderValue::from_static(ALLOWED))
            .await;

        assert_eq!(response.header("access-control-allow-origin"), ALLOWED);
    }

    #[tokio::test]
    async fn unlisted_origin_gets_no_cors_header() {
        let response = test_server()
            .get("/health")
            .add_header(
                "origin".parse().unwrap(),
                HeaderValue::from_static("http://evil.example.com"),
            )
            .await;

        // The request itself succeeds: it is the browser that blocks the response.
        response.assert_status_ok();
        assert!(response.maybe_header("access-control-allow-origin").is_none());
    }

    #[tokio::test]
    async fn preflight_from_allowed_origin_lists_methods() {
        let response = test_server()
            .method(Method::OPTIONS, "/health")
            .add_header("origin".parse().unwrap(), HeaderValue::from_static(ALLOWED))
            .add_header(
                "access-control-request-method".parse().unwrap(),
                HeaderValue::from_static("POST"),
            )
            .await;

        assert_eq!(response.header("access-control-allow-origin"), ALLOWED);
        let methods = response.header("access-control-allow-methods");
        assert!(methods.to_str().unwrap().contains("POST"));
    }

    #[test]
    fn wildcard_origin_is_refused() {
        assert!(build_cors_layer(&test_config(&["*"])).is_err());
    }

    #[test]
    fn invalid_origins_are_refused() {
        assert!(build_cors_layer(&test_config(&["localhost:8090"])).is_err());
        assert!(build_cors_layer(&test_config(&["http://localhost:8090/"])).is_err());
        assert!(build_cors_layer(&test_config(&[])).is_err());
    }
}
