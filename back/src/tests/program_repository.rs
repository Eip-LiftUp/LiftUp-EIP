//! `ProgramRepository` tests on a temporary database (migration 0008 included).

use serde_json::json;
use sqlx::PgPool;

use crate::{
    repositories::program::ProgramRepository,
    tests::common::{build_test_state, register_user},
};

/// Given the migrations applied, when the catalog is queried, then `cached_programs` exists.
#[sqlx::test]
async fn cached_programs_table_exists(pool: PgPool) {
    let exists: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cached_programs')",
    )
    .fetch_one(&pool)
    .await
    .unwrap();

    assert!(exists);
}

/// Given a user, when two programs are upserted in a row, then there is one row
/// holding the last program.
#[sqlx::test]
async fn upsert_twice_keeps_one_row_with_last_program(pool: PgPool) {
    let state = build_test_state(pool.clone());
    let user = register_user(&state, "alice@example.com", "alice").await;
    let repository = ProgramRepository::new(pool.clone());

    let first = repository.upsert(user.id, &json!({ "version": 1 })).await.unwrap();
    let second = repository.upsert(user.id, &json!({ "version": 2 })).await.unwrap();

    let rows: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM cached_programs WHERE user_id = $1")
        .bind(user.id)
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(rows, 1);
    assert_eq!(second.program, json!({ "version": 2 }));
    assert!(second.generated_at >= first.generated_at);

    let found = repository.find_by_user(user.id).await.unwrap().unwrap();
    assert_eq!(found.program, json!({ "version": 2 }));
}

/// Given a user without cached program, when `find_by_user` is called, then it returns `None`.
#[sqlx::test]
async fn find_by_user_without_cache_returns_none(pool: PgPool) {
    let state = build_test_state(pool.clone());
    let user = register_user(&state, "alice@example.com", "alice").await;
    let repository = ProgramRepository::new(pool);

    assert!(repository.find_by_user(user.id).await.unwrap().is_none());
}

/// Given a cached program, when its user is deleted, then the row is deleted too (CASCADE).
#[sqlx::test]
async fn deleting_user_deletes_cached_program(pool: PgPool) {
    let state = build_test_state(pool.clone());
    let user = register_user(&state, "alice@example.com", "alice").await;
    let repository = ProgramRepository::new(pool.clone());
    repository.upsert(user.id, &json!({ "version": 1 })).await.unwrap();

    sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(user.id)
        .execute(&pool)
        .await
        .unwrap();

    assert!(repository.find_by_user(user.id).await.unwrap().is_none());
}
