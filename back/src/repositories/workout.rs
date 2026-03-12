use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::{AppError, AppResult},
    models::workout::{
        CreateExerciseRequest, CreateWorkoutRequest, Exercise, UpdateExerciseRequest,
        UpdateWorkoutRequest, Workout,
    },
};

/// Repository for workout and exercise database operations
pub struct WorkoutRepository {
    pool: PgPool,
}

impl WorkoutRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    // ==================== WORKOUTS ====================

    /// Create a new workout
    pub async fn create_workout(
        &self,
        user_id: Uuid,
        req: &CreateWorkoutRequest,
    ) -> AppResult<Workout> {
        let workout = sqlx::query_as::<_, Workout>(
            r#"
            INSERT INTO workouts (user_id, name, workout_date, duration_minutes, notes)
            VALUES ($1, $2, COALESCE($3, CURRENT_DATE), $4, $5)
            RETURNING *
            "#,
        )
        .bind(user_id)
        .bind(&req.name)
        .bind(req.workout_date)
        .bind(req.duration_minutes)
        .bind(&req.notes)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::Internal(format!("Failed to create workout: {}", e)))?;

        Ok(workout)
    }

    /// Get workout by ID
    pub async fn find_workout_by_id(&self, workout_id: Uuid) -> AppResult<Option<Workout>> {
        let workout = sqlx::query_as::<_, Workout>(
            "SELECT * FROM workouts WHERE id = $1",
        )
        .bind(workout_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::Internal(format!("Failed to fetch workout: {}", e)))?;

        Ok(workout)
    }

    /// Get all workouts for a user
    pub async fn find_workouts_by_user(&self, user_id: Uuid) -> AppResult<Vec<Workout>> {
        let workouts = sqlx::query_as::<_, Workout>(
            "SELECT * FROM workouts WHERE user_id = $1 ORDER BY workout_date DESC, created_at DESC",
        )
        .bind(user_id)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::Internal(format!("Failed to fetch workouts: {}", e)))?;

        Ok(workouts)
    }

    /// Update workout
    pub async fn update_workout(
        &self,
        workout_id: Uuid,
        req: &UpdateWorkoutRequest,
    ) -> AppResult<Workout> {
        let workout = sqlx::query_as::<_, Workout>(
            r#"
            UPDATE workouts
            SET name = COALESCE($1, name),
                workout_date = COALESCE($2, workout_date),
                duration_minutes = COALESCE($3, duration_minutes),
                notes = COALESCE($4, notes),
                is_completed = COALESCE($5, is_completed),
                updated_at = NOW()
            WHERE id = $6
            RETURNING *
            "#,
        )
        .bind(&req.name)
        .bind(req.workout_date)
        .bind(req.duration_minutes)
        .bind(&req.notes)
        .bind(req.is_completed)
        .bind(workout_id)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::Internal(format!("Failed to update workout: {}", e)))?;

        Ok(workout)
    }

    /// Delete workout
    pub async fn delete_workout(&self, workout_id: Uuid) -> AppResult<()> {
        sqlx::query("DELETE FROM workouts WHERE id = $1")
            .bind(workout_id)
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to delete workout: {}", e)))?;

        Ok(())
    }

    // ==================== EXERCISES ====================

    /// Create exercise
    pub async fn create_exercise(
        &self,
        workout_id: Uuid,
        req: &CreateExerciseRequest,
    ) -> AppResult<Exercise> {
        let weight_unit = req.weight_unit.as_ref().map(|u| format!("{:?}", u).to_lowercase()).unwrap_or_else(|| "kg".to_string());
        
        let exercise = sqlx::query_as::<_, Exercise>(
            r#"
            INSERT INTO exercises (workout_id, exercise_name, sets, reps, weight, weight_unit, order_index, notes)
            VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7, 0), $8)
            RETURNING *
            "#,
        )
        .bind(workout_id)
        .bind(&req.exercise_name)
        .bind(req.sets)
        .bind(req.reps)
        .bind(req.weight)
        .bind(&weight_unit)
        .bind(req.order_index)
        .bind(&req.notes)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::Internal(format!("Failed to create exercise: {}", e)))?;

        Ok(exercise)
    }

    /// Get exercises for a workout
    pub async fn find_exercises_by_workout(&self, workout_id: Uuid) -> AppResult<Vec<Exercise>> {
        let exercises = sqlx::query_as::<_, Exercise>(
            "SELECT * FROM exercises WHERE workout_id = $1 ORDER BY order_index ASC, created_at ASC",
        )
        .bind(workout_id)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::Internal(format!("Failed to fetch exercises: {}", e)))?;

        Ok(exercises)
    }

    /// Get exercise by ID
    pub async fn find_exercise_by_id(&self, exercise_id: Uuid) -> AppResult<Option<Exercise>> {
        let exercise = sqlx::query_as::<_, Exercise>(
            "SELECT * FROM exercises WHERE id = $1",
        )
        .bind(exercise_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::Internal(format!("Failed to fetch exercise: {}", e)))?;

        Ok(exercise)
    }

    /// Update exercise
    pub async fn update_exercise(
        &self,
        exercise_id: Uuid,
        req: &UpdateExerciseRequest,
    ) -> AppResult<Exercise> {
        let weight_unit = req.weight_unit.as_ref().map(|u| format!("{:?}", u).to_lowercase());
        
        let exercise = sqlx::query_as::<_, Exercise>(
            r#"
            UPDATE exercises
            SET exercise_name = COALESCE($1, exercise_name),
                sets = COALESCE($2, sets),
                reps = COALESCE($3, reps),
                weight = COALESCE($4, weight),
                weight_unit = COALESCE($5, weight_unit),
                order_index = COALESCE($6, order_index),
                notes = COALESCE($7, notes),
                is_completed = COALESCE($8, is_completed),
                sets_data = COALESCE($9, sets_data)
            WHERE id = $10
            RETURNING *
            "#,
        )
        .bind(&req.exercise_name)
        .bind(req.sets)
        .bind(req.reps)
        .bind(req.weight)
        .bind(&weight_unit)
        .bind(req.order_index)
        .bind(&req.notes)
        .bind(req.is_completed)
        .bind(&req.sets_data)
        .bind(exercise_id)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::Internal(format!("Failed to update exercise: {}", e)))?;

        Ok(exercise)
    }

    /// Delete exercise
    pub async fn delete_exercise(&self, exercise_id: Uuid) -> AppResult<()> {
        sqlx::query("DELETE FROM exercises WHERE id = $1")
            .bind(exercise_id)
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to delete exercise: {}", e)))?;

        Ok(())
    }
}
