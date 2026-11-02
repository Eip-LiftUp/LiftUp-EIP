//! Integration-style tests that need a PostgreSQL database.
//!
//! The crate is a binary, so a top-level `tests/` directory could not import
//! its code; these tests live inside the crate instead (`#[cfg(test)] mod tests;`
//! in `main.rs`). Each `#[sqlx::test]` gets its own temporary database, created
//! from `DATABASE_URL`, with the migrations of `./migrations` already applied.

mod common;
mod http;
mod program_repository;
mod user_service;
mod workout_service;
