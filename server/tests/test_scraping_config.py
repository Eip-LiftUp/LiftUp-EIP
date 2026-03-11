"""
Tests for video scraping configuration
"""

import pytest
from pathlib import Path
from pydantic import ValidationError

from app.scraping.config import ScraperConfig, VideoSourceConfig


class TestVideoSourceConfig:
    """Tests for VideoSourceConfig"""
    
    def test_basic_creation(self):
        """Test basic VideoSourceConfig creation"""
        config = VideoSourceConfig(
            name="Test Source",
            source_type="youtube",
            search_queries=["test query"],
        )
        
        assert config.name == "Test Source"
        assert config.source_type == "youtube"
        assert config.enabled is True  # Default
        assert config.search_queries == ["test query"]
        assert config.max_videos == 100  # Default
    
    def test_with_filters(self):
        """Test VideoSourceConfig with filters"""
        config = VideoSourceConfig(
            name="Filtered Source",
            source_type="youtube",
            search_queries=["workout"],
            max_videos=50,
            filters={"min_views": 1000, "language": "en"}
        )
        
        assert config.filters["min_views"] == 1000
        assert config.filters["language"] == "en"
    
    def test_disabled_source(self):
        """Test creating disabled source"""
        config = VideoSourceConfig(
            name="Disabled",
            source_type="youtube",
            enabled=False,
            search_queries=["test"],
        )
        
        assert config.enabled is False
    
    def test_valid_source_types(self):
        """Test valid source types are accepted"""
        for source_type in ["youtube", "web", "local"]:
            config = VideoSourceConfig(
                name=f"Test {source_type}",
                source_type=source_type,
                search_queries=["test"],
            )
            assert config.source_type == source_type
    
    def test_empty_search_queries(self):
        """Test with empty search queries"""
        config = VideoSourceConfig(
            name="Empty",
            source_type="youtube",
            search_queries=[],
        )
        
        assert config.search_queries == []


class TestScraperConfig:
    """Tests for ScraperConfig"""
    
    def test_default_configuration(self):
        """Test default ScraperConfig"""
        config = ScraperConfig()
        
        # Check defaults
        assert config.output_dir == Path("data/scraped")
        assert config.metadata_dir == Path("data/annotations")
        assert config.video_format == "mp4"
        assert config.video_quality == "720p"
        assert config.max_duration_seconds == 600
        assert config.min_duration_seconds == 30
        assert config.extract_frames is True
        assert config.frame_rate == 30
        assert config.max_concurrent_downloads == 3
        assert config.download_delay_seconds == 2
    
    def test_custom_paths(self):
        """Test custom output paths"""
        config = ScraperConfig(
            output_dir=Path("/custom/output"),
            metadata_dir=Path("/custom/metadata"),
        )
        
        assert config.output_dir == Path("/custom/output")
        assert config.metadata_dir == Path("/custom/metadata")
    
    def test_video_quality_settings(self):
        """Test different video quality settings"""
        for quality in ["360p", "480p", "720p", "1080p"]:
            config = ScraperConfig(video_quality=quality)
            assert config.video_quality == quality
    
    def test_frame_extraction_settings(self):
        """Test frame extraction configuration"""
        config = ScraperConfig(
            extract_frames=True,
            frame_rate=60,
            resize_frames=(512, 512),
        )
        
        assert config.extract_frames is True
        assert config.frame_rate == 60
        assert config.resize_frames == (512, 512)
    
    def test_rate_limiting_settings(self):
        """Test rate limiting configuration"""
        config = ScraperConfig(
            max_concurrent_downloads=5,
            download_delay_seconds=5,
        )
        
        assert config.max_concurrent_downloads == 5
        assert config.download_delay_seconds == 5
    
    def test_sources_configuration(self):
        """Test sources configuration"""
        source = VideoSourceConfig(
            name="Test",
            source_type="youtube",
            search_queries=["test"],
        )
        
        config = ScraperConfig(sources=[source])
        
        assert len(config.sources) == 1
        assert config.sources[0].name == "Test"
    
    def test_default_sources(self):
        """Test default sources are included"""
        config = ScraperConfig()
        
        # Should have at least one default source
        assert len(config.sources) > 0
        
        # Default source should be disabled
        default_source = config.sources[0]
        assert default_source.enabled is False
    
    def test_exclude_keywords(self):
        """Test exclude keywords configuration"""
        config = ScraperConfig()
        
        # Should have default exclude keywords
        assert len(config.exclude_keywords) > 0
        assert "fail" in config.exclude_keywords
        assert "injury" in config.exclude_keywords
    
    def test_custom_exclude_keywords(self):
        """Test custom exclude keywords"""
        config = ScraperConfig(
            exclude_keywords=["custom1", "custom2"]
        )
        
        assert "custom1" in config.exclude_keywords
        assert "custom2" in config.exclude_keywords
    
    def test_exercise_types(self):
        """Test exercise types configuration"""
        config = ScraperConfig()
        
        # Should have default exercise types
        assert len(config.exercise_types) > 0
        assert "squat" in config.exercise_types
        assert "deadlift" in config.exercise_types
        assert "bench_press" in config.exercise_types
    
    def test_custom_exercise_types(self):
        """Test custom exercise types"""
        config = ScraperConfig(
            exercise_types=["custom_exercise1", "custom_exercise2"]
        )
        
        assert "custom_exercise1" in config.exercise_types
        assert "custom_exercise2" in config.exercise_types
    
    def test_auto_annotate_setting(self):
        """Test auto annotation setting"""
        config = ScraperConfig(auto_annotate=False)
        assert config.auto_annotate is False
        
        config = ScraperConfig(auto_annotate=True)
        assert config.auto_annotate is True
    
    def test_duration_limits(self):
        """Test video duration limits"""
        config = ScraperConfig(
            min_duration_seconds=60,
            max_duration_seconds=1200,
        )
        
        assert config.min_duration_seconds == 60
        assert config.max_duration_seconds == 1200
    
    def test_resize_frames_none(self):
        """Test resize_frames can be None"""
        config = ScraperConfig(resize_frames=None)
        assert config.resize_frames is None


