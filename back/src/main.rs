use std::sync::Arc;

use tokio::net::TcpListener;
use tower_http::{compression::CompressionLayer, cors::CorsLayer, trace::TraceLayer};

mod config;
mod db;
mod errors;
mod handlers;
mod models;
mod repositories;
mod routes;
mod services;

use config::Config;
use repositories::user::UserRepository;
use services::user::UserService;

/// Shared application state injected into every handler via Axum's `State` extractor.
#[derive(Clone)]
pub struct AppState {
    pub user_service: Arc<UserService>,
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

    let state = AppState { user_service };

    // 6. Build the Axum router with middleware
    let app = routes::build_router(state)
        .layer(TraceLayer::new_for_http())
        .layer(CompressionLayer::new())
        .layer(CorsLayer::permissive()); // TODO(security): restrict origins before production

    // 7. Bind and serve
    let addr = format!("{}:{}", config.server_host, config.server_port);
    let listener = TcpListener::bind(&addr).await?;
    tracing::info!("Listening on http://{}", addr);

    axum::serve(listener, app).await?;

    Ok(())
}
