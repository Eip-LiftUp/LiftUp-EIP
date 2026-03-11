# Video Scraping Tool for ML Training

This tool provides automated video data collection for training pose estimation and form analysis ML models.

## Overview

The video scraping system consists of:
- **Video Scraper**: Downloads videos from various sources (YouTube, web, local files)
- **Data Pipeline**: Converts scraped videos into ML-ready datasets
- **Configuration System**: Flexible configuration for different scraping scenarios
- **CLI Tool**: Command-line interface for managing scraping operations

## Features

### Video Scraper
- ✅ YouTube video downloading with yt-dlp
- ✅ Automatic exercise type detection from titles/descriptions
- ✅ Video quality and duration filtering
- ✅ Rate limiting and concurrent download management
- ✅ Frame extraction for training
- ✅ Metadata collection and organization
- ⏳ Web scraping from other sources (planned)
- ⏳ Local file batch processing (planned)

### Data Pipeline
- ✅ PyTorch Dataset classes for frames and videos
- ✅ Automatic train/val/test splitting
- ✅ Exercise type filtering
- ✅ Frame sampling and preprocessing
- ✅ Batch loading with DataLoader
- ✅ Statistics and analytics

## Installation

Dependencies are already included in `requirements.txt`:

```bash
# From the server directory
pip install -r requirements.txt
```

Key dependencies:
- `yt-dlp`: YouTube video downloading
- `opencv-python`: Video processing and frame extraction
- `beautifulsoup4`: Web scraping
- `moviepy`: Video editing and conversion
- `torch`, `torchvision`: ML framework

## Quick Start

### 1. Initialize Configuration

```bash
# Create a default configuration file
python -m app.scraping.cli init

# Or with custom settings
python -m app.scraping.cli init --output-dir data/scraped --video-quality 720p
```

This creates `scraper_config.json` with default settings.

### 2. Configure Sources

Edit `scraper_config.json` to customize your scraping sources:

```json
{
  "sources": [
    {
      "name": "Workout YouTube",
      "source_type": "youtube",
      "enabled": false,  // Change to true to enable
      "search_queries": [
        "squat form tutorial",
        "deadlift technique",
        "bench press form"
      ],
      "max_videos": 50,
      "filters": {
        "min_views": 1000,
        "language": "en"
      }
    }
  ]
}
```

### 3. Start Scraping

**IMPORTANT**: Scraping is disabled by default. Enable sources explicitly:

```bash
# Enable specific sources and start scraping
python -m app.scraping.cli scrape --enable-sources "Workout YouTube"

# Or enable multiple sources
python -m app.scraping.cli scrape --enable-sources "Source1" "Source2"
```

### 4. View Statistics

```bash
# Show dataset statistics
python -m app.scraping.cli stats
```

### 5. Split Dataset

```bash
# Split into train/val/test sets (80/10/10)
python -m app.scraping.cli split

# Custom ratios
python -m app.scraping.cli split --train-ratio 0.7 --val-ratio 0.15 --test-ratio 0.15
```

## Configuration Reference

### ScraperConfig Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `output_dir` | Path | `data/scraped` | Where to store scraped videos |
| `metadata_dir` | Path | `data/annotations` | Where to store metadata |
| `video_format` | str | `mp4` | Preferred video format |
| `video_quality` | str | `720p` | Quality: 360p, 480p, 720p, 1080p |
| `max_duration_seconds` | int | 600 | Maximum video duration (10 min) |
| `min_duration_seconds` | int | 30 | Minimum video duration |
| `extract_frames` | bool | true | Extract frames for training |
| `frame_rate` | int | 30 | Target frame rate for extraction |
| `resize_frames` | tuple | (256, 256) | Resize frames to (width, height) |
| `max_concurrent_downloads` | int | 3 | Max simultaneous downloads |
| `download_delay_seconds` | int | 2 | Delay between downloads |

### VideoSourceConfig Options

| Option | Type | Description |
|--------|------|-------------|
| `name` | str | Unique name for the source |
| `source_type` | str | Type: `youtube`, `web`, or `local` |
| `enabled` | bool | Whether this source is active |
| `search_queries` | list | Search terms for finding videos |
| `max_videos` | int | Maximum videos to scrape |
| `filters` | dict | Additional filters (views, language, etc) |

## Usage Examples

### Adding a New Source

```bash
python -m app.scraping.cli add-source \
  --name "Advanced Lifting" \
  --source-type youtube \
  --queries "olympic weightlifting form" "snatch technique" \
  --max-videos 30 \
  --enabled
```

### Programmatic Usage

```python
from app.scraping.video_scraper import VideoScraper
from app.scraping.config import ScraperConfig, VideoSourceConfig

# Create configuration
config = ScraperConfig(
    output_dir="data/my_dataset",
    video_quality="720p",
    max_videos=100,
)

# Add a source
config.sources.append(
    VideoSourceConfig(
        name="My Source",
        source_type="youtube",
        enabled=True,
        search_queries=["workout form tutorial"],
        max_videos=50,
    )
)

# Create scraper and run
scraper = VideoScraper(config)
scraped_videos = await scraper.scrape_all_sources()

# Get statistics
stats = scraper.get_statistics()
print(f"Scraped {stats['total_videos']} videos")
```

### Using the Data Pipeline

```python
from app.scraping.data_pipeline import DataPipeline
from torchvision import transforms

# Create transforms
transform = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

# Create pipeline
pipeline = DataPipeline()

# Create DataLoader for frame-based training
train_loader = pipeline.create_frame_dataloader(
    batch_size=32,
    exercise_filter=['squat', 'deadlift'],  # Only these exercises
    transform=transform,
    shuffle=True,
)

# Use in training loop
for batch in train_loader:
    images = batch['image']  # Tensor of shape (batch_size, 3, 256, 256)
    exercise_types = batch['exercise_type']  # List of exercise types
    # ... training code ...
```

