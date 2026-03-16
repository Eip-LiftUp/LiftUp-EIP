use uuid::Uuid;
use validator::Validate;

use crate::{
    errors::{AppError, AppResult},
    models::workout::{
        CreateExerciseRequest, CreateWorkoutRequest, UpdateExerciseRequest,
        UpdateWorkoutRequest, WorkoutResponse, ExerciseResponse,
    },
    repositories::workout::WorkoutRepository,
};

/// Business logic for workout management
pub struct WorkoutService {
    repository: WorkoutRepository,
}

impl WorkoutService {
    pub fn new(repository: WorkoutRepository) -> Self {
        Self { repository }
    }

    // ==================== WORKOUTS ====================

    /// Create a new workout for a user
    pub async fn create_workout(
        &self,
        user_id: Uuid,
        req: CreateWorkoutRequest,
    ) -> AppResult<WorkoutResponse> {
        // Validate input
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        // Create workout
        let workout = self.repository.create_workout(user_id, &req).await?;
        
        // Get exercises (will be empty initially)
        let exercises = self.repository.find_exercises_by_workout(workout.id).await?;

        tracing::info!("Workout created: {} for user {}", workout.name, user_id);

        Ok(WorkoutResponse {
            id: workout.id,
            user_id: workout.user_id,
            name: workout.name,
            workout_date: workout.workout_date.to_string(),
            duration_minutes: workout.duration_minutes,
            notes: workout.notes,
            is_completed: workout.is_completed,
            exercises: exercises.into_iter().map(ExerciseResponse::from).collect(),
            created_at: workout.created_at,
            updated_at: workout.updated_at,
        })
    }

    /// Get workout by ID with exercises
    pub async fn get_workout(&self, workout_id: Uuid, user_id: Uuid) -> AppResult<WorkoutResponse> {
        let workout = self
            .repository
            .find_workout_by_id(workout_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Workout with id '{}' not found", workout_id)))?;

        // Verify ownership
        if workout.user_id != user_id {
            return Err(AppError::Forbidden("You don't have access to this workout".to_string()));
        }

        // Get exercises
        let exercises = self.repository.find_exercises_by_workout(workout_id).await?;

        Ok(WorkoutResponse {
            id: workout.id,
            user_id: workout.user_id,
            name: workout.name,
            workout_date: workout.workout_date.to_string(),
            duration_minutes: workout.duration_minutes,
            notes: workout.notes,
            is_completed: workout.is_completed,
            exercises: exercises.into_iter().map(ExerciseResponse::from).collect(),
            created_at: workout.created_at,
            updated_at: workout.updated_at,
        })
    }

    /// Get all workouts for a user
    pub async fn get_user_workouts(&self, user_id: Uuid) -> AppResult<Vec<WorkoutResponse>> {
        let workouts = self.repository.find_workouts_by_user(user_id).await?;
        
        let mut responses = Vec::new();
        for workout in workouts {
            let exercises = self.repository.find_exercises_by_workout(workout.id).await?;
            responses.push(WorkoutResponse {
                id: workout.id,
                user_id: workout.user_id,
                name: workout.name,
                workout_date: workout.workout_date.to_string(),
                duration_minutes: workout.duration_minutes,
                notes: workout.notes,
                is_completed: workout.is_completed,
                exercises: exercises.into_iter().map(ExerciseResponse::from).collect(),
                created_at: workout.created_at,
                updated_at: workout.updated_at,
            });
        }

        Ok(responses)
    }

    /// Update workout
    pub async fn update_workout(
        &self,
        workout_id: Uuid,
        user_id: Uuid,
        req: UpdateWorkoutRequest,
    ) -> AppResult<WorkoutResponse> {
        // Validate input
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        // Check ownership
        let existing_workout = self
            .repository
            .find_workout_by_id(workout_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Workout with id '{}' not found", workout_id)))?;

        if existing_workout.user_id != user_id {
            return Err(AppError::Forbidden("You don't have access to this workout".to_string()));
        }

        // Update workout
        let workout = self.repository.update_workout(workout_id, &req).await?;
        
        // Get exercises
        let exercises = self.repository.find_exercises_by_workout(workout_id).await?;

        tracing::info!("Workout updated: {} by user {}", workout_id, user_id);

        Ok(WorkoutResponse {
            id: workout.id,
            user_id: workout.user_id,
            name: workout.name,
            workout_date: workout.workout_date.to_string(),
            duration_minutes: workout.duration_minutes,
            notes: workout.notes,
            is_completed: workout.is_completed,
            exercises: exercises.into_iter().map(ExerciseResponse::from).collect(),
            created_at: workout.created_at,
            updated_at: workout.updated_at,
        })
    }

    /// Delete workout
    pub async fn delete_workout(&self, workout_id: Uuid, user_id: Uuid) -> AppResult<()> {
        // Check ownership
        let workout = self
            .repository
            .find_workout_by_id(workout_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Workout with id '{}' not found", workout_id)))?;

        if workout.user_id != user_id {
            return Err(AppError::Forbidden("You don't have access to this workout".to_string()));
        }

        self.repository.delete_workout(workout_id).await?;
        
        tracing::info!("Workout deleted: {} by user {}", workout_id, user_id);
        Ok(())
    }

    // ==================== EXERCISES ====================

    /// Add exercise to workout
    pub async fn add_exercise(
        &self,
        workout_id: Uuid,
        user_id: Uuid,
        req: CreateExerciseRequest,
    ) -> AppResult<ExerciseResponse> {
        // Validate input
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        // Check workout ownership
        let workout = self
            .repository
            .find_workout_by_id(workout_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Workout with id '{}' not found", workout_id)))?;

        if workout.user_id != user_id {
            return Err(AppError::Forbidden("You don't have access to this workout".to_string()));
        }

        // Create exercise
        let exercise = self.repository.create_exercise(workout_id, &req).await?;

        tracing::info!("Exercise added: {} to workout {}", exercise.exercise_name, workout_id);

        Ok(ExerciseResponse::from(exercise))
    }

    /// Update exercise
    pub async fn update_exercise(
        &self,
        exercise_id: Uuid,
        user_id: Uuid,
        req: UpdateExerciseRequest,
    ) -> AppResult<ExerciseResponse> {
        // Validate input
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        // Check exercise exists and get workout
        let exercise = self
            .repository
            .find_exercise_by_id(exercise_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Exercise with id '{}' not found", exercise_id)))?;

        // Check workout ownership
        let workout = self
            .repository
            .find_workout_by_id(exercise.workout_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Workout not found".to_string()))?;

        if workout.user_id != user_id {
            return Err(AppError::Forbidden("You don't have access to this exercise".to_string()));
        }

        // Update exercise
        let updated_exercise = self.repository.update_exercise(exercise_id, &req).await?;

        tracing::info!("Exercise updated: {} by user {}", exercise_id, user_id);

        Ok(ExerciseResponse::from(updated_exercise))
    }

    /// Delete exercise
    pub async fn delete_exercise(&self, exercise_id: Uuid, user_id: Uuid) -> AppResult<()> {
        // Check exercise exists and get workout
        let exercise = self
            .repository
            .find_exercise_by_id(exercise_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Exercise with id '{}' not found", exercise_id)))?;

        // Check workout ownership
        let workout = self
            .repository
            .find_workout_by_id(exercise.workout_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Workout not found".to_string()))?;

        if workout.user_id != user_id {
            return Err(AppError::Forbidden("You don't have access to this exercise".to_string()));
        }

        self.repository.delete_exercise(exercise_id).await?;
        
        tracing::info!("Exercise deleted: {} by user {}", exercise_id, user_id);
        Ok(())
    }
}
