use sqlx::{postgres::PgPoolOptions, PgPool};

use crate::config::Config;

/// Create and return a PostgreSQL connection pool.
pub async fn create_pool(config: &Config) -> anyhow::Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(config.database_max_connections)
        .connect(&config.database_url)
        .await?;

    tracing::info!("Database connection pool established.");
    Ok(pool)
}

/// Run pending SQLx migrations (files under `migrations/`).
pub async fn run_migrations(pool: &PgPool) -> anyhow::Result<()> {
    sqlx::migrate!("./migrations").run(pool).await?;
    tracing::info!("Database migrations applied.");
    Ok(())
}
