"""
Tests for video scraper
"""

import pytest
import json
from pathlib import Path
from unittest.mock import Mock, patch, AsyncMock, MagicMock
from datetime import datetime

from app.scraping.video_scraper import VideoScraper, VideoMetadata
from app.scraping.config import ScraperConfig, VideoSourceConfig


class TestVideoMetadata:
    """Tests for VideoMetadata class"""
    
    def test_creation(self):
        """Test VideoMetadata creation"""
        metadata = VideoMetadata(
            video_id="test123",
            title="Test Video",
            source="Test Source",
            url="https://example.com/video",
            duration=120.5,
            resolution=(1280, 720),
            file_path="videos/test123.mp4",
            exercise_type="squat",
        )
        
        assert metadata.video_id == "test123"
        assert metadata.title == "Test Video"
        assert metadata.source == "Test Source"
        assert metadata.duration == 120.5
        assert metadata.resolution == (1280, 720)
        assert metadata.exercise_type == "squat"
    
    def test_to_dict(self):
        """Test conversion to dictionary"""
        metadata = VideoMetadata(
            video_id="test123",
            title="Test Video",
            source="Test Source",
            url="https://example.com/video",
            duration=120.0,
            resolution=(1280, 720),
            file_path="videos/test123.mp4",
        )
        
        data = metadata.to_dict()
        
        assert isinstance(data, dict)
        assert data["video_id"] == "test123"
        assert data["title"] == "Test Video"
        assert data["resolution"] == [1280, 720]
        assert "scraped_at" in data
    
    def test_save_metadata(self, tmp_path):
        """Test saving metadata to file"""
        metadata = VideoMetadata(
            video_id="test123",
            title="Test Video",
            source="Test Source",
            url="https://example.com/video",
            duration=120.0,
            resolution=(1280, 720),
            file_path="videos/test123.mp4",
        )
        
        output_path = tmp_path / "metadata.json"
        metadata.save(output_path)
        
        assert output_path.exists()
        
        # Load and verify
        with open(output_path, 'r') as f:
            loaded = json.load(f)
        
        assert loaded["video_id"] == "test123"
        assert loaded["title"] == "Test Video"
    
    def test_metadata_with_annotations(self):
        """Test metadata with custom annotations"""
        metadata = VideoMetadata(
            video_id="test123",
            title="Test Video",
            source="Test Source",
            url="https://example.com/video",
            duration=120.0,
            resolution=(1280, 720),
            file_path="videos/test123.mp4",
            annotations={"custom_field": "custom_value", "fps": 30.0}
        )
        
        data = metadata.to_dict()
        assert data["annotations"]["custom_field"] == "custom_value"
        assert data["annotations"]["fps"] == 30.0


