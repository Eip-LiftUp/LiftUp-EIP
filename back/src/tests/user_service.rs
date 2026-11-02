//! `UserService` tests, calling the service directly on a temporary database.

use sqlx::PgPool;

use crate::{
    errors::AppError,
    models::user::{LoginRequest, UpdateUserRequest, UserProfileResponse},
    tests::common::{build_test_state, create_user_request, register_user, TEST_PASSWORD},
};

/// Given a valid request, when the user is created, then it is stored with a bcrypt hash
/// that is not the plain password.
#[sqlx::test]
async fn create_user_stores_bcrypt_hash(pool: PgPool) {
    let state = build_test_state(pool);

    let user = register_user(&state, "alice@example.com", "alice").await;

    assert_eq!(user.email, "alice@example.com");
    assert_ne!(user.password_hash, TEST_PASSWORD);
    assert!(bcrypt::verify(TEST_PASSWORD, &user.password_hash).unwrap());
}

/// Given an existing email, when another user registers with it, then `Conflict` is returned.
#[sqlx::test]
async fn create_user_with_duplicate_email_is_conflict(pool: PgPool) {
    let state = build_test_state(pool);
    register_user(&state, "alice@example.com", "alice").await;

    let result = state
        .user_service
        .create_user(create_user_request("alice@example.com", "alice2", TEST_PASSWORD))
        .await;

    assert!(matches!(result, Err(AppError::Conflict(_))));
}

/// Given an invalid email, a short username or a short password, when creating a user,
/// then `Validation` is returned for each.
#[sqlx::test]
async fn create_user_with_invalid_input_is_validation_error(pool: PgPool) {
    let state = build_test_state(pool);

    let bad_requests = [
        create_user_request("not-an-email", "alice", TEST_PASSWORD),
        create_user_request("alice@example.com", "al", TEST_PASSWORD),
        create_user_request("alice@example.com", "alice", "short"),
    ];

    for request in bad_requests {
        let result = state.user_service.create_user(request).await;
        assert!(matches!(result, Err(AppError::Validation(_))), "got {result:?}");
    }
}

/// Given a registered user, when logging in with the right password, then the user is returned.
#[sqlx::test]
async fn login_with_correct_password_succeeds(pool: PgPool) {
    let state = build_test_state(pool);
    let created = register_user(&state, "alice@example.com", "alice").await;

    let user = state
        .user_service
        .login(LoginRequest {
            email: "alice@example.com".to_string(),
            password: TEST_PASSWORD.to_string(),
        })
        .await
        .unwrap();

    assert_eq!(user.id, created.id);
}

/// Given a registered user, when logging in with a wrong password, then `Unauthorized` is returned.
#[sqlx::test]
async fn login_with_wrong_password_is_unauthorized(pool: PgPool) {
    let state = build_test_state(pool);
    register_user(&state, "alice@example.com", "alice").await;

    let result = state
        .user_service
        .login(LoginRequest {
            email: "alice@example.com".to_string(),
            password: "wrong-password".to_string(),
        })
        .await;

    assert!(matches!(result, Err(AppError::Unauthorized(_))));
}

/// Given a user with a profile, when updating only one field, then the other fields
/// are kept (the SQL uses COALESCE).
#[sqlx::test]
async fn partial_update_keeps_other_fields(pool: PgPool) {
    let state = build_test_state(pool);
    let created: crate::models::user::CreateUserRequest = serde_json::from_value(serde_json::json!({
        "email": "alice@example.com",
        "username": "alice",
        "password": TEST_PASSWORD,
        "display_name": "Alice",
        "height_cm": 170,
        "weight_kg": 60.5,
    }))
    .unwrap();
    let user = state.user_service.create_user(created).await.unwrap();

    // The update DTO is camelCase, unlike the creation DTO.
    let update: UpdateUserRequest =
        serde_json::from_value(serde_json::json!({ "fitnessGoals": "Gain strength" })).unwrap();
    let updated = state.user_service.update_user(user.id, update).await.unwrap();

    let profile = UserProfileResponse::from(updated);
    assert_eq!(profile.fitness_goals.as_deref(), Some("Gain strength"));
    assert_eq!(profile.display_name.as_deref(), Some("Alice"));
    assert_eq!(profile.height_cm, Some(170));
    assert_eq!(profile.weight_kg, Some(60.5));
}

/// Given two registrations with the same email running at the same time, when both
/// are awaited together, then exactly one succeeds and the other is a `Conflict`
/// (never an `Internal` error), whichever of the two checks catches it.
#[sqlx::test]
async fn concurrent_create_user_with_same_email_gives_one_conflict(pool: PgPool) {
    let state = build_test_state(pool);
    let service = &state.user_service;

    // `join!` polls both futures concurrently on the same task: both run
    // `email_exists` (and the slow bcrypt hash) before either one inserts.
    let (first, second) = tokio::join!(
        service.create_user(create_user_request("race@example.com", "racer1", TEST_PASSWORD)),
        service.create_user(create_user_request("race@example.com", "racer2", TEST_PASSWORD)),
    );

    let results = [first, second];
    let successes = results.iter().filter(|r| r.is_ok()).count();
    let conflicts = results
        .iter()
        .filter(|r| matches!(r, Err(AppError::Conflict(_))))
        .count();
    assert_eq!(successes, 1, "got {results:?}");
    assert_eq!(conflicts, 1, "got {results:?}");
}
