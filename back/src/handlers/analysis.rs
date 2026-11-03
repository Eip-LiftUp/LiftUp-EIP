//! AI Analysis Proxy Handler
//!
//! Proxies video analysis requests to the Python AI service.
//! This allows the Flutter app to use the Rust backend as a single entry point.

use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::Json,
};
use axum_extra::extract::Multipart;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use crate::AppState;

/// Query parameters for video analysis
#[derive(Debug, Deserialize)]
pub struct AnalyzeQuery {
    pub exercise_type: Option<String>,
}

/// Response from the AI service
#[derive(Debug, Serialize, Deserialize)]
pub struct AnalysisResponse {
    pub analysis_id: String,
    pub timestamp: String,
    pub quality_score: f64,
    pub detected_exercise: String,
    pub detection_confidence: f64,
    pub form_scores: FormScores,
    pub feedback: Vec<FeedbackComment>,
    pub metrics: AnalysisMetrics,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FormScores {
    pub depth: f64,
    pub alignment: f64,
    pub stability: f64,
    pub tempo: f64,
    pub range_of_motion: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FeedbackComment {
    pub id: String,
    #[serde(rename = "type")]
    pub comment_type: String,
    pub category: String,
    pub text: String,
    pub score: f64,
    pub severity: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AnalysisMetrics {
    pub video_fps: f64,
    pub total_frames: i32,
    pub frames_analyzed: i32,
    pub processing_time_seconds: f64,
    pub model_device: String,
}

/// Supported exercises response
#[derive(Debug, Serialize, Deserialize)]
pub struct SupportedExercisesResponse {
    pub exercises: Vec<String>,
    pub total: i32,
    pub form_aspects: Vec<String>,
}

/// Error response
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub error: String,
    pub detail: Option<String>,
}

/// Proxy video analysis to the Python AI service
///
/// POST /ai/analyze
///
/// Accepts multipart form data with:
/// - video: The video file to analyze
/// - exercise_type (optional): Expected exercise type
pub async fn analyze_video(
    State(state): State<AppState>,
    Query(query): Query<AnalyzeQuery>,
    mut multipart: Multipart,
) -> Result<Json<AnalysisResponse>, (StatusCode, Json<ErrorResponse>)> {
    // Build multipart form for the AI service
    let mut form = reqwest::multipart::Form::new();

    // Process incoming multipart data
    loop {
        let field_result = multipart.next_field().await;
        
        let field = match field_result {
            Ok(Some(f)) => f,
            Ok(None) => break,
            Err(e) => {
                return Err((
                    StatusCode::BAD_REQUEST,
                    Json(ErrorResponse {
                        error: "Failed to read multipart".to_string(),
                        detail: Some(e.to_string()),
                    }),
                ));
            }
        };
        
        let name = field.name().unwrap_or("").to_string();
        
        if name == "video" {
            let filename = field.file_name().unwrap_or("video.mp4").to_string();
            let content_type = field.content_type().unwrap_or("video/mp4").to_string();
            
            let data = match field.bytes().await {
                Ok(bytes) => bytes,
                Err(e) => {
                    return Err((
                        StatusCode::BAD_REQUEST,
                        Json(ErrorResponse {
                            error: "Failed to read video data".to_string(),
                            detail: Some(e.to_string()),
                        }),
                    ));
                }
            };

            let part = reqwest::multipart::Part::bytes(data.to_vec())
                .file_name(filename)
                .mime_str(&content_type)
                .map_err(|e| {
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(ErrorResponse {
                            error: "Failed to create multipart part".to_string(),
                            detail: Some(e.to_string()),
                        }),
                    )
                })?;

            form = form.part("video", part);
        }
    }

    // Add exercise type if provided
    if let Some(exercise_type) = query.exercise_type {
        form = form.text("exercise_type", exercise_type);
    }

    // Send request to AI service
    let response = state
        .analysis_client
        .post(format!("{}/api/v1/video/analyze", state.ai_service_url))
        .multipart(form)
        .send()
        .await
        .map_err(|e| {
            tracing::error!("Failed to connect to AI service: {}", e);
            (
                StatusCode::SERVICE_UNAVAILABLE,
                Json(ErrorResponse {
                    error: "AI service unavailable".to_string(),
                    detail: Some(format!("Could not connect to AI service: {}", e)),
                }),
            )
        })?;

    if response.status().is_success() {
        let analysis: AnalysisResponse = response.json().await.map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "Failed to parse AI response".to_string(),
                    detail: Some(e.to_string()),
                }),
            )
        })?;
        Ok(Json(analysis))
    } else {
        let status = response.status();
        let error_text = response.text().await.unwrap_or_default();
        Err((
            StatusCode::from_u16(status.as_u16()).unwrap_or(StatusCode::INTERNAL_SERVER_ERROR),
            Json(ErrorResponse {
                error: "AI analysis failed".to_string(),
                detail: Some(error_text),
            }),
        ))
    }
}

/// Get supported exercises from the AI service
///
/// GET /ai/exercises
pub async fn get_supported_exercises(
    State(state): State<AppState>,
) -> Result<Json<SupportedExercisesResponse>, (StatusCode, Json<ErrorResponse>)> {
    let response = state
        .analysis_client
        .get(format!("{}/api/v1/video/supported-exercises", state.ai_service_url))
        .send()
        .await
        .map_err(|e| {
            (
                StatusCode::SERVICE_UNAVAILABLE,
                Json(ErrorResponse {
                    error: "AI service unavailable".to_string(),
                    detail: Some(e.to_string()),
                }),
            )
        })?;

    if response.status().is_success() {
        let exercises: SupportedExercisesResponse = response.json().await.map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "Failed to parse response".to_string(),
                    detail: Some(e.to_string()),
                }),
            )
        })?;
        Ok(Json(exercises))
    } else {
        Err((
            StatusCode::SERVICE_UNAVAILABLE,
            Json(ErrorResponse {
                error: "Failed to get exercises".to_string(),
                detail: None,
            }),
        ))
    }
}

/// Health check for the AI service
///
/// GET /ai/health
pub async fn ai_health_check(
    State(state): State<AppState>,
) -> Json<HashMap<String, serde_json::Value>> {
    // The shared client has the long analysis timeout; this call keeps its own short one.
    match state
        .analysis_client
        .get(format!("{}/api/v1/video/health", state.ai_service_url))
        .timeout(std::time::Duration::from_secs(5))
        .send()
        .await
    {
        Ok(response) if response.status().is_success() => {
            match response.json::<HashMap<String, serde_json::Value>>().await {
                Ok(health) => Json(health),
                Err(_) => Json(HashMap::from([
                    ("status".to_string(), serde_json::json!("unknown")),
                    ("ai_service".to_string(), serde_json::json!("connected")),
                ])),
            }
        }
        Ok(response) => Json(HashMap::from([
            ("status".to_string(), serde_json::json!("unhealthy")),
            (
                "ai_service".to_string(),
                serde_json::json!(format!("error: {}", response.status())),
            ),
        ])),
        Err(e) => Json(HashMap::from([
            ("status".to_string(), serde_json::json!("unhealthy")),
            (
                "ai_service".to_string(),
                serde_json::json!(format!("disconnected: {}", e)),
            ),
        ])),
    }
}
