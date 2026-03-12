"""Video Scraper

Main video scraping service that collects training data from various sources.
"""

import asyncio
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Any
import hashlib

import yt_dlp
import cv2
import numpy as np
from PIL import Image

from app.scraping.config import ScraperConfig, VideoSourceConfig

logger = logging.getLogger(__name__)


class VideoMetadata:
    """Stores metadata about a scraped video"""
    
    def __init__(
        self,
        video_id: str,
        title: str,
        source: str,
        url: str,
        duration: float,
        resolution: tuple,
        file_path: str,
        exercise_type: Optional[str] = None,
        annotations: Optional[Dict[str, Any]] = None,
    ):
        self.video_id = video_id
        self.title = title
        self.source = source
        self.url = url
        self.duration = duration
        self.resolution = resolution
        self.file_path = file_path
        self.exercise_type = exercise_type
        self.annotations = annotations or {}
        self.scraped_at = datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        return {
            "video_id": self.video_id,
            "title": self.title,
            "source": self.source,
            "url": self.url,
            "duration": self.duration,
            "resolution": list(self.resolution) if self.resolution else None,
            "file_path": self.file_path,
            "exercise_type": self.exercise_type,
            "annotations": self.annotations,
            "scraped_at": self.scraped_at,
        }
    
    def save(self, output_path: Path):
        """Save metadata to JSON file"""
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w') as f:
            json.dump(self.to_dict(), f, indent=2)


