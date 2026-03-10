"""
Pose estimation endpoints
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from typing import List, Dict, Any
import numpy as np
from datetime import datetime

from app.services.pose_estimator import PoseEstimator
from app.models.schemas import PoseResponse, KeyPoint

router = APIRouter()
pose_estimator = PoseEstimator()


@router.post("/estimate", response_model=PoseResponse)
async def estimate_pose(file: UploadFile = File(...)):
    """
    Estimate pose from an uploaded image.
    
    Args:
        file: Image file (jpg, png)
    
    Returns:
        PoseResponse with detected keypoints and confidence scores
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Read image data
        image_data = await file.read()
        
        # Perform pose estimation
        result = await pose_estimator.estimate_pose(image_data)
        
        return PoseResponse(
            timestamp=datetime.utcnow().isoformat(),
            keypoints=result["keypoints"],
            confidence=result["confidence"],
            frame_number=0,
            metadata={
                "filename": file.filename,
                "model_version": pose_estimator.model_version,
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Pose estimation failed: {str(e)}")


@router.post("/estimate-video")
async def estimate_pose_video(file: UploadFile = File(...)):
    """
    Estimate pose for all frames in a video.
    
    Args:
        file: Video file (mp4, avi, mov)
    
    Returns:
        List of pose estimations for each frame
    """
    if not file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="File must be a video")
    
    try:
        # Read video data
        video_data = await file.read()
        
        # Process video frames
        results = await pose_estimator.estimate_pose_video(video_data)
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "total_frames": len(results),
            "filename": file.filename,
            "frames": results,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Video pose estimation failed: {str(e)}")


@router.get("/keypoints/names")
async def get_keypoint_names():
    """Get the list of keypoint names used by the model"""
    return {
        "keypoints": pose_estimator.get_keypoint_names(),
        "total": len(pose_estimator.get_keypoint_names()),
    }
