//! Business logic of `GET /workouts/program`.
//!
//! The service asks the Python ML engine for a program, stores the result in the
//! `cached_programs` table, and falls back to that cache when the engine fails.
//! An AI outage must never produce a 500: the worst case is a 503.
//!
//! **Privacy:** `injured_zones` is health data. The request and response bodies
//! exchanged with the ML engine are never logged; warnings only contain the cause
//! (see [`MlError`]).

use std::time::Duration;

use chrono::Utc;
use rust_decimal::prelude::ToPrimitive;
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

use crate::{
    errors::{AppError, AppResult},
    models::{
        program::{ProgramExercise, ProgramResponse, ProgramSource, ProgramWorkout},
        user::User,
        workout::WeightUnit,
    },
    repositories::{program::ProgramRepository, user::UserRepository},
};

/// Maximum time allowed to open the TCP connection to the ML engine.
const AI_CONNECT_TIMEOUT: Duration = Duration::from_secs(1);

/// Path of the ML endpoint, appended to `AI_SERVICE_URL`.
///
/// PROVISIONAL: modelled on `/api/v1/video/*`, to be confirmed by the ML team.
const ML_GENERATE_PATH: &str = "/api/v1/program/generate";

/// Body sent to the ML engine.
///
/// PROVISIONAL: the contract is not frozen yet and must be validated by the ML
/// team. Kept separate from [`ProgramResponse`] on purpose, so the public API
/// does not change when the ML contract does.
#[derive(Debug, Serialize)]
struct MlProgramRequest {
    /// `beginner`, `intermediate` or `advanced`.
    fitness_level: String,
    fitness_goals: Option<String>,
    height_cm: Option<i16>,
    weight_kg: Option<f64>,
    /// Health data: never log it.
    injured_zones: Option<Vec<String>>,
}

/// Body returned by the ML engine. PROVISIONAL, see [`MlProgramRequest`].
///
/// It has no `generated_at` nor `source`: the backend adds them itself.
#[derive(Debug, Deserialize)]
struct MlProgramResponse {
    workouts: Vec<MlWorkout>,
}

/// One workout in the ML response. PROVISIONAL.
#[derive(Debug, Deserialize)]
struct MlWorkout {
    name: String,
    exercises: Vec<MlExercise>,
}

/// One exercise in the ML response. PROVISIONAL.
#[derive(Debug, Deserialize)]
struct MlExercise {
    exercise_name: String,
    sets: i32,
    reps: i32,
    /// `None` for bodyweight exercises.
    weight: Option<f64>,
    weight_unit: WeightUnit,
}

/// Why a call to the ML engine failed.
///
/// Only the kind of failure is kept (never the body), so it is safe to log.
#[derive(Debug, Error)]
enum MlError {
    #[error("timeout")]
    Timeout,
    #[error("connection failed")]
    Connection,
    #[error("unexpected HTTP status {0}")]
    Status(u16),
    #[error("invalid JSON in response")]
    InvalidJson,
    #[error("request failed")]
    Other,
}

impl From<reqwest::Error> for MlError {
    /// Classifies a `reqwest` error without keeping its message, which could
    /// contain details we do not want in the logs.
    fn from(error: reqwest::Error) -> Self {
        if error.is_timeout() {
            MlError::Timeout
        } else if error.is_connect() {
            MlError::Connection
        } else if error.is_decode() {
            MlError::InvalidJson
        } else {
            MlError::Other
        }
    }
}

/// Builds training programs by calling the ML engine, with a cache fallback.
pub struct ProgramService {
    /// Built once: a `reqwest::Client` keeps a connection pool, so it must be reused.
    client: reqwest::Client,
    /// Base URL of the AI service, without trailing slash.
    ai_service_url: String,
    user_repository: UserRepository,
    program_repository: ProgramRepository,
}

impl ProgramService {
    /// Creates the service and its HTTP client.
    ///
    /// `timeout` is the total time allowed for one ML call; the connection
    /// phase alone is limited to 1 second.
    ///
    /// # Errors
    /// Returns an error if the HTTP client cannot be built.
    pub fn new(
        ai_service_url: String,
        timeout: Duration,
        user_repository: UserRepository,
        program_repository: ProgramRepository,
    ) -> anyhow::Result<Self> {
        let client = reqwest::Client::builder()
            .timeout(timeout)
            .connect_timeout(AI_CONNECT_TIMEOUT)
            .build()?;

        Ok(Self { client, ai_service_url, user_repository, program_repository })
    }

    /// Returns the program of a user: freshly generated, or cached if the ML engine fails.
    ///
    /// # Errors
    /// - [`AppError::NotFound`] if the user does not exist.
    /// - [`AppError::ServiceUnavailable`] if the ML engine failed and there is no usable cache.
    /// - [`AppError::Database`] if reading the user or the cache fails.
    pub async fn get_program(&self, user_id: Uuid) -> AppResult<ProgramResponse> {
        let user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("User {user_id} not found")))?;

        match self.generate_remote(&user).await {
            Ok(ml_program) => {
                let program = to_program_response(ml_program);
                self.save_to_cache(user_id, &program).await;
                Ok(program)
            }
            Err(cause) => {
                // Log the cause only, never the bodies (health data).
                tracing::warn!(%user_id, %cause, "ML engine failed, trying the cache");
                self.read_from_cache(user_id).await
            }
        }
    }

    /// Calls the ML engine. Isolated here because the ML contract is PROVISIONAL.
    ///
    /// # Errors
    /// Returns an [`MlError`] on timeout, connection failure, non-2xx status
    /// or invalid JSON.
    async fn generate_remote(&self, user: &User) -> Result<MlProgramResponse, MlError> {
        let body = MlProgramRequest {
            fitness_level: user.fitness_level.clone(),
            fitness_goals: user.fitness_goals.clone(),
            height_cm: user.height_cm,
            // `Decimal` -> `f64` can fail in theory; `None` simply omits the value.
            weight_kg: user.weight_kg.and_then(|w| w.to_f64()),
            injured_zones: user.injured_zones.clone(),
        };

        let url = format!("{}{}", self.ai_service_url, ML_GENERATE_PATH);
        // `?` converts `reqwest::Error` into `MlError` through the `From` impl above.
        let response = self.client.post(url).json(&body).send().await?;

        let status = response.status();
        if !status.is_success() {
            return Err(MlError::Status(status.as_u16()));
        }

        Ok(response.json::<MlProgramResponse>().await?)
    }

    /// Stores the program as the user's "last known program".
    ///
    /// A failure here is only logged: the user still gets the program that was
    /// just generated.
    async fn save_to_cache(&self, user_id: Uuid, program: &ProgramResponse) {
        let json = match serde_json::to_value(program) {
            Ok(json) => json,
            Err(error) => {
                tracing::warn!(%user_id, %error, "could not serialize the program for the cache");
                return;
            }
        };
        if let Err(error) = self.program_repository.upsert(user_id, &json).await {
            tracing::warn!(%user_id, %error, "could not save the program in the cache");
        }
    }

    /// Reads the cached program, used when the ML engine failed.
    ///
    /// A cache row that no longer matches the current schema is treated as
    /// "no cache": a 503 is better than a 500.
    async fn read_from_cache(&self, user_id: Uuid) -> AppResult<ProgramResponse> {
        let unavailable = || {
            AppError::ServiceUnavailable(
                "Program generation is unavailable and no cached program exists".to_string(),
            )
        };

        let cached = self
            .program_repository
            .find_by_user(user_id)
            .await?
            .ok_or_else(unavailable)?;

        // `from_value` takes ownership of the JSON, so no copy is made.
        let mut program: ProgramResponse = match serde_json::from_value(cached.program) {
            Ok(program) => program,
            Err(_) => {
                tracing::warn!(%user_id, "cached program does not match the current schema");
                return Err(unavailable());
            }
        };

        // The SQL column is the reliable date; the one inside the JSON is overwritten.
        program.generated_at = cached.generated_at;
        program.source = ProgramSource::Cache;
        Ok(program)
    }
}

/// Converts the (provisional) ML response into the public [`ProgramResponse`].
///
/// `generated_at` and `source` are added here: the ML engine does not send them.
fn to_program_response(ml: MlProgramResponse) -> ProgramResponse {
    ProgramResponse {
        generated_at: Utc::now(),
        source: ProgramSource::Generated,
        // `into_iter` consumes the ML data, so strings are moved, not cloned.
        workouts: ml
            .workouts
            .into_iter()
            .map(|workout| ProgramWorkout {
                name: workout.name,
                exercises: workout
                    .exercises
                    .into_iter()
                    .map(|e| ProgramExercise {
                        exercise_name: e.exercise_name,
                        sets: e.sets,
                        reps: e.reps,
                        weight: e.weight,
                        weight_unit: e.weight_unit,
                    })
                    .collect(),
            })
            .collect(),
    }
}
