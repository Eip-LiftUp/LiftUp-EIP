"""Scraper Configuration

Configuration for video scraping operations.
"""

from typing import List, Dict, Optional, Any
from pydantic import BaseModel, Field, field_validator, ConfigDict
from pathlib import Path


class VideoSourceConfig(BaseModel):
    """Configuration for a video source"""
    name: str = Field(..., description="Name of the video source")
    source_type: str = Field(..., description="Type: 'youtube', 'web', 'local'")
    enabled: bool = Field(default=True, description="Whether this source is active")
    search_queries: List[str] = Field(default_factory=list, description="Search queries for this source")
    max_videos: int = Field(default=100, description="Maximum videos to scrape from this source")
    filters: Dict[str, Any] = Field(default_factory=dict, description="Additional filters (duration, quality, etc.)")


class ScraperConfig(BaseModel):
    """Main scraper configuration"""
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "output_dir": "data/scraped",
                "video_quality": "720p",
                "max_concurrent_downloads": 3,
            }
        }
    )
    
    # Output directories
    output_dir: Path = Field(default_factory=lambda: Path("data/scraped"), description="Where to store scraped videos")
    metadata_dir: Path = Field(default_factory=lambda: Path("data/annotations"), description="Where to store video metadata")
    temp_dir: Path = Field(default_factory=lambda: Path("data/temp"), description="Temporary directory for processing")
    
    # Video quality settings
    video_format: str = Field(default="mp4", description="Preferred video format")
    video_quality: str = Field(default="720p", description="Preferred video quality (360p, 480p, 720p, 1080p)")
    max_duration_seconds: int = Field(default=600, description="Maximum video duration (10 minutes)")
    min_duration_seconds: int = Field(default=30, description="Minimum video duration")
    
    # Processing settings
    extract_frames: bool = Field(default=True, description="Extract frames for training")
    frame_rate: int = Field(default=30, description="Frame rate for extraction")
    resize_frames: Optional[tuple] = Field(default=(256, 256), description="Resize frames to (width, height)")
    
    # Rate limiting
    max_concurrent_downloads: int = Field(default=3, description="Max simultaneous downloads")
    download_delay_seconds: int = Field(default=2, description="Delay between downloads")
    
    # Video sources
    sources: List[VideoSourceConfig] = Field(
        default_factory=lambda: [
            VideoSourceConfig(
                name="Workout YouTube",
                source_type="youtube",
                enabled=False,  # Disabled by default - user activates when ready
                search_queries=[
                    "squat form tutorial",
                    "deadlift technique",
                    "bench press form",
                    "proper squat technique",
                    "workout form check",
                    "olympic lifting form",
                ],
                max_videos=50,
                filters={
                    "min_views": 1000,
                    "language": "en",
                }
            ),
        ],
        description="List of video sources to scrape from"
    )
    
    # Content filtering
    exclude_keywords: List[str] = Field(
        default_factory=lambda: ["fail", "injury", "blooper", "worst"],
        description="Keywords to exclude from search results"
    )
    
    # Annotation settings
    auto_annotate: bool = Field(default=True, description="Automatically annotate exercise type from title/description")
    exercise_types: List[str] = Field(
        default_factory=lambda: ["squat", "deadlift", "bench_press", "overhead_press", "pullup", "row", "lunge", "plank"],
        description="Exercise types to categorize"
    )
    
    @field_validator('output_dir', 'metadata_dir', 'temp_dir', mode='before')
    @classmethod
    def convert_to_path(cls, v):
        """Convert string paths to Path objects"""
        if isinstance(v, str):
            return Path(v)
        return v


# Default configuration instance
DEFAULT_SCRAPER_CONFIG = ScraperConfig()
