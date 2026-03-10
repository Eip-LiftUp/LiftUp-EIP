use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

/// Fitness level of a user.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum FitnessLevel {
    Beginner,
    Intermediate,
    Advanced,
}

impl Default for FitnessLevel {
    fn default() -> Self {
        FitnessLevel::Beginner
    }
}

/// The persistent User entity, mapped 1-to-1 with the `users` table.
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    pub display_name: Option<String>,
    pub birth_date: Option<NaiveDate>,
    pub height_cm: Option<i16>,
    pub weight_kg: Option<rust_decimal::Decimal>,
    pub fitness_level: String,
    pub fitness_goals: Option<String>,
    pub password_hash: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// DTO — payload expected from the client when registering a new user.
/// Corresponds to the body of `POST /users`.
#[derive(Debug, Deserialize, Validate)]
pub struct CreateUserRequest {
    #[validate(email(message = "Invalid email format"))]
    pub email: String,

    #[validate(length(min = 3, max = 100, message = "Username must be between 3 and 100 characters"))]
    pub username: String,

    #[validate(length(min = 8, message = "Password must be at least 8 characters"))]
    pub password: String,

    pub display_name: Option<String>,

    pub birth_date: Option<NaiveDate>,

    #[validate(range(min = 1, max = 299, message = "Height must be between 1 and 299 cm"))]
    pub height_cm: Option<i16>,

    #[validate(range(min = 1.0, max = 699.0, message = "Weight must be between 1 and 699 kg"))]
    pub weight_kg: Option<f64>,

    pub fitness_level: Option<FitnessLevel>,
}

/// DTO — shape of the JSON body returned after successful user creation.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateUserResponse {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    pub display_name: Option<String>,
    pub fitness_level: String,
    pub created_at: DateTime<Utc>,
}

impl From<User> for CreateUserResponse {
    fn from(u: User) -> Self {
        Self {
            id: u.id,
            email: u.email,
            username: u.username,
            display_name: u.display_name,
            fitness_level: u.fitness_level,
            created_at: u.created_at,
        }
    }
}

/// DTO — payload for logging in
#[derive(Debug, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email(message = "Invalid email format"))]
    pub email: String,

    #[validate(length(min = 1, message = "Password is required"))]
    pub password: String,
}

/// DTO — response after successful login
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LoginResponse {
    pub token: String,
    pub user_id: Uuid,
    pub email: String,
    pub username: String,
    pub display_name: Option<String>,
}

/// DTO — payload for updating user profile
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct UpdateUserRequest {
    pub display_name: Option<String>,

    pub birth_date: Option<NaiveDate>,

    #[validate(range(min = 1, max = 299, message = "Height must be between 1 and 299 cm"))]
    pub height_cm: Option<i16>,

    #[validate(range(min = 1.0, max = 699.0, message = "Weight must be between 1 and 699 kg"))]
    pub weight_kg: Option<f64>,

    pub fitness_level: Option<FitnessLevel>,

    pub fitness_goals: Option<String>,
}

/// DTO — user profile response
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UserProfileResponse {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    pub display_name: Option<String>,
    pub birth_date: Option<String>,
    pub height_cm: Option<i16>,
    pub weight_kg: Option<f64>,
    pub fitness_level: String,
    pub fitness_goals: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<User> for UserProfileResponse {
    fn from(u: User) -> Self {
        Self {
            id: u.id,
            email: u.email,
            username: u.username,
            display_name: u.display_name,
            birth_date: u.birth_date.map(|d| d.to_string()),
            height_cm: u.height_cm,
            weight_kg: u.weight_kg.map(|w| w.to_string().parse().unwrap_or(0.0)),
            fitness_level: u.fitness_level,
            fitness_goals: u.fitness_goals,
            created_at: u.created_at,
            updated_at: u.updated_at,
        }
    }
}
