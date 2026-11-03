use std::{net::SocketAddr, sync::Arc, time::Duration};

use tokio::net::TcpListener;
use tower_http::{compression::CompressionLayer, trace::TraceLayer};

mod auth;
mod config;
mod cors;
mod db;
mod errors;
mod handlers;
mod models;
mod rate_limit;
mod repositories;
mod routes;
mod services;
#[cfg(test)]
mod tests;

use config::{Config, JwtConfig};
use cors::build_cors_layer;
use repositories::program::ProgramRepository;
use repositories::user::UserRepository;
use repositories::workout::WorkoutRepository;
use services::program::ProgramService;
use services::user::UserService;
use services::workout::WorkoutService;

/// Shared application state injected into every handler via Axum's `State` extractor.
#[derive(Clone)]
pub struct AppState {
    /// JWT settings, shared read-only; `Arc` makes cloning the state cheap.
    pub jwt_config: Arc<JwtConfig>,
    pub user_service: Arc<UserService>,
    pub workout_service: Arc<WorkoutService>,
    /// Builds programs through the ML engine, with a cache fallback.
    pub program_service: Arc<ProgramService>,
    /// Base URL of the AI service (same `AI_SERVICE_URL` as `ProgramService`).
    pub ai_service_url: Arc<String>,
    /// HTTP client of the video analysis proxy, with its own long timeout
    /// (`AI_ANALYSIS_TIMEOUT_SECS`). `reqwest::Client` is already a cheap,
    /// reference-counted handle, so cloning the state does not open new pools.
    pub analysis_client: reqwest::Client,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // 1. Load .env file (optional in production — env vars are already set)
    dotenvy::dotenv().ok();

    // 2. Initialise structured logging
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive("liftup_backend=debug".parse()?),
        )
        .init();

    // 3. Load config
    let config = Config::from_env()?;
    tracing::info!("Starting LiftUp backend on {}:{}", config.server_host, config.server_port);

    // 4. Set up the database pool and run migrations
    let pool = db::create_pool(&config).await?;
    db::run_migrations(&pool).await?;

    // 5. Wire up the dependency graph
    let user_repository = UserRepository::new(pool.clone());
    let user_service = Arc::new(UserService::new(user_repository));

    let workout_repository = WorkoutRepository::new(pool.clone());
    let workout_service = Arc::new(WorkoutService::new(workout_repository));

    // One ProgramService (and thus one reqwest client) for the whole app.
    let program_service = Arc::new(ProgramService::new(
        config.ai_service_url.clone(),
        Duration::from_secs(config.ai_timeout_secs),
        UserRepository::new(pool.clone()),
        ProgramRepository::new(pool.clone()),
    )?);

    // Built once: a client keeps a connection pool, so it must not be created per request.
    // A separate client from ProgramService: its 5 s timeout is too short for a video upload.
    let analysis_client = reqwest::Client::builder()
        .timeout(Duration::from_secs(config.ai_analysis_timeout_secs))
        .build()?;

    // Clone the config once into an `Arc`: `config` keeps its own copy for the rest of main.
    let jwt_config = Arc::new(config.jwt.clone());

    let state = AppState {
        jwt_config,
        user_service,
        workout_service,
        program_service,
        ai_service_url: Arc::new(config.ai_service_url.clone()),
        analysis_client,
    };

    // 6. Build the Axum router with middleware.
    // Built first so an invalid CORS_ALLOWED_ORIGINS stops the startup with a clear error.
    let cors_layer = build_cors_layer(&config)?;

    // Layers wrap the router from the inside out: the last `.layer(...)` is the outermost,
    // so CORS sees every request first and answers preflight OPTIONS before routing.
    let app = routes::build_router(state, config.login_rate_limit_per_minute, config.max_upload_bytes)?
        .layer(TraceLayer::new_for_http())
        .layer(CompressionLayer::new())
        .layer(cors_layer);

    // 7. Bind and serve
    let addr = format!("{}:{}", config.server_host, config.server_port);
    let listener = TcpListener::bind(&addr).await?;
    tracing::info!("Listening on http://{}", addr);

    // `ConnectInfo<SocketAddr>` exposes the peer IP: the rate limiter falls back to it
    // when no proxy header is present.
    axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>()).await?;

    Ok(())
}
