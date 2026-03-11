"""Data Pipeline for ML Training

This module handles the pipeline from scraped videos to ML-ready datasets.
"""

import json
import logging
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
import random

import torch
from torch.utils.data import Dataset, DataLoader
import cv2
import numpy as np
from PIL import Image

from app.scraping.config import ScraperConfig

logger = logging.getLogger(__name__)


class VideoFrameDataset(Dataset):
    """PyTorch Dataset for video frames extracted from scraped videos"""
    
    def __init__(
        self,
        metadata_dir: Path,
        frames_dir: Path,
        exercise_filter: Optional[List[str]] = None,
        transform=None,
    ):
        """
        Initialize the dataset.
        
        Args:
            metadata_dir: Directory containing video metadata JSON files
            frames_dir: Directory containing extracted frames
            exercise_filter: List of exercise types to include (None = all)
            transform: Optional torchvision transforms to apply
        """
        self.metadata_dir = metadata_dir
        self.frames_dir = frames_dir
        self.exercise_filter = exercise_filter
        self.transform = transform
        
        # Load all video metadata
        self.videos = self._load_metadata()
        
        # Build frame index
        self.frame_samples = self._build_frame_index()
        
        logger.info(f"Loaded dataset with {len(self.frame_samples)} frames from {len(self.videos)} videos")
    
    def _load_metadata(self) -> List[Dict[str, Any]]:
        """Load all video metadata files"""
        videos = []
        metadata_files = list((self.metadata_dir / 'videos').glob('*.json'))
        
        for metadata_file in metadata_files:
            try:
                with open(metadata_file, 'r') as f:
                    metadata = json.load(f)
                
                # Filter by exercise type if specified
                if self.exercise_filter:
                    if metadata.get('exercise_type') not in self.exercise_filter:
                        continue
                
                videos.append(metadata)
            
            except Exception as e:
                logger.warning(f"Error loading metadata {metadata_file}: {str(e)}")
        
        return videos
    
    def _build_frame_index(self) -> List[Tuple[str, Path]]:
        """Build an index of all available frames"""
        frame_samples = []
        
        for video in self.videos:
            video_id = video['video_id']
            video_frames_dir = self.frames_dir / video_id
            
            if not video_frames_dir.exists():
                continue
            
            # Get all frame files for this video
            frame_files = sorted(video_frames_dir.glob('frame_*.jpg'))
            
            for frame_file in frame_files:
                frame_samples.append((video_id, frame_file))
        
        return frame_samples
    
    def __len__(self) -> int:
        """Return the number of samples in the dataset"""
        return len(self.frame_samples)
    
    def __getitem__(self, idx: int) -> Dict[str, Any]:
        """
        Get a single sample.
        
        Returns:
            Dictionary with:
                - image: Tensor of the frame
                - video_id: ID of the source video
                - frame_path: Path to the frame file
                - exercise_type: Type of exercise (if available)
                - metadata: Additional metadata
        """
        video_id, frame_path = self.frame_samples[idx]
        
        # Load image
        image = Image.open(frame_path).convert('RGB')
        
        # Apply transforms if provided
        if self.transform:
            image = self.transform(image)
        
        # Find video metadata
        video_metadata = next((v for v in self.videos if v['video_id'] == video_id), {})
        
        return {
            'image': image,
            'video_id': video_id,
            'frame_path': str(frame_path),
            'exercise_type': video_metadata.get('exercise_type'),
            'metadata': video_metadata,
        }


