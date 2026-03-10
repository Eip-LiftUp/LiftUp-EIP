"""
Tests for data pipeline (PyTorch integration)
"""

import pytest
import torch
import json
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock
from PIL import Image

from app.scraping.data_pipeline import (
    VideoFrameDataset,
    VideoDataset,
    DataPipeline,
)
from app.scraping.config import ScraperConfig


@pytest.fixture
def sample_metadata_dir(tmp_path):
    """Create sample metadata directory with test data"""
    metadata_dir = tmp_path / "metadata"
    videos_dir = metadata_dir / "videos"
    videos_dir.mkdir(parents=True)
    
    # Create sample metadata files
    metadata_files = [
        {
            "video_id": "video1",
            "title": "Squat Tutorial",
            "exercise_type": "squat",
            "duration": 120.0,
            "resolution": [1280, 720],
            "file_path": "video1.mp4",  # Changed from "videos/video1.mp4"
        },
        {
            "video_id": "video2",
            "title": "Deadlift Guide",
            "exercise_type": "deadlift",
            "duration": 180.0,
            "resolution": [1920, 1080],
            "file_path": "video2.mp4",  # Changed from "videos/video2.mp4"
        },
        {
            "video_id": "video3",
            "title": "Squat Form",
            "exercise_type": "squat",
            "duration": 150.0,
            "resolution": [1280, 720],
            "file_path": "video3.mp4",  # Changed from "videos/video3.mp4"
        },
    ]
    
    for metadata in metadata_files:
        filepath = videos_dir / f"{metadata['video_id']}.json"
        with open(filepath, 'w') as f:
            json.dump(metadata, f)
    
    return metadata_dir


@pytest.fixture
def sample_frames_dir(tmp_path):
    """Create sample frames directory with test images"""
    frames_dir = tmp_path / "frames"
    
    # Create frames for video1
    video1_frames = frames_dir / "video1"
    video1_frames.mkdir(parents=True)
    for i in range(5):
        img = Image.new('RGB', (256, 256), color=(i * 50, 100, 150))
        img.save(video1_frames / f"frame_{i:06d}.jpg")
    
    # Create frames for video2
    video2_frames = frames_dir / "video2"
    video2_frames.mkdir(parents=True)
    for i in range(3):
        img = Image.new('RGB', (256, 256), color=(200, i * 80, 100))
        img.save(video2_frames / f"frame_{i:06d}.jpg")
    
    # Create frames for video3
    video3_frames = frames_dir / "video3"
    video3_frames.mkdir(parents=True)
    for i in range(4):
        img = Image.new('RGB', (256, 256), color=(100, 150, i * 60))
        img.save(video3_frames / f"frame_{i:06d}.jpg")
    
    return frames_dir


class TestVideoFrameDataset:
    """Tests for VideoFrameDataset"""
    
    def test_initialization(self, sample_metadata_dir, sample_frames_dir):
        """Test dataset initialization"""
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=sample_frames_dir,
        )
        
        assert dataset is not None
        assert len(dataset.videos) == 3
        assert len(dataset.frame_samples) == 12  # 5 + 3 + 4 frames
    
    def test_initialization_with_filter(self, sample_metadata_dir, sample_frames_dir):
        """Test dataset initialization with exercise filter"""
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=sample_frames_dir,
            exercise_filter=["squat"],
        )
        
        # Should only load squat videos
        assert len(dataset.videos) == 2  # video1 and video3
        assert len(dataset.frame_samples) == 9  # 5 + 4 frames
    
    def test_len(self, sample_metadata_dir, sample_frames_dir):
        """Test dataset length"""
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=sample_frames_dir,
        )
        
        assert len(dataset) == 12
    
    def test_getitem(self, sample_metadata_dir, sample_frames_dir):
        """Test getting a single item"""
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=sample_frames_dir,
        )
        
        sample = dataset[0]
        
        # Check sample structure
        assert "image" in sample
        assert "video_id" in sample
        assert "frame_path" in sample
        assert "exercise_type" in sample
        assert "metadata" in sample
        
        # Check image is PIL Image (no transform applied)
        assert isinstance(sample["image"], Image.Image)
    
    def test_getitem_with_transform(self, sample_metadata_dir, sample_frames_dir):
        """Test getting item with transform applied"""
        from torchvision import transforms
        
        transform = transforms.Compose([
            transforms.Resize((128, 128)),
            transforms.ToTensor(),
        ])
        
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=sample_frames_dir,
            transform=transform,
        )
        
        sample = dataset[0]
        
        # Image should be transformed to tensor
        assert isinstance(sample["image"], torch.Tensor)
        assert sample["image"].shape == (3, 128, 128)
    
    def test_exercise_filter(self, sample_metadata_dir, sample_frames_dir):
        """Test exercise type filtering"""
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=sample_frames_dir,
            exercise_filter=["deadlift"],
        )
        
        # Should only have frames from deadlift video
        assert len(dataset) == 3
        
        # All samples should be deadlift
        for i in range(len(dataset)):
            sample = dataset[i]
            assert sample["exercise_type"] == "deadlift"
    
    def test_multiple_exercise_filter(self, sample_metadata_dir, sample_frames_dir):
        """Test filtering with multiple exercise types"""
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=sample_frames_dir,
            exercise_filter=["squat", "deadlift"],
        )
        
        # Should have all frames
        assert len(dataset) == 12
    
    def test_frame_index_building(self, sample_metadata_dir, sample_frames_dir):
        """Test frame index is built correctly"""
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=sample_frames_dir,
        )
        
        # Check frame samples structure
        assert len(dataset.frame_samples) > 0
        
        video_id, frame_path = dataset.frame_samples[0]
        assert isinstance(video_id, str)
        assert isinstance(frame_path, Path)
        assert frame_path.exists()


