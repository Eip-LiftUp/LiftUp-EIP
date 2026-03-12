"""
Pydantic schemas for API request/response models
"""

from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from enum import Enum


class CommentType(str, Enum):
    """Types of coaching comments"""
    POSITIVE = "positive"
    CORRECTION = "correction"
    ENCOURAGEMENT = "encouragement"
    WARNING = "warning"


class KeyPoint(BaseModel):
    """A single pose keypoint"""
    name: str = Field(..., description="Name of the keypoint (e.g., 'left_shoulder')")
    x: float = Field(..., description="X coordinate (normalized 0-1)")
    y: float = Field(..., description="Y coordinate (normalized 0-1)")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score")
    visible: bool = Field(True, description="Whether keypoint is visible in frame")


class PoseResponse(BaseModel):
    """Response from pose estimation"""
    timestamp: str
    keypoints: List[KeyPoint]
    confidence: float = Field(..., ge=0.0, le=1.0)
    frame_number: int
    metadata: Optional[Dict[str, Any]] = None


class Comment(BaseModel):
    """A coaching comment"""
    id: str
    text: str
    type: CommentType
    timestamp: str
    severity: Optional[int] = Field(None, ge=1, le=5, description="Severity level (1-5)")
    related_keypoints: Optional[List[str]] = Field(None, description="Related body parts")


class FormAnalysisRequest(BaseModel):
    """Request for form analysis"""
    exercise_type: str = Field(..., description="Type of exercise (e.g., 'squat', 'deadlift')")
    keypoints: List[List[KeyPoint]] = Field(..., description="List of keypoints for each frame")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")


class FormAnalysisResponse(BaseModel):
    """Response from form analysis"""
    timestamp: str
    exercise_type: str
    comments: List[Comment]
    overall_score: float = Field(..., ge=0.0, le=100.0)
    metrics: Dict[str, Any] = Field(..., description="Detailed form metrics")


class ExerciseGuidelines(BaseModel):
    """Guidelines for proper exercise form"""
    exercise_type: str
    description: str
    key_points: List[str]
    common_mistakes: List[str]
    safety_tips: List[str]
