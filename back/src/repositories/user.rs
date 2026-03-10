use rust_decimal::Decimal;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::AppResult,
    models::user::{CreateUserRequest, FitnessLevel, User},
};

/// All database operations related to the `users` table.
pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Check whether an email address already exists in the database.
    pub async fn email_exists(&self, email: &str) -> AppResult<bool> {
        let row = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)",
        )
        .bind(email)
        .fetch_one(&self.pool)
        .await?;

        Ok(row)
    }

    /// Insert a new user row and return the created entity.
    pub async fn create(&self, req: &CreateUserRequest) -> AppResult<User> {
        let fitness_level = req
            .fitness_level
            .as_ref()
            .unwrap_or(&FitnessLevel::Beginner);

        let fitness_level_str = match fitness_level {
            FitnessLevel::Beginner => "beginner",
            FitnessLevel::Intermediate => "intermediate",
            FitnessLevel::Advanced => "advanced",
        };

        let weight: Option<Decimal> = req
            .weight_kg
            .map(|w| Decimal::from_f64_retain(w).unwrap_or(Decimal::ZERO));

        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (
                email, username, display_name,
                birth_date, height_cm, weight_kg, fitness_level
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            "#,
        )
        .bind(&req.email)
        .bind(&req.username)
        .bind(&req.display_name)
        .bind(req.birth_date)
        .bind(req.height_cm)
        .bind(weight)
        .bind(fitness_level_str)
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    /// Fetch a user by its UUID.
    pub async fn find_by_id(&self, id: Uuid) -> AppResult<Option<User>> {
        let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await?;

        Ok(user)
    }
}