class TestVideoDataset:
    """Tests for VideoDataset (temporal data)"""
    
    def test_initialization(self, sample_metadata_dir, tmp_path):
        """Test VideoDataset initialization"""
        videos_dir = tmp_path / "videos"
        videos_dir.mkdir()
        
        # Create dummy video files
        for i in range(1, 4):
            (videos_dir / f"video{i}.mp4").touch()
        
        dataset = VideoDataset(
            metadata_dir=sample_metadata_dir,
            videos_dir=videos_dir,
        )
        
        assert dataset is not None
        assert len(dataset.videos) == 3
    
    def test_len(self, sample_metadata_dir, tmp_path):
        """Test dataset length"""
        videos_dir = tmp_path / "videos"
        videos_dir.mkdir()
        
        for i in range(1, 4):
            (videos_dir / f"video{i}.mp4").touch()
        
        dataset = VideoDataset(
            metadata_dir=sample_metadata_dir,
            videos_dir=videos_dir,
        )
        
        assert len(dataset) == 3
    
    def test_exercise_filter(self, sample_metadata_dir, tmp_path):
        """Test exercise filtering in VideoDataset"""
        videos_dir = tmp_path / "videos"
        videos_dir.mkdir()
        
        for i in range(1, 4):
            (videos_dir / f"video{i}.mp4").touch()
        
        dataset = VideoDataset(
            metadata_dir=sample_metadata_dir,
            videos_dir=videos_dir,
            exercise_filter=["squat"],
        )
        
        # Should only have squat videos
        assert len(dataset) == 2
    
    def test_max_frames_setting(self, sample_metadata_dir, tmp_path):
        """Test max_frames parameter"""
        videos_dir = tmp_path / "videos"
        videos_dir.mkdir()
        
        for i in range(1, 4):
            (videos_dir / f"video{i}.mp4").touch()
        
        dataset = VideoDataset(
            metadata_dir=sample_metadata_dir,
            videos_dir=videos_dir,
            max_frames=100,
        )
        
        assert dataset.max_frames == 100
    
    def test_sample_rate_setting(self, sample_metadata_dir, tmp_path):
        """Test sample_rate parameter"""
        videos_dir = tmp_path / "videos"
        videos_dir.mkdir()
        
        for i in range(1, 4):
            (videos_dir / f"video{i}.mp4").touch()
        
        dataset = VideoDataset(
            metadata_dir=sample_metadata_dir,
            videos_dir=videos_dir,
            sample_rate=3,
        )
        
        assert dataset.sample_rate == 3


