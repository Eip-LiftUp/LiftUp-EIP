"""
Configuration settings for the LiftUp ML service
"""

from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings"""
    
    # API Settings
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True
    
    # CORS Settings
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:*",
        "http://127.0.0.1:*",
        "http://10.0.2.2:8000",  # Android emulator
    ]
    
    # ML Model Settings
    POSE_MODEL_PATH: str = "data/models/pose_model.pt"
    I3D_MODEL_PATH: str = "data/models/i3d_model.pt"
    CONFIDENCE_THRESHOLD: float = 0.5
    
    # Processing Settings
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB
    SUPPORTED_VIDEO_FORMATS: List[str] = [".mp4", ".avi", ".mov"]
    SUPPORTED_IMAGE_FORMATS: List[str] = [".jpg", ".jpeg", ".png"]
    
    # Comment Generation Settings
    COMMENT_CATEGORIES: List[str] = ["positive", "correction", "encouragement", "warning"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
