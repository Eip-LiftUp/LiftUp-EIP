use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

/// Weight unit enum
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum WeightUnit {
    Kg,
    Lbs,
}

impl Default for WeightUnit {
    fn default() -> Self {
        WeightUnit::Kg
    }
}

/// Workout entity from database
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Workout {
    pub id: Uuid,
    pub user_id: Uuid,
    pub name: String,
    pub workout_date: NaiveDate,
    pub duration_minutes: Option<i32>,
    pub notes: Option<String>,
    pub is_completed: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Exercise entity from database
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Exercise {
    pub id: Uuid,
    pub workout_id: Uuid,
    pub exercise_name: String,
    pub sets: i32,
    pub reps: i32,
    pub weight: Option<rust_decimal::Decimal>,
    pub weight_unit: String,
    pub order_index: i32,
    pub notes: Option<String>,
    pub is_completed: bool,
    pub created_at: DateTime<Utc>,
}

// ==================== DTOs ====================

/// DTO for creating a new workout
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct CreateWorkoutRequest {
    #[validate(length(min = 1, max = 255, message = "Workout name must be between 1 and 255 characters"))]
    pub name: String,
    
    pub workout_date: Option<NaiveDate>,
    
    #[validate(range(min = 1, max = 600, message = "Duration must be between 1 and 600 minutes"))]
    pub duration_minutes: Option<i32>,
    
    pub notes: Option<String>,
}

/// DTO for updating a workout
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct UpdateWorkoutRequest {
    pub name: Option<String>,
    pub workout_date: Option<NaiveDate>,
    pub duration_minutes: Option<i32>,
    pub notes: Option<String>,
    pub is_completed: Option<bool>,
}

/// DTO for creating an exercise
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct CreateExerciseRequest {
    #[validate(length(min = 1, max = 255, message = "Exercise name must be between 1 and 255 characters"))]
    pub exercise_name: String,
    
    #[validate(range(min = 1, max = 100, message = "Sets must be between 1 and 100"))]
    pub sets: i32,
    
    #[validate(range(min = 1, max = 1000, message = "Reps must be between 1 and 1000"))]
    pub reps: i32,
    
    pub weight: Option<f64>,
    
    pub weight_unit: Option<WeightUnit>,
    
    pub order_index: Option<i32>,
    
    pub notes: Option<String>,
}

/// DTO for updating an exercise
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct UpdateExerciseRequest {
    pub exercise_name: Option<String>,
    pub sets: Option<i32>,
    pub reps: Option<i32>,
    pub weight: Option<f64>,
    pub weight_unit: Option<WeightUnit>,
    pub order_index: Option<i32>,
    pub notes: Option<String>,
    pub is_completed: Option<bool>,
}

/// Response for workout with exercises
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct WorkoutResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub name: String,
    pub workout_date: String,
    pub duration_minutes: Option<i32>,
    pub notes: Option<String>,
    pub is_completed: bool,
    pub exercises: Vec<ExerciseResponse>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Response for a single exercise
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExerciseResponse {
    pub id: Uuid,
    pub workout_id: Uuid,
    pub exercise_name: String,
    pub sets: i32,
    pub reps: i32,
    pub weight: Option<f64>,
    pub weight_unit: String,
    pub order_index: i32,
    pub notes: Option<String>,
    pub is_completed: bool,
    pub created_at: DateTime<Utc>,
}

impl From<Exercise> for ExerciseResponse {
    fn from(e: Exercise) -> Self {
        Self {
            id: e.id,
            workout_id: e.workout_id,
            exercise_name: e.exercise_name,
            sets: e.sets,
            reps: e.reps,
            weight: e.weight.map(|w| w.to_string().parse().unwrap_or(0.0)),
            weight_unit: e.weight_unit,
            order_index: e.order_index,
            notes: e.notes,
            is_completed: e.is_completed,
            created_at: e.created_at,
        }
    }
}