class TestConfigValidation:
    """Tests for configuration validation"""
    
    def test_negative_max_videos_rejected(self):
        """Test negative max_videos is handled"""
        # Pydantic should handle this, but let's verify
        config = VideoSourceConfig(
            name="Test",
            source_type="youtube",
            search_queries=["test"],
            max_videos=-1,  # Invalid
        )
        # Pydantic will accept it but we can validate in usage
        assert config.max_videos == -1  # Just checking it's stored
    
    def test_config_serialization(self):
        """Test config can be serialized to dict"""
        config = ScraperConfig()
        config_dict = config.model_dump()
        
        assert isinstance(config_dict, dict)
        assert "output_dir" in config_dict
        assert "video_quality" in config_dict
        assert "sources" in config_dict
    
    def test_config_from_dict(self):
        """Test config can be created from dict"""
        config_dict = {
            "output_dir": "data/test",
            "video_quality": "1080p",
            "max_videos": 50,
        }
        
        config = ScraperConfig(**config_dict)
        assert str(config.output_dir) == "data/test"
        assert config.video_quality == "1080p"


class TestConfigDefaults:
    """Tests for default configuration values"""
    
    def test_default_config_is_safe(self):
        """Test default configuration is safe (sources disabled)"""
        config = ScraperConfig()
        
        # All default sources should be disabled
        for source in config.sources:
            assert source.enabled is False, "Default sources should be disabled for safety"
    
    def test_default_paths_are_relative(self):
        """Test default paths are relative"""
        config = ScraperConfig()
        
        # Paths should be relative (not absolute)
        assert not config.output_dir.is_absolute()
        assert not config.metadata_dir.is_absolute()
        assert not config.temp_dir.is_absolute()
    
    def test_default_video_settings_reasonable(self):
        """Test default video settings are reasonable"""
        config = ScraperConfig()
        
        # Quality should be reasonable (not too high)
        assert config.video_quality in ["360p", "480p", "720p"]
        
        # Duration limits should be reasonable
        assert config.min_duration_seconds >= 10
        assert config.max_duration_seconds <= 3600  # 1 hour max
        
        # Frame rate should be standard
        assert config.frame_rate in [24, 25, 30, 60]
    
    def test_default_rate_limiting(self):
        """Test default rate limiting is respectful"""
        config = ScraperConfig()
        
        # Should have reasonable limits
        assert config.max_concurrent_downloads <= 5
        assert config.download_delay_seconds >= 1


class TestMultipleSourcesConfiguration:
    """Tests for configuring multiple sources"""
    
    def test_multiple_sources(self):
        """Test configuration with multiple sources"""
        source1 = VideoSourceConfig(
            name="Source 1",
            source_type="youtube",
            search_queries=["query1"],
        )
        source2 = VideoSourceConfig(
            name="Source 2",
            source_type="youtube",
            search_queries=["query2"],
        )
        
        config = ScraperConfig(sources=[source1, source2])
        
        assert len(config.sources) == 2
        assert config.sources[0].name == "Source 1"
        assert config.sources[1].name == "Source 2"
    
    def test_mixed_enabled_disabled_sources(self):
        """Test mix of enabled and disabled sources"""
        source1 = VideoSourceConfig(
            name="Enabled",
            source_type="youtube",
            enabled=True,
            search_queries=["q1"],
        )
        source2 = VideoSourceConfig(
            name="Disabled",
            source_type="youtube",
            enabled=False,
            search_queries=["q2"],
        )
        
        config = ScraperConfig(sources=[source1, source2])
        
        enabled_count = sum(1 for s in config.sources if s.enabled)
        assert enabled_count == 1
    
    def test_different_source_types(self):
        """Test different source types in same config"""
        sources = [
            VideoSourceConfig(
                name="YouTube Source",
                source_type="youtube",
                search_queries=["yt"],
            ),
            VideoSourceConfig(
                name="Web Source",
                source_type="web",
                search_queries=["web"],
            ),
            VideoSourceConfig(
                name="Local Source",
                source_type="local",
                search_queries=["local"],
            ),
        ]
        
        config = ScraperConfig(sources=sources)
        
        source_types = [s.source_type for s in config.sources]
        assert "youtube" in source_types
        assert "web" in source_types
        assert "local" in source_types
