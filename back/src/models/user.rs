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

/// Self-reported training frequency, collected on the mandatory onboarding page.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum ActivityFrequency {
    Sedentary,
    Light,
    Moderate,
    Active,
    VeryActive,
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
    pub activity_frequency: Option<String>,
    pub has_injuries: Option<bool>,
    pub medical_notes: Option<String>,
    pub injured_zones: Option<Vec<String>>,
    pub training_focus: Option<Vec<String>>,
    pub onboarding_completed: bool,
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
    pub onboarding_completed: bool,
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

    pub activity_frequency: Option<ActivityFrequency>,

    pub has_injuries: Option<bool>,

    #[validate(length(max = 5000, message = "Medical notes must be at most 5000 characters"))]
    pub medical_notes: Option<String>,

    pub injured_zones: Option<Vec<String>>,

    pub training_focus: Option<Vec<String>>,

    pub onboarding_completed: Option<bool>,
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
    pub activity_frequency: Option<String>,
    pub has_injuries: Option<bool>,
    pub medical_notes: Option<String>,
    pub injured_zones: Option<Vec<String>>,
    pub training_focus: Option<Vec<String>>,
    pub onboarding_completed: bool,
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
            activity_frequency: u.activity_frequency,
            has_injuries: u.has_injuries,
            medical_notes: u.medical_notes,
            injured_zones: u.injured_zones,
            training_focus: u.training_focus,
            onboarding_completed: u.onboarding_completed,
            created_at: u.created_at,
            updated_at: u.updated_at,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Builds a valid [`CreateUserRequest`] to tweak field by field.
    fn valid_request() -> CreateUserRequest {
        serde_json::from_value(serde_json::json!({
            "email": "alice@example.com",
            "username": "alice",
            "password": "password123",
        }))
        .unwrap()
    }

    /// Given valid data, when validated, then no error is reported.
    #[test]
    fn valid_create_request_passes() {
        assert!(valid_request().validate().is_ok());
    }

    /// Given a malformed email, when validated, then the error mentions the email.
    #[test]
    fn invalid_email_is_rejected() {
        let mut req = valid_request();
        req.email = "not-an-email".to_string();

        let err = req.validate().unwrap_err().to_string();
        assert!(err.contains("Invalid email format"));
    }

    /// Given usernames of 2 and 101 characters, when validated, then both are rejected;
    /// the bounds 3 and 100 are accepted.
    #[test]
    fn username_length_bounds() {
        let mut req = valid_request();
        for (username, ok) in [("ab", false), ("abc", true), (&"a".repeat(100), true), (&"a".repeat(101), false)] {
            req.username = username.to_string();
            assert_eq!(req.validate().is_ok(), ok, "username of {} chars", username.len());
        }
    }

    /// Given passwords of 7 and 8 characters, when validated, then only 8 is accepted.
    #[test]
    fn password_minimum_length() {
        let mut req = valid_request();
        req.password = "1234567".to_string();
        assert!(req.validate().is_err());
        req.password = "12345678".to_string();
        assert!(req.validate().is_ok());
    }

    /// Given out-of-range height and weight, when validated, then they are rejected.
    #[test]
    fn height_and_weight_ranges() {
        let mut req = valid_request();
        req.height_cm = Some(300);
        assert!(req.validate().is_err());
        req.height_cm = Some(170);
        req.weight_kg = Some(700.0);
        assert!(req.validate().is_err());
        req.weight_kg = Some(70.0);
        assert!(req.validate().is_ok());
    }

    /// Given an empty password, when validating a login request, then it is rejected.
    #[test]
    fn login_requires_password() {
        let req = LoginRequest { email: "alice@example.com".to_string(), password: String::new() };
        assert!(req.validate().is_err());
    }

    /// Given a camelCase JSON body, when deserialized, then `UpdateUserRequest` reads it
    /// (the creation DTO is snake_case, the update DTO is camelCase).
    #[test]
    fn update_request_is_camel_case() {
        let req: UpdateUserRequest =
            serde_json::from_value(serde_json::json!({ "displayName": "Alice", "heightCm": 170 })).unwrap();
        assert_eq!(req.display_name.as_deref(), Some("Alice"));
        assert_eq!(req.height_cm, Some(170));
    }
}