### Video-Based DataLoader (Temporal)

```python
# Create DataLoader for video sequences (temporal data)
video_loader = pipeline.create_video_dataloader(
    batch_size=4,
    exercise_filter=['squat'],
    max_frames=300,  # Max frames per video
    sample_rate=2,   # Sample every 2nd frame
    transform=transform,
)

# Use in training
for batch in video_loader:
    videos = batch['frames']  # Tensor of shape (batch_size, T, 3, H, W)
    # ... temporal model training ...
```

## Data Organization

After scraping, data is organized as:

```
data/
├── scraped/
│   ├── videos/           # Downloaded videos
│   │   ├── abc123.mp4
│   │   └── def456.mp4
│   └── frames/           # Extracted frames
│       ├── abc123/
│       │   ├── frame_000000.jpg
│       │   ├── frame_000001.jpg
│       │   └── ...
│       └── def456/
│           └── ...
├── annotations/
│   ├── videos/           # Metadata for each video
│   │   ├── abc123.json
│   │   └── def456.json
│   ├── dataset_splits.json  # Train/val/test splits
│   └── scraping_summary.json  # Overall statistics
└── temp/                 # Temporary files
```

## Metadata Format

Each video gets a metadata JSON file:

```json
{
  "video_id": "abc123",
  "title": "Perfect Squat Form Tutorial",
  "source": "Workout YouTube",
  "url": "https://youtube.com/watch?v=...",
  "duration": 180.5,
  "resolution": [1280, 720],
  "file_path": "videos/abc123.mp4",
  "exercise_type": "squat",
  "annotations": {
    "fps": 30.0,
    "frame_count": 5415,
    "uploader": "FitnessCoach",
    "view_count": 50000,
    "description": "Learn proper squat form..."
  },
  "scraped_at": "2026-03-09T10:30:00"
}
```

## Best Practices

### Rate Limiting
- Keep `download_delay_seconds` at least 2 seconds
- Use `max_concurrent_downloads` = 3 or less
- Be respectful of source websites

### Quality vs Quantity
- Start with high-quality sources (high view counts)
- Use `min_views` filter to ensure quality content
- Review scraped videos before using for training

### Storage Management
- 720p videos: ~50-100 MB per minute
- Frame extraction multiplies storage needs
- Monitor disk space when scraping large datasets
- Use `max_duration_seconds` to limit storage

### Exercise Type Detection
- Add variations to `search_queries` for better coverage
- The auto-annotate feature detects exercise types from titles
- Review and correct annotations in metadata files if needed

## Troubleshooting

### "No videos downloaded"
- Check that at least one source is `enabled: true`
- Verify search queries return results on YouTube
- Check internet connection
- Review logs for specific errors

### "Rate limited" or "HTTP 429"
- Increase `download_delay_seconds`
- Decrease `max_concurrent_downloads`
- Take a break and resume later

### "Disk space full"
- Reduce `max_videos` or `max_duration_seconds`
- Set `extract_frames: false` if you only need videos
- Clean up old scraped data

### Missing frames
- Check that `extract_frames: true` in config
- Verify video downloaded successfully
- Check logs for frame extraction errors

## Advanced Usage

### Custom Filters

Add custom filters in source configuration:

```json
{
  "filters": {
    "min_views": 10000,
    "max_views": 1000000,
    "min_duration": 120,
    "max_duration": 600,
    "language": "en",
    "upload_date": "20230101"
  }
}
```

### Integration with Training

```python
# Example training integration
from app.scraping.data_pipeline import DataPipeline
from app.services.pose_estimator import PoseEstimator
import torch
import torch.nn as nn
from torchvision import transforms

# Setup
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
pipeline = DataPipeline()

# Create DataLoader
transform = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])

train_loader = pipeline.create_frame_dataloader(
    batch_size=32,
    transform=transform,
    exercise_filter=['squat', 'deadlift'],
)

# Load or create model
# model = YourPoseEstimationModel()
# model = model.to(device)
# optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
# criterion = nn.MSELoss()

# Training loop (example)
# for epoch in range(num_epochs):
#     for batch in train_loader:
#         images = batch['image'].to(device)
#         
#         # Forward pass
#         outputs = model(images)
#         
#         # Calculate loss (would need ground truth labels)
#         # loss = criterion(outputs, targets)
#         
#         # Backward pass
#         # optimizer.zero_grad()
#         # loss.backward()
#         # optimizer.step()
```

## Safety & Legal

**IMPORTANT DISCLAIMERS**:

1. **Respect Copyright**: Only scrape videos you have permission to use
2. **Terms of Service**: Comply with YouTube and other platforms' ToS
3. **Rate Limiting**: Be respectful and avoid overloading servers
4. **Educational Use**: This tool is for educational/research purposes
5. **Review Content**: Manually review scraped content before training

## Future Enhancements

Planned features:
- [ ] Web scraping from fitness websites
- [ ] Instagram/TikTok integration
- [ ] Automatic pose annotation with existing models
- [ ] Data augmentation pipeline
- [ ] Active learning integration
- [ ] Multi-person pose tracking
- [ ] Quality assessment scoring

## Support

For issues or questions:
1. Check this documentation
2. Review the configuration file examples
3. Check logs for error messages
4. Adjust rate limiting if getting errors

---

**Note**: This tool is currently in setup mode. All sources are disabled by default. You must explicitly enable sources before scraping will begin.