class TestVideoScraperInitialization:
    """Tests for VideoScraper initialization"""
    
    def test_default_initialization(self, tmp_path):
        """Test scraper initialization with default config"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        assert scraper.config == config
        assert isinstance(scraper.scraped_videos, list)
        assert len(scraper.scraped_videos) == 0
    
    def test_directory_creation(self, tmp_path):
        """Test that scraper creates necessary directories"""
        output_dir = tmp_path / "output"
        config = ScraperConfig(
            output_dir=output_dir,
            metadata_dir=tmp_path / "metadata",
            temp_dir=tmp_path / "temp",
        )
        
        scraper = VideoScraper(config)
        
        # Check directories were created
        assert (output_dir / "videos").exists()
        assert (output_dir / "frames").exists()
        assert (tmp_path / "metadata" / "videos").exists()
        assert (tmp_path / "temp").exists()
    
    def test_ytdl_options_configuration(self, tmp_path):
        """Test YouTube-DL options are configured correctly"""
        config = ScraperConfig(
            output_dir=tmp_path,
            video_quality="1080p",
        )
        scraper = VideoScraper(config)
        
        assert 'format' in scraper.ytdl_opts
        assert 'outtmpl' in scraper.ytdl_opts


class TestVideoIDGeneration:
    """Tests for video ID generation"""
    
    def test_generate_video_id(self, tmp_path):
        """Test video ID generation is consistent"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        url = "https://example.com/video123"
        id1 = scraper._generate_video_id(url)
        id2 = scraper._generate_video_id(url)
        
        # Should be consistent
        assert id1 == id2
        assert len(id1) == 12  # MD5 hash truncated to 12 chars
    
    def test_different_urls_different_ids(self, tmp_path):
        """Test different URLs produce different IDs"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        id1 = scraper._generate_video_id("https://example.com/video1")
        id2 = scraper._generate_video_id("https://example.com/video2")
        
        assert id1 != id2


class TestExerciseDetection:
    """Tests for exercise type detection"""
    
    def test_detect_squat(self, tmp_path):
        """Test squat detection from title"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "Perfect Squat Form Tutorial"
        exercise = scraper._detect_exercise_type(title)
        
        assert exercise == "squat"
    
    def test_detect_deadlift(self, tmp_path):
        """Test deadlift detection"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "How to Deadlift Properly"
        exercise = scraper._detect_exercise_type(title)
        
        assert exercise == "deadlift"
    
    def test_detect_bench_press(self, tmp_path):
        """Test bench press detection"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "Bench press technique guide"
        exercise = scraper._detect_exercise_type(title)
        
        assert exercise == "bench_press"
    
    def test_detect_from_description(self, tmp_path):
        """Test detection from description when not in title"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "Workout Tutorial"
        description = "This video shows proper squat form"
        exercise = scraper._detect_exercise_type(title, description)
        
        assert exercise == "squat"
    
    def test_no_detection(self, tmp_path):
        """Test when no exercise type is detected"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "Random Video Title"
        exercise = scraper._detect_exercise_type(title)
        
        assert exercise is None
    
    def test_case_insensitive(self, tmp_path):
        """Test exercise detection is case insensitive"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "SQUAT FORM TUTORIAL"
        exercise = scraper._detect_exercise_type(title)
        
        assert exercise == "squat"


class TestContentFiltering:
    """Tests for content filtering"""
    
    def test_should_exclude_fail(self, tmp_path):
        """Test exclusion of fail videos"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "Epic Squat Fail Compilation"
        assert scraper._should_exclude(title) is True
    
    def test_should_exclude_injury(self, tmp_path):
        """Test exclusion of injury videos"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "Gym Injury Caught on Camera"
        assert scraper._should_exclude(title) is True
    
    def test_should_not_exclude_good_content(self, tmp_path):
        """Test good content is not excluded"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "Perfect Squat Form Tutorial"
        assert scraper._should_exclude(title) is False
    
    def test_custom_exclude_keywords(self, tmp_path):
        """Test custom exclude keywords"""
        config = ScraperConfig(
            output_dir=tmp_path,
            exclude_keywords=["custom", "bad"]
        )
        scraper = VideoScraper(config)
        
        title = "Custom Bad Video"
        assert scraper._should_exclude(title) is True
    
    def test_exclude_from_description(self, tmp_path):
        """Test exclusion checks description too"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        title = "Workout Video"
        description = "This is a fail compilation"
        assert scraper._should_exclude(title, description) is True


class TestQualityConversion:
    """Tests for quality string to pixel conversion"""
    
    def test_quality_conversion(self, tmp_path):
        """Test video quality string to height conversion"""
        config = ScraperConfig(output_dir=tmp_path, video_quality="720p")
        scraper = VideoScraper(config)
        
        height = scraper._get_height_from_quality()
        assert height == 720
    
    def test_different_qualities(self, tmp_path):
        """Test different quality conversions"""
        qualities = {
            "360p": 360,
            "480p": 480,
            "720p": 720,
            "1080p": 1080,
        }
        
        for quality, expected_height in qualities.items():
            config = ScraperConfig(output_dir=tmp_path, video_quality=quality)
            scraper = VideoScraper(config)
            
            assert scraper._get_height_from_quality() == expected_height
    
    def test_unknown_quality_defaults(self, tmp_path):
        """Test unknown quality defaults to 720p"""
        config = ScraperConfig(output_dir=tmp_path, video_quality="unknown")
        scraper = VideoScraper(config)
        
        height = scraper._get_height_from_quality()
        assert height == 720  # Default


class TestStatistics:
    """Tests for statistics gathering"""
    
    def test_empty_statistics(self, tmp_path):
        """Test statistics with no scraped videos"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        stats = scraper.get_statistics()
        
        assert stats["total_videos"] == 0
        assert stats["total_duration_hours"] == 0
    
    def test_statistics_with_videos(self, tmp_path):
        """Test statistics with scraped videos"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        # Add some mock videos
        scraper.scraped_videos = [
            VideoMetadata(
                video_id="v1",
                title="Video 1",
                source="Source A",
                url="url1",
                duration=120.0,
                resolution=(1280, 720),
                file_path="v1.mp4",
                exercise_type="squat",
            ),
            VideoMetadata(
                video_id="v2",
                title="Video 2",
                source="Source A",
                url="url2",
                duration=180.0,
                resolution=(1280, 720),
                file_path="v2.mp4",
                exercise_type="deadlift",
            ),
            VideoMetadata(
                video_id="v3",
                title="Video 3",
                source="Source B",
                url="url3",
                duration=300.0,
                resolution=(1280, 720),
                file_path="v3.mp4",
                exercise_type="squat",
            ),
        ]
        
        stats = scraper.get_statistics()
        
        assert stats["total_videos"] == 3
        assert stats["total_duration_hours"] == (120 + 180 + 300) / 3600
        assert stats["by_source"]["Source A"] == 2
        assert stats["by_source"]["Source B"] == 1
        assert stats["by_exercise"]["squat"] == 2
        assert stats["by_exercise"]["deadlift"] == 1


class TestScrapingWorkflow:
    """Tests for scraping workflow (with mocks)"""
    
    @pytest.mark.asyncio
    async def test_scrape_disabled_source(self, tmp_path):
        """Test that disabled sources are skipped"""
        source = VideoSourceConfig(
            name="Disabled Source",
            source_type="youtube",
            enabled=False,
            search_queries=["test"],
        )
        
        config = ScraperConfig(output_dir=tmp_path, sources=[source])
        scraper = VideoScraper(config)
        
        results = await scraper.scrape_youtube(source)
        
        # Should return empty list for disabled source
        assert results == []
    
    def test_scraping_summary_save(self, tmp_path):
        """Test saving scraping summary"""
        config = ScraperConfig(
            output_dir=tmp_path,
            metadata_dir=tmp_path / "metadata"
        )
        scraper = VideoScraper(config)
        
        # Add mock videos
        scraped = [
            VideoMetadata(
                video_id="v1",
                title="Video 1",
                source="Test Source",
                url="url1",
                duration=120.0,
                resolution=(1280, 720),
                file_path="v1.mp4",
                exercise_type="squat",
            ),
        ]
        
        scraper._save_scraping_summary(scraped)
        
        # Check summary file was created
        summary_path = config.metadata_dir / "scraping_summary.json"
        assert summary_path.exists()
        
        # Load and verify contents
        with open(summary_path, 'r') as f:
            summary = json.load(f)
        
        assert summary["total_videos"] == 1
        assert "Test Source" in summary["sources"]
        assert "squat" in summary["exercise_types"]


class TestGroupingOperations:
    """Tests for grouping operations"""
    
    def test_group_by_source(self, tmp_path):
        """Test grouping videos by source"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        scraper.scraped_videos = [
            VideoMetadata("v1", "T1", "Source A", "u1", 100, (640, 480), "v1.mp4"),
            VideoMetadata("v2", "T2", "Source A", "u2", 100, (640, 480), "v2.mp4"),
            VideoMetadata("v3", "T3", "Source B", "u3", 100, (640, 480), "v3.mp4"),
        ]
        
        grouped = scraper._group_by("source")
        
        assert grouped["Source A"] == 2
        assert grouped["Source B"] == 1
    
    def test_group_by_exercise(self, tmp_path):
        """Test grouping videos by exercise type"""
        config = ScraperConfig(output_dir=tmp_path)
        scraper = VideoScraper(config)
        
        scraper.scraped_videos = [
            VideoMetadata("v1", "T1", "S", "u1", 100, (640, 480), "v1.mp4", exercise_type="squat"),
            VideoMetadata("v2", "T2", "S", "u2", 100, (640, 480), "v2.mp4", exercise_type="squat"),
            VideoMetadata("v3", "T3", "S", "u3", 100, (640, 480), "v3.mp4", exercise_type="deadlift"),
            VideoMetadata("v4", "T4", "S", "u4", 100, (640, 480), "v4.mp4", exercise_type=None),
        ]
        
        grouped = scraper._group_by("exercise_type")
        
        assert grouped["squat"] == 2
        assert grouped["deadlift"] == 1
        assert grouped["unknown"] == 1  # None becomes 'unknown'