class VideoScraper:
    """Main video scraping service"""
    
    def __init__(self, config: Optional[ScraperConfig] = None):
        self.config = config or ScraperConfig()
        self._setup_directories()
        self.scraped_videos: List[VideoMetadata] = []
        
        # YouTube-DL configuration
        self.ytdl_opts = {
            'format': f'bestvideo[height<={self._get_height_from_quality()}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
            'outtmpl': str(self.config.output_dir / '%(id)s.%(ext)s'),
            'quiet': False,
            'no_warnings': False,
            'extract_flat': False,
            'socket_timeout': 30,
        }
    
    def _setup_directories(self):
        """Create necessary directories"""
        self.config.output_dir.mkdir(parents=True, exist_ok=True)
        self.config.metadata_dir.mkdir(parents=True, exist_ok=True)
        self.config.temp_dir.mkdir(parents=True, exist_ok=True)
        
        # Create subdirectories for organized storage
        (self.config.output_dir / "videos").mkdir(exist_ok=True)
        (self.config.output_dir / "frames").mkdir(exist_ok=True)
        (self.config.metadata_dir / "videos").mkdir(exist_ok=True)
    
    def _get_height_from_quality(self) -> int:
        """Convert quality string to pixel height"""
        quality_map = {
            '360p': 360,
            '480p': 480,
            '720p': 720,
            '1080p': 1080,
        }
        return quality_map.get(self.config.video_quality, 720)
    
    def _generate_video_id(self, url: str) -> str:
        """Generate a unique ID for a video"""
        return hashlib.md5(url.encode()).hexdigest()[:12]
    
    def _detect_exercise_type(self, title: str, description: str = "") -> Optional[str]:
        """Auto-detect exercise type from video title/description"""
        text = (title + " " + description).lower()
        
        for exercise in self.config.exercise_types:
            # Handle multi-word exercises
            search_term = exercise.replace("_", " ")
            if search_term in text:
                return exercise
        
        return None
    
    def _should_exclude(self, title: str, description: str = "") -> bool:
        """Check if video should be excluded based on keywords"""
        text = (title + " " + description).lower()
        return any(keyword.lower() in text for keyword in self.config.exclude_keywords)
    
    async def scrape_youtube(self, source_config: VideoSourceConfig) -> List[VideoMetadata]:
        """
        Scrape videos from YouTube based on source configuration.
        
        Args:
            source_config: Configuration for this YouTube source
            
        Returns:
            List of metadata for successfully scraped videos
        """
        if not source_config.enabled:
            logger.info(f"Source '{source_config.name}' is disabled, skipping")
            return []
        
        logger.info(f"Starting YouTube scraping for source: {source_config.name}")
        scraped = []
        
        for query in source_config.search_queries:
            try:
                logger.info(f"Searching YouTube for: {query}")
                
                # Search for videos
                search_opts = {
                    **self.ytdl_opts,
                    'default_search': 'ytsearch' + str(source_config.max_videos // len(source_config.search_queries)),
                }
                
                with yt_dlp.YoutubeDL(search_opts) as ydl:
                    # Extract info without downloading first
                    result = ydl.extract_info(f"ytsearch{source_config.max_videos // len(source_config.search_queries)}:{query}", download=False)
                    
                    if 'entries' not in result:
                        continue
                    
                    for video_info in result['entries']:
                        if len(scraped) >= source_config.max_videos:
                            break
                        
                        # Filter by duration
                        duration = video_info.get('duration', 0)
                        if duration < self.config.min_duration_seconds or duration > self.config.max_duration_seconds:
                            logger.debug(f"Skipping video {video_info.get('id')} - duration {duration}s out of range")
                            continue
                        
                        # Check exclusion keywords
                        title = video_info.get('title', '')
                        description = video_info.get('description', '')
                        if self._should_exclude(title, description):
                            logger.debug(f"Skipping video {video_info.get('id')} - matches exclusion keywords")
                            continue
                        
                        # Apply source-specific filters
                        if 'min_views' in source_config.filters:
                            if video_info.get('view_count', 0) < source_config.filters['min_views']:
                                continue
                        
                        # Download the video
                        video_metadata = await self._download_video(video_info, source_config.name)
                        if video_metadata:
                            scraped.append(video_metadata)
                        
                        # Rate limiting
                        await asyncio.sleep(self.config.download_delay_seconds)
            
            except Exception as e:
                logger.error(f"Error scraping query '{query}': {str(e)}")
                continue
        
        logger.info(f"Completed scraping {len(scraped)} videos from source: {source_config.name}")
        return scraped
    
    async def _download_video(self, video_info: Dict[str, Any], source_name: str) -> Optional[VideoMetadata]:
        """
        Download a single video and extract frames if configured.
        
        Args:
            video_info: Video information from yt-dlp
            source_name: Name of the source this video came from
            
        Returns:
            VideoMetadata object or None if download failed
        """
        try:
            video_id = video_info.get('id', self._generate_video_id(video_info.get('webpage_url', '')))
            url = video_info.get('webpage_url', '')
            title = video_info.get('title', 'Unknown')
            
            logger.info(f"Downloading video: {title} ({video_id})")
            
            # Download with yt-dlp
            download_opts = {
                **self.ytdl_opts,
                'outtmpl': str(self.config.output_dir / 'videos' / f'{video_id}.%(ext)s'),
            }
            
            with yt_dlp.YoutubeDL(download_opts) as ydl:
                ydl.download([url])
            
            # Find the downloaded file
            video_path = None
            for ext in ['mp4', 'webm', 'mkv']:
                potential_path = self.config.output_dir / 'videos' / f'{video_id}.{ext}'
                if potential_path.exists():
                    video_path = potential_path
                    break
            
            if not video_path:
                logger.error(f"Downloaded video not found for {video_id}")
                return None
            
            # Extract video information
            cap = cv2.VideoCapture(str(video_path))
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            fps = cap.get(cv2.CAP_PROP_FPS)
            frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            duration = frame_count / fps if fps > 0 else video_info.get('duration', 0)
            cap.release()
            
            # Detect exercise type
            exercise_type = None
            if self.config.auto_annotate:
                exercise_type = self._detect_exercise_type(
                    title,
                    video_info.get('description', '')
                )
            
            # Create metadata
            metadata = VideoMetadata(
                video_id=video_id,
                title=title,
                source=source_name,
                url=url,
                duration=duration,
                resolution=(width, height),
                file_path=str(video_path.relative_to(self.config.output_dir)),
                exercise_type=exercise_type,
                annotations={
                    'fps': fps,
                    'frame_count': frame_count,
                    'uploader': video_info.get('uploader', ''),
                    'view_count': video_info.get('view_count', 0),
                    'description': video_info.get('description', '')[:500],  # First 500 chars
                }
            )
            
            # Save metadata
            metadata_path = self.config.metadata_dir / 'videos' / f'{video_id}.json'
            metadata.save(metadata_path)
            
            # Extract frames if configured
            if self.config.extract_frames:
                await self._extract_frames(video_path, video_id)
            
            self.scraped_videos.append(metadata)
            return metadata
        
        except Exception as e:
            logger.error(f"Error downloading video {video_info.get('id', 'unknown')}: {str(e)}")
            return None
    
    async def _extract_frames(self, video_path: Path, video_id: str):
        """
        Extract frames from video for training.
        
        Args:
            video_path: Path to the video file
            video_id: Unique ID for the video
        """
        try:
            frames_dir = self.config.output_dir / 'frames' / video_id
            frames_dir.mkdir(parents=True, exist_ok=True)
            
            cap = cv2.VideoCapture(str(video_path))
            fps = cap.get(cv2.CAP_PROP_FPS)
            
            # Calculate frame interval to match target frame rate
            frame_interval = max(1, int(fps / self.config.frame_rate))
            
            frame_idx = 0
            saved_frames = 0
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                
                # Save frame at intervals
                if frame_idx % frame_interval == 0:
                    # Resize if configured
                    if self.config.resize_frames:
                        frame = cv2.resize(frame, self.config.resize_frames)
                    
                    # Save frame
                    frame_path = frames_dir / f'frame_{saved_frames:06d}.jpg'
                    cv2.imwrite(str(frame_path), frame)
                    saved_frames += 1
                
                frame_idx += 1
            
            cap.release()
            logger.info(f"Extracted {saved_frames} frames from video {video_id}")
        
        except Exception as e:
            logger.error(f"Error extracting frames from {video_id}: {str(e)}")
    
    async def scrape_all_sources(self) -> List[VideoMetadata]:
        """
        Scrape videos from all configured sources.
        
        Returns:
            List of all scraped video metadata
        """
        all_scraped = []
        
        for source in self.config.sources:
            if source.source_type == 'youtube':
                scraped = await self.scrape_youtube(source)
                all_scraped.extend(scraped)
            elif source.source_type == 'web':
                # TODO: Implement web scraping
                logger.warning("Web scraping not yet implemented")
            elif source.source_type == 'local':
                # TODO: Implement local file processing
                logger.warning("Local file processing not yet implemented")
            else:
                logger.warning(f"Unknown source type: {source.source_type}")
        
        # Save summary
        self._save_scraping_summary(all_scraped)
        
        return all_scraped
    
    def _save_scraping_summary(self, scraped: List[VideoMetadata]):
        """Save a summary of the scraping session"""
        summary = {
            'total_videos': len(scraped),
            'sources': {},
            'exercise_types': {},
            'total_duration_seconds': sum(v.duration for v in scraped),
            'scraped_at': datetime.utcnow().isoformat(),
        }
        
        # Group by source and exercise type
        for video in scraped:
            # By source
            if video.source not in summary['sources']:
                summary['sources'][video.source] = 0
            summary['sources'][video.source] += 1
            
            # By exercise type
            if video.exercise_type:
                if video.exercise_type not in summary['exercise_types']:
                    summary['exercise_types'][video.exercise_type] = 0
                summary['exercise_types'][video.exercise_type] += 1
        
        # Save summary
        summary_path = self.config.metadata_dir / 'scraping_summary.json'
        with open(summary_path, 'w') as f:
            json.dump(summary, f, indent=2)
        
        logger.info(f"Scraping summary saved to {summary_path}")
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get statistics about scraped videos"""
        return {
            'total_videos': len(self.scraped_videos),
            'by_source': self._group_by('source'),
            'by_exercise': self._group_by('exercise_type'),
            'total_duration_hours': sum(v.duration for v in self.scraped_videos) / 3600,
        }
    
    def _group_by(self, attribute: str) -> Dict[str, int]:
        """Group videos by an attribute"""
        groups = {}
        for video in self.scraped_videos:
            value = getattr(video, attribute, None) or 'unknown'
            groups[value] = groups.get(value, 0) + 1
        return groups


# Example usage (for testing/development)
if __name__ == "__main__":
    # This is an example - DO NOT RUN without explicit user permission
    # Configure logging
    logging.basicConfig(level=logging.INFO)
    
    # Create a test configuration (all sources disabled by default)
    config = ScraperConfig()
    
    # Create scraper
    scraper = VideoScraper(config)
    
    print("Video scraper initialized")
    print(f"Output directory: {config.output_dir}")
    print(f"Metadata directory: {config.metadata_dir}")
    print("\nTo use the scraper:")
    print("1. Enable sources in the configuration")
    print("2. Run: await scraper.scrape_all_sources()")
    print("\nNote: Scraping is currently DISABLED by default")