class VideoDataset(Dataset):
    """PyTorch Dataset for full videos (temporal data)"""
    
    def __init__(
        self,
        metadata_dir: Path,
        videos_dir: Path,
        exercise_filter: Optional[List[str]] = None,
        max_frames: int = 300,
        sample_rate: int = 2,
        transform=None,
    ):
        """
        Initialize video dataset.
        
        Args:
            metadata_dir: Directory containing metadata
            videos_dir: Directory containing video files
            exercise_filter: Filter by exercise types
            max_frames: Maximum frames to load per video
            sample_rate: Sample every Nth frame
            transform: Transforms to apply
        """
        self.metadata_dir = metadata_dir
        self.videos_dir = videos_dir
        self.exercise_filter = exercise_filter
        self.max_frames = max_frames
        self.sample_rate = sample_rate
        self.transform = transform
        
        # Load metadata
        self.videos = self._load_metadata()
        
        logger.info(f"Loaded video dataset with {len(self.videos)} videos")
    
    def _load_metadata(self) -> List[Dict[str, Any]]:
        """Load video metadata"""
        videos = []
        metadata_files = list((self.metadata_dir / 'videos').glob('*.json'))
        
        for metadata_file in metadata_files:
            try:
                with open(metadata_file, 'r') as f:
                    metadata = json.load(f)
                
                # Filter by exercise type
                if self.exercise_filter:
                    if metadata.get('exercise_type') not in self.exercise_filter:
                        continue
                
                # Check if video file exists
                video_path = self.videos_dir / metadata['file_path']
                if video_path.exists():
                    videos.append(metadata)
            
            except Exception as e:
                logger.warning(f"Error loading metadata {metadata_file}: {str(e)}")
        
        return videos
    
    def __len__(self) -> int:
        return len(self.videos)
    
    def __getitem__(self, idx: int) -> Dict[str, Any]:
        """
        Get a video sample.
        
        Returns:
            Dictionary with:
                - frames: Tensor of shape (T, C, H, W) where T is time
                - video_id: Video ID
                - exercise_type: Exercise type
                - metadata: Additional metadata
        """
        video_meta = self.videos[idx]
        video_path = self.videos_dir / video_meta['file_path']
        
        # Load video frames
        frames = self._load_video_frames(video_path)
        
        return {
            'frames': frames,
            'video_id': video_meta['video_id'],
            'exercise_type': video_meta.get('exercise_type'),
            'metadata': video_meta,
        }
    
    def _load_video_frames(self, video_path: Path) -> torch.Tensor:
        """Load frames from video file"""
        cap = cv2.VideoCapture(str(video_path))
        frames = []
        frame_count = 0
        
        while len(frames) < self.max_frames:
            ret, frame = cap.read()
            if not ret:
                break
            
            # Sample at specified rate
            if frame_count % self.sample_rate == 0:
                # Convert BGR to RGB
                frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                frame = Image.fromarray(frame)
                
                # Apply transforms
                if self.transform:
                    frame = self.transform(frame)
                
                frames.append(frame)
            
            frame_count += 1
        
        cap.release()
        
        # Stack frames into tensor (T, C, H, W)
        if frames:
            frames_tensor = torch.stack(frames)
        else:
            # Return empty tensor if no frames loaded
            frames_tensor = torch.zeros((0, 3, 256, 256))
        
        return frames_tensor