# Integration test
class TestScraperIntegration:
    """Integration tests for complete scraper workflows"""
    
    def test_complete_initialization_workflow(self, tmp_path):
        """Test complete scraper initialization workflow"""
        # Create config with custom settings
        config = ScraperConfig(
            output_dir=tmp_path / "scraped",
            metadata_dir=tmp_path / "metadata",
            temp_dir=tmp_path / "temp",
            video_quality="720p",
            extract_frames=True,
        )
        
        # Add sources
        config.sources = [
            VideoSourceConfig(
                name="Test Source 1",
                source_type="youtube",
                enabled=False,
                search_queries=["squat form"],
                max_videos=10,
            ),
            VideoSourceConfig(
                name="Test Source 2",
                source_type="youtube",
                enabled=False,
                search_queries=["deadlift form"],
                max_videos=10,
            ),
        ]
        
        # Initialize scraper
        scraper = VideoScraper(config)
        
        # Verify setup
        assert scraper.config == config
        assert len(scraper.scraped_videos) == 0
        assert (tmp_path / "scraped" / "videos").exists()
        assert (tmp_path / "scraped" / "frames").exists()
        assert (tmp_path / "metadata" / "videos").exists()
        
        # Verify statistics work
        stats = scraper.get_statistics()
        assert stats["total_videos"] == 0
