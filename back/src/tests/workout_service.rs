//! `WorkoutService` tests, calling the service directly on a temporary database.

use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::AppError,
    models::workout::{
        CreateExerciseRequest, CreateWorkoutRequest, UpdateExerciseRequest, UpdateWorkoutRequest,
    },
    tests::common::{build_test_state, register_user},
    AppState,
};

/// Builds a [`CreateWorkoutRequest`] with the given name (camelCase DTO).
fn workout_request(name: &str) -> CreateWorkoutRequest {
    serde_json::from_value(serde_json::json!({ "name": name })).unwrap()
}

/// Builds a [`CreateExerciseRequest`] for a weighted exercise.
fn exercise_request(name: &str) -> CreateExerciseRequest {
    serde_json::from_value(serde_json::json!({
        "exerciseName": name,
        "sets": 3,
        "reps": 10,
        "weight": 60.0,
    }))
    .unwrap()
}

/// Creates a user and one workout owned by that user; returns `(user_id, workout_id)`.
async fn user_with_workout(state: &AppState) -> (Uuid, Uuid) {
    let user = register_user(state, "alice@example.com", "alice").await;
    let workout = state
        .workout_service
        .create_workout(user.id, workout_request("Push day"))
        .await
        .unwrap();
    (user.id, workout.id)
}

/// Given a user, when a workout is created, then it can be read back by its owner.
#[sqlx::test]
async fn create_then_get_workout(pool: PgPool) {
    let state = build_test_state(pool);
    let (user_id, workout_id) = user_with_workout(&state).await;

    let workout = state.workout_service.get_workout(workout_id, user_id).await.unwrap();

    assert_eq!(workout.name, "Push day");
    assert_eq!(workout.user_id, user_id);
    assert!(workout.exercises.is_empty());
}

/// Given a workout of user A, when user B reads it, then `Forbidden` is returned.
#[sqlx::test]
async fn get_workout_of_another_user_is_forbidden(pool: PgPool) {
    let state = build_test_state(pool);
    let (_, workout_id) = user_with_workout(&state).await;
    let other = register_user(&state, "bob@example.com", "bobby").await;

    let result = state.workout_service.get_workout(workout_id, other.id).await;

    assert!(matches!(result, Err(AppError::Forbidden(_))));
}

/// Given a workout, when its name and completion are updated, then the response shows the changes.
#[sqlx::test]
async fn update_workout_changes_fields(pool: PgPool) {
    let state = build_test_state(pool);
    let (user_id, workout_id) = user_with_workout(&state).await;

    let update: UpdateWorkoutRequest =
        serde_json::from_value(serde_json::json!({ "name": "Pull day", "isCompleted": true }))
            .unwrap();
    let workout = state
        .workout_service
        .update_workout(workout_id, user_id, update)
        .await
        .unwrap();

    assert_eq!(workout.name, "Pull day");
    assert!(workout.is_completed);
}

/// Given a workout, when it is deleted, then reading it returns `NotFound`.
#[sqlx::test]
async fn delete_workout_then_get_is_not_found(pool: PgPool) {
    let state = build_test_state(pool);
    let (user_id, workout_id) = user_with_workout(&state).await;

    state.workout_service.delete_workout(workout_id, user_id).await.unwrap();
    let result = state.workout_service.get_workout(workout_id, user_id).await;

    assert!(matches!(result, Err(AppError::NotFound(_))));
}

/// Given a workout, when an exercise is added, updated and deleted, then each step is
/// reflected in the workout.
#[sqlx::test]
async fn add_update_delete_exercise(pool: PgPool) {
    let state = build_test_state(pool);
    let (user_id, workout_id) = user_with_workout(&state).await;

    // Add
    let exercise = state
        .workout_service
        .add_exercise(workout_id, user_id, exercise_request("Bench press"))
        .await
        .unwrap();
    assert_eq!(exercise.exercise_name, "Bench press");
    assert_eq!(exercise.sets, 3);
    assert_eq!(exercise.weight, Some(60.0));

    // Update
    let update: UpdateExerciseRequest =
        serde_json::from_value(serde_json::json!({ "reps": 12 })).unwrap();
    let updated = state
        .workout_service
        .update_exercise(exercise.id, user_id, update)
        .await
        .unwrap();
    assert_eq!(updated.reps, 12);
    assert_eq!(updated.sets, 3);

    // Delete
    state.workout_service.delete_exercise(exercise.id, user_id).await.unwrap();
    let workout = state.workout_service.get_workout(workout_id, user_id).await.unwrap();
    assert!(workout.exercises.is_empty());
}

/// Given an unknown user id, when creating a workout, then `NotFound` is expected.
#[sqlx::test]
async fn create_workout_for_unknown_user_is_not_found(pool: PgPool) {
    let state = build_test_state(pool);

    let result = state
        .workout_service
        .create_workout(Uuid::new_v4(), workout_request("Ghost workout"))
        .await;

    assert!(matches!(result, Err(AppError::NotFound(_))), "got {result:?}");
}
