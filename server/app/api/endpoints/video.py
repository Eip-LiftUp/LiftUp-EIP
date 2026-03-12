"""
Video Analysis Endpoints

Handles video uploads and I3D-based movement analysis
"""

from fastapi import APIRouter, HTTPException, UploadFile, File, Form, BackgroundTasks
from fastapi.responses import JSONResponse
from typing import Optional, List
import os
import tempfile
from pathlib import Path
from datetime import datetime

from app.services.i3d_analyzer import get_i3d_analyzer, I3DVideoAnalyzer
from app.core.config import settings


router = APIRouter()

# Supported video formats
SUPPORTED_FORMATS = {".mp4", ".avi", ".mov", ".mkv", ".webm"}
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB


@router.post("/analyze")
async def analyze_video(
    video: UploadFile = File(..., description="Video file to analyze"),
    exercise_type: Optional[str] = Form(None, description="Exercise type (e.g., 'squat', 'deadlift')"),
):
    """
    Analyze a workout video using I3D (Inflated 3D CNN)
    
    This endpoint accepts a video upload and returns:
    - Quality score (0-100)
    - Detected exercise type
    - Form scores for different aspects (depth, alignment, stability, tempo, range_of_motion)
    - Detailed feedback and corrections
    
    **Supported formats:** MP4, AVI, MOV, MKV, WebM
    
    **Max file size:** 100MB
    
    **Example response:**
    ```json
    {
        "analysis_id": "uuid",
        "quality_score": 78.5,
        "detected_exercise": "squat",
        "form_scores": {
            "depth": 85.0,
            "alignment": 72.0,
            "stability": 80.0,
            "tempo": 75.0,
            "range_of_motion": 82.0
        },
        "feedback": [
            {
                "type": "positive",
                "category": "depth",
                "text": "Excellent depth on your movement!"
            }
        ]
    }
    ```
    """
    # Validate file type
    if video.filename:
        file_ext = Path(video.filename).suffix.lower()
        if file_ext not in SUPPORTED_FORMATS:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported video format: {file_ext}. Supported: {', '.join(SUPPORTED_FORMATS)}"
            )
    
    # Read the video file
    try:
        content = await video.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to read video file: {str(e)}")
    
    # Check file size
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024*1024)}MB"
        )
    
    # Analyze the video
    try:
        analyzer = get_i3d_analyzer()
        result = await analyzer.analyze_video_bytes(
            video_bytes=content,
            filename=video.filename or "video.mp4",
            exercise_type=exercise_type
        )
        
        return JSONResponse(content=result)
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@router.post("/analyze-url")
async def analyze_video_from_url(
    video_url: str,
    exercise_type: Optional[str] = None
):
    """
    Analyze a workout video from a URL
    
    Useful when the video is already hosted (e.g., cloud storage).
    
    Args:
        video_url: Direct URL to the video file
        exercise_type: Optional exercise type hint
    """
    import aiohttp
    
    try:
        # Download the video
        async with aiohttp.ClientSession() as session:
            async with session.get(video_url) as response:
                if response.status != 200:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Failed to download video: HTTP {response.status}"
                    )
                
                content = await response.read()
                
                if len(content) > MAX_FILE_SIZE:
                    raise HTTPException(
                        status_code=413,
                        detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024*1024)}MB"
                    )
        
        # Extract filename from URL
        filename = video_url.split("/")[-1].split("?")[0] or "video.mp4"
        
        # Analyze
        analyzer = get_i3d_analyzer()
        result = await analyzer.analyze_video_bytes(
            video_bytes=content,
            filename=filename,
            exercise_type=exercise_type
        )
        
        return JSONResponse(content=result)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@router.get("/supported-exercises")
async def get_supported_exercises():
    """
    Get list of exercises that can be analyzed
    
    Returns the list of exercise types that the I3D model can recognize and analyze.
    """
    return {
        "exercises": I3DVideoAnalyzer.EXERCISE_CLASSES,
        "total": len(I3DVideoAnalyzer.EXERCISE_CLASSES),
        "form_aspects": I3DVideoAnalyzer.FORM_ASPECTS
    }


@router.get("/health")
async def video_analysis_health():
    """
    Health check for the video analysis service
    
    Returns status of the I3D analyzer.
    """
    try:
        analyzer = get_i3d_analyzer()
        return {
            "status": "healthy",
            "device": str(analyzer.device),
            "model_loaded": analyzer.model is not None,
            "num_frames": analyzer.num_frames,
            "frame_size": f"{analyzer.frame_width}x{analyzer.frame_height}",
            "supported_exercises": len(I3DVideoAnalyzer.EXERCISE_CLASSES)
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }
