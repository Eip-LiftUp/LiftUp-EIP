"""
Example: Using the Video Scraping Tool and Data Pipeline

This script demonstrates how to use the scraping tool programmatically
to collect training data and create PyTorch DataLoaders.

IMPORTANT: This is an EXAMPLE ONLY. Do not run without understanding
the implications and ensuring you have permission to scrape videos.
"""

import asyncio
from pathlib import Path
from torchvision import transforms
from app.scraping.video_scraper import VideoScraper
from app.scraping.config import ScraperConfig, VideoSourceConfig
from app.scraping.data_pipeline import DataPipeline


async def example_scraping():
    """Example: Scrape videos from YouTube"""
    print("=" * 60)
    print("EXAMPLE: Video Scraping")
    print("=" * 60)
    
    # Create custom configuration
    config = ScraperConfig(
        output_dir=Path("data/scraped"),
        video_quality="720p",
        max_duration_seconds=300,  # 5 minutes max
        extract_frames=True,
        frame_rate=30,
    )
    
    # Add a source (DISABLED by default)
    config.sources = [
        VideoSourceConfig(
            name="Test Source",
            source_type="youtube",
            enabled=False,  # KEEP THIS FALSE until you're ready
            search_queries=["squat form tutorial"],
            max_videos=5,  # Small number for testing
            filters={
                "min_views": 10000,
            }
        )
    ]
    
    print(f"\nConfiguration:")
    print(f"  Output dir: {config.output_dir}")
    print(f"  Video quality: {config.video_quality}")
    print(f"  Max  duration: {config.max_duration_seconds}s")
    print(f"  Extract frames: {config.extract_frames}")
    print(f"  Sources: {len(config.sources)}")
    print(f"  Enabled sources: {sum(1 for s in config.sources if s.enabled)}")
    
    if not any(s.enabled for s in config.sources):
        print("\n⚠️  WARNING: All sources are disabled!")
        print("  To enable, set source.enabled = True in configuration")
        print("  This example will NOT scrape any videos.")
        return
    
    # Create scraper
    scraper = VideoScraper(config)
    
    # Run scraping (ONLY if sources are enabled)
    print("\nStarting scraping...")
    scraped_videos = await scraper.scrape_all_sources()
    
    print(f"\n✓ Scraped {len(scraped_videos)} videos")
    
    # Show statistics
    stats = scraper.get_statistics()
    print(f"\nStatistics:")
    print(f"  Total videos: {stats['total_videos']}")
    print(f"  By source: {stats['by_source']}")
    print(f"  By exercise: {stats['by_exercise']}")
    print(f"  Total duration: {stats['total_duration_hours']:.2f} hours")


def example_data_pipeline():
    """Example: Create PyTorch DataLoaders from scraped data"""
    print("\n" + "=" * 60)
    print("EXAMPLE: Data Pipeline")
    print("=" * 60)
    
    # Create data pipeline
    pipeline = DataPipeline()
    
    # Get statistics
    stats = pipeline.get_statistics()
    print(f"\nDataset Statistics:")
    print(f"  Total videos: {stats['total_videos']}")
    print(f"  By exercise: {stats['by_exercise']}")
    print(f"  Total frames: {stats['total_frames']}")
    print(f"  Total duration: {stats['total_duration_hours']:.2f} hours")
    
    if stats['total_videos'] == 0:
        print("\n⚠️  No videos found!")
        print("  Run scraping first to collect training data")
        return
    
    # Create image transforms
    transform = transforms.Compose([
        transforms.Resize((256, 256)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        ),
    ])
    
    # Create DataLoader for frames
    print("\nCreating frame-based DataLoader...")
    try:
        train_loader = pipeline.create_frame_dataloader(
            batch_size=32,
            exercise_filter=['squat', 'deadlift'],  # Only these exercises
            transform=transform,
            shuffle=True,
            num_workers=2,
        )
        
        print(f"✓ DataLoader created")
        print(f"  Batch size: 32")
        print(f"  Number of batches: {len(train_loader)}")
        print(f"  Total samples: {len(train_loader.dataset)}")
        
        # Example: Iterate over first batch
        print("\nExample batch:")
        for batch in train_loader:
            images = batch['image']
            exercise_types = batch['exercise_type']
            video_ids = batch['video_id']
            
            print(f"  Image tensor shape: {images.shape}")  # (batch_size, 3, 256, 256)
            print(f"  Exercise types: {set(exercise_types)}")
            print(f"  Number of videos: {len(set(video_ids))}")
            break  # Just show first batch
    
    except Exception as e:
        print(f"✗ Error creating DataLoader: {e}")
    
    # Split dataset
    print("\nSplitting dataset...")
    try:
        train_ids, val_ids, test_ids = pipeline.split_dataset(
            train_ratio=0.8,
            val_ratio=0.1,
            test_ratio=0.1,
        )
        
        print(f"✓ Dataset split:")
        print(f"  Train: {len(train_ids)} videos")
        print(f"  Val: {len(val_ids)} videos")
        print(f"  Test: {len(test_ids)} videos")
    
    except Exception as e:
        print(f"✗ Error splitting dataset: {e}")