class DataPipeline:
    """Manages the data pipeline from scraped videos to ML training"""
    
    def __init__(self, config: Optional[ScraperConfig] = None):
        self.config = config or ScraperConfig()
    
    def create_frame_dataloader(
        self,
        batch_size: int = 32,
        exercise_filter: Optional[List[str]] = None,
        transform=None,
        shuffle: bool = True,
        num_workers: int = 4,
    ) -> DataLoader:
        """
        Create a DataLoader for frame-based training.
        
        Args:
            batch_size: Batch size for training
            exercise_filter: Filter by exercise types
            transform: Transforms to apply
            shuffle: Whether to shuffle data
            num_workers: Number of worker processes
            
        Returns:
            PyTorch DataLoader
        """
        dataset = VideoFrameDataset(
            metadata_dir=self.config.metadata_dir,
            frames_dir=self.config.output_dir / 'frames',
            exercise_filter=exercise_filter,
            transform=transform,
        )
        
        return DataLoader(
            dataset,
            batch_size=batch_size,
            shuffle=shuffle,
            num_workers=num_workers,
            pin_memory=True,
        )
    
    def create_video_dataloader(
        self,
        batch_size: int = 4,
        exercise_filter: Optional[List[str]] = None,
        max_frames: int = 300,
        sample_rate: int = 2,
        transform=None,
        shuffle: bool = True,
        num_workers: int = 2,
    ) -> DataLoader:
        """
        Create a DataLoader for video-based training (temporal sequences).
        
        Args:
            batch_size: Batch size
            exercise_filter: Filter by exercise types
            max_frames: Max frames per video
            sample_rate: Sample every Nth frame
            transform: Transforms to apply
            shuffle: Whether to shuffle
            num_workers: Number of workers
            
        Returns:
            PyTorch DataLoader
        """
        dataset = VideoDataset(
            metadata_dir=self.config.metadata_dir,
            videos_dir=self.config.output_dir / 'videos',
            exercise_filter=exercise_filter,
            max_frames=max_frames,
            sample_rate=sample_rate,
            transform=transform,
        )
        
        return DataLoader(
            dataset,
            batch_size=batch_size,
            shuffle=shuffle,
            num_workers=num_workers,
            pin_memory=True,
        )
    
    def split_dataset(
        self,
        train_ratio: float = 0.8,
        val_ratio: float = 0.1,
        test_ratio: float = 0.1,
        seed: int = 42,
    ) -> Tuple[List[str], List[str], List[str]]:
        """
        Split videos into train/val/test sets.
        
        Args:
            train_ratio: Proportion for training
            val_ratio: Proportion for validation
            test_ratio: Proportion for testing
            seed: Random seed
            
        Returns:
            Tuple of (train_video_ids, val_video_ids, test_video_ids)
        """
        assert abs(train_ratio + val_ratio + test_ratio - 1.0) < 1e-6, "Ratios must sum to 1"
        
        # Load all video metadata
        metadata_files = list((self.config.metadata_dir / 'videos').glob('*.json'))
        video_ids = [f.stem for f in metadata_files]
        
        # Shuffle with seed
        random.seed(seed)
        random.shuffle(video_ids)
        
        # Split
        n_total = len(video_ids)
        n_train = int(n_total * train_ratio)
        n_val = int(n_total * val_ratio)
        
        train_ids = video_ids[:n_train]
        val_ids = video_ids[n_train:n_train + n_val]
        test_ids = video_ids[n_train + n_val:]
        
        # Save splits
        splits = {
            'train': train_ids,
            'val': val_ids,
            'test': test_ids,
        }
        
        splits_path = self.config.metadata_dir / 'dataset_splits.json'
        with open(splits_path, 'w') as f:
            json.dump(splits, f, indent=2)
        
        logger.info(f"Dataset split: {len(train_ids)} train, {len(val_ids)} val, {len(test_ids)} test")
        
        return train_ids, val_ids, test_ids
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get statistics about the scraped dataset"""
        metadata_files = list((self.config.metadata_dir / 'videos').glob('*.json'))
        
        stats = {
            'total_videos': len(metadata_files),
            'by_exercise': {},
            'total_duration_hours': 0,
            'total_frames': 0,
        }
        
        for metadata_file in metadata_files:
            with open(metadata_file, 'r') as f:
                metadata = json.load(f)
            
            # Count by exercise
            exercise = metadata.get('exercise_type', 'unknown')
            stats['by_exercise'][exercise] = stats['by_exercise'].get(exercise, 0) + 1
            
            # Total duration
            stats['total_duration_hours'] += metadata.get('duration', 0) / 3600
            
            # Count frames
            video_id = metadata['video_id']
            frames_dir = self.config.output_dir / 'frames' / video_id
            if frames_dir.exists():
                frame_count = len(list(frames_dir.glob('frame_*.jpg')))
                stats['total_frames'] += frame_count
        
        return stats


# Example usage for testing
if __name__ == "__main__":
    from torchvision import transforms
    
    # Create transforms
    transform = transforms.Compose([
        transforms.Resize((256, 256)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    
    # Create pipeline
    pipeline = DataPipeline()
    
    # Get statistics
    stats = pipeline.get_statistics()
    print("Dataset Statistics:")
    print(json.dumps(stats, indent=2))
    
    # Create dataloaders (example)
    # train_loader = pipeline.create_frame_dataloader(
    #     batch_size=32,
    #     exercise_filter=['squat', 'deadlift'],
    #     transform=transform,
    # )
