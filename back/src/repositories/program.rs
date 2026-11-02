//! Database access for the `cached_programs` table.

use sqlx::PgPool;
use uuid::Uuid;

use crate::{errors::AppResult, models::program::CachedProgram};

/// All database operations related to the `cached_programs` table.
pub struct ProgramRepository {
    pool: PgPool,
}

impl ProgramRepository {
    /// Creates a repository that uses the given connection pool.
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Saves `program` as the cached program of `user_id`, replacing any previous one.
    ///
    /// Inserts a row, or updates it if the user already has one; `generated_at`
    /// is reset to now in both cases. Returns the stored row.
    ///
    /// # Errors
    /// Returns [`crate::errors::AppError::Database`] if the query fails
    /// (for example when `user_id` does not exist in `users`).
    pub async fn upsert(
        &self,
        user_id: Uuid,
        program: &serde_json::Value,
    ) -> AppResult<CachedProgram> {
        // `&Value` is borrowed for the query only; sqlx encodes it as JSONB
        // through `bind`, so no manual serialization is needed.
        let cached = sqlx::query_as::<_, CachedProgram>(
            r#"
            INSERT INTO cached_programs (user_id, program)
            VALUES ($1, $2)
            ON CONFLICT (user_id) DO UPDATE
                SET program = EXCLUDED.program,
                    generated_at = NOW()
            RETURNING *
            "#,
        )
        .bind(user_id)
        .bind(program)
        .fetch_one(&self.pool)
        .await?;

        Ok(cached)
    }

    /// Returns the cached program of `user_id`, or `None` if there is none.
    ///
    /// # Errors
    /// Returns [`crate::errors::AppError::Database`] if the query fails.
    pub async fn find_by_user(&self, user_id: Uuid) -> AppResult<Option<CachedProgram>> {
        let cached = sqlx::query_as::<_, CachedProgram>(
            "SELECT * FROM cached_programs WHERE user_id = $1",
        )
        .bind(user_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(cached)
    }
}