def example_training_integration():
    """Example: Integrate with PyTorch training"""
    print("\n" + "=" * 60)
    print("EXAMPLE: Training Integration")
    print("=" * 60)
    
    print("""
This is a skeleton training loop showing how to integrate
the data pipeline with PyTorch model training.

import torch
import torch.nn as nn
from app.scraping.data_pipeline import DataPipeline

# Setup
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
pipeline = DataPipeline()

# Create DataLoader
train_loader = pipeline.create_frame_dataloader(
    batch_size=32,
    transform=transform,
)

# Load or create model
model = YourPoseEstimationModel()
model = model.to(device)

# Optimizer and loss
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
criterion = nn.MSELoss()

# Training loop
for epoch in range(num_epochs):
    model.train()
    epoch_loss = 0
    
    for batch in train_loader:
        # Get data
        images = batch['image'].to(device)
        # targets = batch['targets'].to(device)  # If you have ground truth
        
        # Forward pass
        outputs = model(images)
        
        # Calculate loss (example)
        # loss = criterion(outputs, targets)
        
        # Backward pass
        optimizer.zero_grad()
        # loss.backward()
        # optimizer.step()
        
        # epoch_loss += loss.item()
    
    print(f"Epoch {epoch+1}/{num_epochs}, Loss: {epoch_loss/len(train_loader):.4f}")

# Save model
torch.save(model.state_dict(), 'data/models/pose_model.pth')
""")


def main():
    """Run all examples"""
    print("""
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║    LiftUp Video Scraping & Data Pipeline Examples             ║
║                                                                ║
║    ⚠️  IMPORTANT: This is for demonstration purposes only     ║
║    Do not run scraping without proper authorization          ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    # Example 1: Scraping (async)
    print("\n[1] Scraping Example (Disabled by default)")
    print("-" * 60)
    asyncio.run(example_scraping())
    
    # Example 2: Data Pipeline
    print("\n[2] Data Pipeline Example")
    print("-" * 60)
    example_data_pipeline()
    
    # Example 3: Training Integration
    print("\n[3] Training Integration Example")
    print("-" * 60)
    example_training_integration()
    
    print("\n" + "=" * 60)
    print("Examples complete!")
    print("=" * 60)
    print(
"""
Next steps:
1. Review and customize scraper_config.json
2. Enable sources when ready to collect data
3. Run: python -m app.scraping.cli scrape --enable-sources "Your Source"
4. Use DataPipeline to create DataLoaders
5. Train your PyTorch model
6. Deploy trained model to app/services/pose_estimator.py

For more information, see:
- SCRAPING_TOOL.md
- PYTORCH_SCRAPING_SETUP.md
- README.md
"""
    )


if __name__ == "__main__":
    main()
