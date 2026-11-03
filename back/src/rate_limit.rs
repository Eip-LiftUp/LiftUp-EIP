//! Rate limiting of `POST /auth/login` (brute-force protection), per client IP.
//!
//! Built on `tower_governor`: each IP gets a bucket of `N` tokens
//! (`LOGIN_RATE_LIMIT_PER_MINUTE`) refilled at one token every `60 / N` seconds.
//! When the bucket is empty the client receives `429 Too Many Requests` with a
//! JSON body and the retry headers added by the library.

use std::time::Duration;

use anyhow::Context;
use axum::{
    body::Body,
    http::{Response, StatusCode},
    response::IntoResponse,
    Json,
};
use governor::{clock::QuantaInstant, middleware::NoOpMiddleware};
use serde_json::json;
use tower_governor::{
    governor::GovernorConfigBuilder, key_extractor::SmartIpKeyExtractor, GovernorError,
    GovernorLayer,
};

/// Concrete type of the layer returned by [`login_rate_limit_layer`].
pub type LoginRateLimitLayer = GovernorLayer<SmartIpKeyExtractor, NoOpMiddleware<QuantaInstant>>;

/// How often the limiter drops the state of IPs that are no longer limited.
const CLEANUP_INTERVAL: Duration = Duration::from_secs(60);

/// Builds the rate-limit layer for the login route and starts its cleanup task.
///
/// The key is the client IP, read by [`SmartIpKeyExtractor`] from
/// `X-Forwarded-For`, then `X-Real-IP`, then `Forwarded`, and finally from the
/// TCP peer address.
///
/// **Security warning:** these headers are only trustworthy when a reverse proxy
/// (DigitalOcean) sets them. If the server is exposed directly to the internet,
/// an attacker can send a different fake `X-Forwarded-For` on every request and
/// bypass the limit. Besides, the extractor reads the *first* address of
/// `X-Forwarded-For`, which is the one supplied by the client itself, so the
/// proxy must overwrite the header rather than append to it.
///
/// This function spawns a tokio task, so it must be called inside a tokio runtime.
///
/// # Errors
/// Returns an error if `per_minute` is `0` (a burst or a period of zero is invalid).
pub fn login_rate_limit_layer(per_minute: u32) -> anyhow::Result<LoginRateLimitLayer> {
    if per_minute == 0 {
        anyhow::bail!("LOGIN_RATE_LIMIT_PER_MINUTE must be greater than 0");
    }

    // `finish()` returns an `Option`; `context` turns `None` into an `anyhow` error.
    let config = GovernorConfigBuilder::default()
        .key_extractor(SmartIpKeyExtractor)
        // One token every 60/N seconds; a float keeps the precision for N that does not divide 60.
        .period(Duration::from_secs_f64(60.0 / f64::from(per_minute)))
        .burst_size(per_minute)
        .error_handler(too_many_requests_response)
        .finish()
        .context("Invalid login rate limit configuration")?;

    // The limiter keeps one entry per IP forever unless cleaned: without this
    // task, the memory would grow with every new client IP.
    // `limiter()` is borrowed, so we clone the `Arc` to move an owned handle into the task.
    let limiter = config.limiter().clone();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(CLEANUP_INTERVAL);
        loop {
            interval.tick().await;
            limiter.retain_recent();
            tracing::debug!("Login rate limiter tracks {} IP(s)", limiter.len());
        }
    });

    Ok(GovernorLayer {
        config: std::sync::Arc::new(config),
    })
}

/// Turns a limiter error into the HTTP response sent to the client.
fn too_many_requests_response(error: GovernorError) -> Response<Body> {
    match error {
        GovernorError::TooManyRequests { headers, .. } => {
            let mut response = (
                StatusCode::TOO_MANY_REQUESTS,
                Json(json!({ "error": "Too many login attempts, please retry later" })),
            )
                .into_response();
            // Keep the `retry-after` / `x-ratelimit-after` headers added by the library.
            if let Some(headers) = headers {
                response.headers_mut().extend(headers);
            }
            response
        }
        // Other errors (e.g. no client IP found): same JSON format as the rest of the API,
        // generic message, and the cause is only logged.
        other => {
            tracing::error!("Login rate limiter error: {:?}", other);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Internal server error" })),
            )
                .into_response()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{routing::post, Router};
    use axum_test::TestServer;
    use serde_json::Value;

    const LIMIT: u32 = 3;

    /// Mini server whose login handler always answers 401, behind the rate limiter (no database).
    fn test_server() -> TestServer {
        let layer = login_rate_limit_layer(LIMIT).unwrap();
        let app = Router::new()
            .route("/auth/login", post(|| async { StatusCode::UNAUTHORIZED }))
            .layer(layer);
        TestServer::new(app).unwrap()
    }

    /// Sends a login request that looks like it comes from `ip` (through a proxy header).
    async fn login_from(server: &TestServer, ip: &'static str) -> axum_test::TestResponse {
        server
            .post("/auth/login")
            .add_header(
                "x-forwarded-for".parse().unwrap(),
                axum::http::HeaderValue::from_static(ip),
            )
            .await
    }

    /// Given a limit of N, when one IP sends N requests, then they reach the handler (401),
    /// and the N+1th is blocked with 429.
    #[tokio::test]
    async fn request_after_the_burst_is_blocked() {
        let server = test_server();

        for _ in 0..LIMIT {
            login_from(&server, "203.0.113.1").await.assert_status(StatusCode::UNAUTHORIZED);
        }

        login_from(&server, "203.0.113.1")
            .await
            .assert_status(StatusCode::TOO_MANY_REQUESTS);
    }

    /// Given an IP that is blocked, when another IP sends a request, then it is not blocked.
    #[tokio::test]
    async fn other_ip_is_not_blocked() {
        let server = test_server();
        for _ in 0..=LIMIT {
            login_from(&server, "203.0.113.1").await;
        }

        login_from(&server, "203.0.113.2").await.assert_status(StatusCode::UNAUTHORIZED);
    }

    /// Given a blocked IP, when the 429 is returned, then the body is the JSON error and
    /// the library's retry header is kept.
    #[tokio::test]
    async fn blocked_response_is_json_with_retry_header() {
        let server = test_server();
        for _ in 0..LIMIT {
            login_from(&server, "203.0.113.1").await;
        }

        let response = login_from(&server, "203.0.113.1").await;

        response.assert_status(StatusCode::TOO_MANY_REQUESTS);
        assert_eq!(
            response.json::<Value>(),
            json!({ "error": "Too many login attempts, please retry later" })
        );
        assert!(response.header("content-type").to_str().unwrap().starts_with("application/json"));
        assert!(response.maybe_header("retry-after").is_some());
    }

    /// Given a limit of 0, when building the layer, then an error is returned.
    #[tokio::test]
    async fn zero_limit_is_refused() {
        assert!(login_rate_limit_layer(0).is_err());
    }

    /// Given a request without any client IP (no proxy header, no peer address),
    /// when it reaches the limiter, then the answer is a JSON 500 with a generic message.
    #[tokio::test]
    async fn missing_client_ip_returns_json_500() {
        let server = test_server();

        let response = server.post("/auth/login").await;

        response.assert_status(StatusCode::INTERNAL_SERVER_ERROR);
        assert_eq!(response.json::<Value>(), json!({ "error": "Internal server error" }));
        assert!(response.header("content-type").to_str().unwrap().starts_with("application/json"));
    }
}