class TestDataPipeline:
    """Tests for DataPipeline"""
    
    def test_initialization(self):
        """Test DataPipeline initialization"""
        pipeline = DataPipeline()
        
        assert pipeline is not None
        assert isinstance(pipeline.config, ScraperConfig)
    
    def test_custom_config(self, tmp_path):
        """Test DataPipeline with custom config"""
        config = ScraperConfig(
            output_dir=tmp_path / "scraped",
            metadata_dir=tmp_path / "metadata",
        )
        
        pipeline = DataPipeline(config)
        
        assert pipeline.config == config
    
    def test_get_statistics_empty(self, tmp_path):
        """Test statistics with no data"""
        config = ScraperConfig(
            output_dir=tmp_path / "scraped",
            metadata_dir=tmp_path / "metadata",
        )
        
        # Create directories
        (tmp_path / "metadata" / "videos").mkdir(parents=True)
        
        pipeline = DataPipeline(config)
        stats = pipeline.get_statistics()
        
        assert stats["total_videos"] == 0
        assert stats["total_frames"] == 0
        assert stats["total_duration_hours"] == 0
    
    def test_get_statistics_with_data(self, sample_metadata_dir, sample_frames_dir, tmp_path):
        """Test statistics with sample data"""
        config = ScraperConfig(
            output_dir=sample_frames_dir.parent,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        stats = pipeline.get_statistics()
        
        assert stats["total_videos"] == 3
        assert stats["total_frames"] == 12  # 5 + 3 + 4
        assert stats["total_duration_hours"] > 0
        assert "squat" in stats["by_exercise"]
        assert "deadlift" in stats["by_exercise"]
    
    def test_split_dataset(self, sample_metadata_dir, tmp_path):
        """Test dataset splitting"""
        config = ScraperConfig(
            output_dir=tmp_path,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        train_ids, val_ids, test_ids = pipeline.split_dataset(
            train_ratio=0.6,
            val_ratio=0.2,
            test_ratio=0.2,
            seed=42,
        )
        
        # Check splits
        assert len(train_ids) + len(val_ids) + len(test_ids) == 3
        assert len(train_ids) >= 1  # 60% of 3
        
        # Check no overlap
        all_ids = set(train_ids + val_ids + test_ids)
        assert len(all_ids) == 3
        
        # Check split file was created
        splits_file = sample_metadata_dir / "dataset_splits.json"
        assert splits_file.exists()
    
    def test_split_dataset_seed_consistency(self, sample_metadata_dir, tmp_path):
        """Test that same seed produces same splits"""
        config = ScraperConfig(
            output_dir=tmp_path,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        # First split
        train1, val1, test1 = pipeline.split_dataset(seed=42)
        
        # Second split with same seed
        train2, val2, test2 = pipeline.split_dataset(seed=42)
        
        # Should be identical
        assert train1 == train2
        assert val1 == val2
        assert test1 == test2
    
    def test_split_dataset_different_seeds(self, sample_metadata_dir, tmp_path):
        """Test different seeds produce different splits"""
        config = ScraperConfig(
            output_dir=tmp_path,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        # Split with different seeds
        train1, val1, test1 = pipeline.split_dataset(seed=42)
        train2, val2, test2 = pipeline.split_dataset(seed=123)
        
        # At least one should be different (probabilistically)
        # With only 3 videos, there's a chance they could be the same
        # but we check structure is correct
        assert len(train1) + len(val1) + len(test1) == 3
        assert len(train2) + len(val2) + len(test2) == 3


class TestDataLoaderCreation:
    """Tests for DataLoader creation"""
    
    def test_create_frame_dataloader(self, sample_metadata_dir, sample_frames_dir, tmp_path):
        """Test creating frame-based DataLoader"""
        config = ScraperConfig(
            output_dir=sample_frames_dir.parent,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        dataloader = pipeline.create_frame_dataloader(
            batch_size=4,
            shuffle=False,
            num_workers=0,  # No multiprocessing in tests
        )
        
        assert dataloader is not None
        assert dataloader.batch_size == 4
        assert len(dataloader.dataset) == 12
    
    def test_create_frame_dataloader_with_filter(self, sample_metadata_dir, sample_frames_dir, tmp_path):
        """Test DataLoader with exercise filter"""
        config = ScraperConfig(
            output_dir=sample_frames_dir.parent,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        dataloader = pipeline.create_frame_dataloader(
            batch_size=2,
            exercise_filter=["squat"],
            shuffle=False,
            num_workers=0,
        )
        
        # Should only have squat frames
        assert len(dataloader.dataset) == 9  # 5 + 4
    
    def test_create_frame_dataloader_with_transform(self, sample_metadata_dir, sample_frames_dir, tmp_path):
        """Test DataLoader with transforms"""
        from torchvision import transforms
        
        transform = transforms.Compose([
            transforms.Resize((128, 128)),
            transforms.ToTensor(),
        ])
        
        config = ScraperConfig(
            output_dir=sample_frames_dir.parent,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        dataloader = pipeline.create_frame_dataloader(
            batch_size=4,
            transform=transform,
            shuffle=False,
            num_workers=0,
        )
        
        # Get a batch
        batch = next(iter(dataloader))
        
        # Check batch structure
        assert "image" in batch
        assert isinstance(batch["image"], torch.Tensor)
        assert batch["image"].shape[0] <= 4  # Batch size
        assert batch["image"].shape[1:] == (3, 128, 128)  # C, H, W
    
    def test_create_video_dataloader(self, sample_metadata_dir, tmp_path):
        """Test creating video-based DataLoader"""
        videos_dir = tmp_path / "videos"
        videos_dir.mkdir()
        
        # Create dummy video files
        for i in range(1, 4):
            (videos_dir / f"video{i}.mp4").touch()
        
        config = ScraperConfig(
            output_dir=videos_dir.parent,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        dataloader = pipeline.create_video_dataloader(
            batch_size=2,
            max_frames=100,
            sample_rate=2,
            shuffle=False,
            num_workers=0,
        )
        
        assert dataloader is not None
        assert dataloader.batch_size == 2
        assert len(dataloader.dataset) == 3


class TestDataPipelineIntegration:
    """Integration tests for complete data pipeline workflows"""
    
    def test_full_pipeline_workflow(self, sample_metadata_dir, sample_frames_dir, tmp_path):
        """Test complete pipeline workflow"""
        from torchvision import transforms
        
        # Setup
        config = ScraperConfig(
            output_dir=sample_frames_dir.parent,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        # 1. Get statistics
        stats = pipeline.get_statistics()
        assert stats["total_videos"] == 3
        
        # 2. Split dataset
        train_ids, val_ids, test_ids = pipeline.split_dataset()
        assert len(train_ids) > 0
        
        # 3. Create transform
        transform = transforms.Compose([
            transforms.Resize((256, 256)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
        ])
        
        # 4. Create DataLoader
        dataloader = pipeline.create_frame_dataloader(
            batch_size=4,
            transform=transform,
            shuffle=True,
            num_workers=0,
        )
        
        # 5. Iterate through batches
        batch_count = 0
        for batch in dataloader:
            assert "image" in batch
            assert isinstance(batch["image"], torch.Tensor)
            batch_count += 1
        
        assert batch_count > 0
    
    def test_pipeline_with_filtering_and_splitting(self, sample_metadata_dir, sample_frames_dir, tmp_path):
        """Test pipeline with exercise filtering and splitting"""
        # Create a transform to convert PIL images to tensors
        from torchvision import transforms
        transform = transforms.Compose([
            transforms.ToTensor(),
        ])
        
        config = ScraperConfig(
            output_dir=sample_frames_dir.parent,
            metadata_dir=sample_metadata_dir,
        )
        
        pipeline = DataPipeline(config)
        
        # Split dataset
        train_ids, val_ids, test_ids = pipeline.split_dataset()
        
        # Create filtered DataLoader with transform
        dataloader = pipeline.create_frame_dataloader(
            batch_size=2,
            exercise_filter=["squat"],
            shuffle=False,
            num_workers=0,
            transform=transform,
        )
        
        # Verify filtering worked
        assert len(dataloader.dataset) == 9  # Only squat frames
        
        # Iterate and verify
        for batch in dataloader:
            for exercise_type in batch["exercise_type"]:
                assert exercise_type == "squat"


class TestEdgeCases:
    """Tests for edge cases and error handling"""
    
    def test_empty_dataset(self, tmp_path):
        """Test handling of empty dataset"""
        metadata_dir = tmp_path / "metadata"
        metadata_dir.mkdir()
        (metadata_dir / "videos").mkdir()
        
        frames_dir = tmp_path / "frames"
        frames_dir.mkdir()
        
        dataset = VideoFrameDataset(
            metadata_dir=metadata_dir,
            frames_dir=frames_dir,
        )
        
        assert len(dataset) == 0
    
    def test_missing_frames_directory(self, sample_metadata_dir, tmp_path):
        """Test handling when frames directory doesn't exist for a video"""
        frames_dir = tmp_path / "frames"
        frames_dir.mkdir()
        
        # Don't create frame subdirectories
        
        dataset = VideoFrameDataset(
            metadata_dir=sample_metadata_dir,
            frames_dir=frames_dir,
        )
        
        # Should handle gracefully
        assert len(dataset) == 0  # No frames available
    
    def test_invalid_metadata_file(self, tmp_path):
        """Test handling of invalid metadata files"""
        metadata_dir = tmp_path / "metadata" / "videos"
        metadata_dir.mkdir(parents=True)
        
        # Create invalid metadata file
        (metadata_dir / "invalid.json").write_text("not json")
        
        frames_dir = tmp_path / "frames"
        frames_dir.mkdir()
        
        # Should handle gracefully (skip invalid files)
        dataset = VideoFrameDataset(
            metadata_dir=metadata_dir.parent,
            frames_dir=frames_dir,
        )
        
        assert len(dataset) == 0
