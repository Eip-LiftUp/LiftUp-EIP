"""
Form analysis endpoints
"""

from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from datetime import datetime

from app.models.schemas import (
    FormAnalysisRequest,
    FormAnalysisResponse,
    Comment,
    CommentType
)
from app.services.form_analyzer import FormAnalyzer

router = APIRouter()
form_analyzer = FormAnalyzer()


@router.post("/analyze-form", response_model=FormAnalysisResponse)
async def analyze_form(request: FormAnalysisRequest):
    """
    Analyze workout form from pose keypoints.
    
    Args:
        request: FormAnalysisRequest with exercise type and keypoint data
    
    Returns:
        FormAnalysisResponse with comments and suggestions
    """
    try:
        # Perform form analysis
        result = await form_analyzer.analyze_form(
            exercise_type=request.exercise_type,
            keypoints=request.keypoints,
            metadata=request.metadata
        )
        
        return FormAnalysisResponse(
            timestamp=datetime.utcnow().isoformat(),
            exercise_type=request.exercise_type,
            comments=result["comments"],
            overall_score=result["overall_score"],
            metrics=result["metrics"],
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Form analysis failed: {str(e)}")


@router.post("/real-time-feedback")
async def real_time_feedback(request: FormAnalysisRequest):
    """
    Provide real-time feedback for a single frame.
    
    This endpoint is optimized for low-latency responses during live sessions.
    """
    try:
        feedback = await form_analyzer.real_time_feedback(
            exercise_type=request.exercise_type,
            keypoints=request.keypoints
        )
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "feedback": feedback,
            "latency_ms": feedback.get("latency_ms", 0),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Real-time feedback failed: {str(e)}")


@router.get("/exercises")
async def get_supported_exercises():
    """Get list of supported exercises"""
    return {
        "exercises": form_analyzer.get_supported_exercises(),
        "total": len(form_analyzer.get_supported_exercises()),
    }


@router.get("/exercises/{exercise_type}/guidelines")
async def get_exercise_guidelines(exercise_type: str):
    """Get form guidelines for a specific exercise"""
    try:
        guidelines = await form_analyzer.get_exercise_guidelines(exercise_type)
        return {
            "exercise_type": exercise_type,
            "guidelines": guidelines,
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
