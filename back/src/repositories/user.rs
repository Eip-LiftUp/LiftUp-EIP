use rust_decimal::Decimal;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::AppResult,
    models::user::{CreateUserRequest, FitnessLevel, User, UpdateUserRequest},
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
    pub async fn create(&self, req: &CreateUserRequest, password_hash: &str) -> AppResult<User> {
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
                birth_date, height_cm, weight_kg, fitness_level, password_hash
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
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
        .bind(password_hash)
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

    /// Fetch a user by email address.
    pub async fn find_by_email(&self, email: &str) -> AppResult<Option<User>> {
        let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = $1")
            .bind(email)
            .fetch_optional(&self.pool)
            .await?;

        Ok(user)
    }

    /// Update user profile fields.
    pub async fn update(&self, user_id: Uuid, req: &UpdateUserRequest) -> AppResult<User> {
        let fitness_level_str = req.fitness_level.as_ref().map(|f| match f {
            FitnessLevel::Beginner => "beginner",
            FitnessLevel::Intermediate => "intermediate",
            FitnessLevel::Advanced => "advanced",
        });

        let activity_frequency_str = req.activity_frequency.as_ref().map(|f| match f {
            crate::models::user::ActivityFrequency::Sedentary => "sedentary",
            crate::models::user::ActivityFrequency::Light => "light",
            crate::models::user::ActivityFrequency::Moderate => "moderate",
            crate::models::user::ActivityFrequency::Active => "active",
            crate::models::user::ActivityFrequency::VeryActive => "very_active",
        });

        let weight: Option<Decimal> = req
            .weight_kg
            .map(|w| Decimal::from_f64_retain(w).unwrap_or(Decimal::ZERO));

        let user = sqlx::query_as::<_, User>(
            r#"
            UPDATE users
            SET
                display_name = COALESCE($1, display_name),
                birth_date = COALESCE($2, birth_date),
                height_cm = COALESCE($3, height_cm),
                weight_kg = COALESCE($4, weight_kg),
                fitness_level = COALESCE($5, fitness_level),
                fitness_goals = COALESCE($6, fitness_goals),
                activity_frequency = COALESCE($7, activity_frequency),
                has_injuries = COALESCE($8, has_injuries),
                medical_notes = COALESCE($9, medical_notes),
                injured_zones = COALESCE($10, injured_zones),
                training_focus = COALESCE($11, training_focus),
                onboarding_completed = COALESCE($12, onboarding_completed)
            WHERE id = $13
            RETURNING *
            "#,
        )
        .bind(&req.display_name)
        .bind(req.birth_date)
        .bind(req.height_cm)
        .bind(weight)
        .bind(fitness_level_str)
        .bind(&req.fitness_goals)
        .bind(activity_frequency_str)
        .bind(req.has_injuries)
        .bind(&req.medical_notes)
        .bind(&req.injured_zones)
        .bind(&req.training_focus)
        .bind(req.onboarding_completed)
        .bind(user_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }
}
