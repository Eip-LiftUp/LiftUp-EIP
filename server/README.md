# LiftUp ML Service

AI-powered pose estimation and form analysis service for the LiftUp fitness coaching application.

## Overview

This service provides REST APIs for:
- **Pose Estimation**: Detect body keypoints from images and videos
- **Form Analysis**: Analyze workout form and provide coaching feedback
- **Real-time Feedback**: Low-latency feedback during live workout sessions

## Architecture

```
server/
├── app/
│   ├── api/
│   │   └── endpoints/      # API route handlers
│   │       ├── health.py   # Health check endpoints
│   │       ├── pose.py     # Pose estimation endpoints
│   │       └── analysis.py # Form analysis endpoints
│   ├── core/
│   │   └── config.py       # Configuration settings
│   ├── models/
│   │   └── schemas.py      # Pydantic data models
│   ├── services/
│   │   ├── pose_estimator.py  # PyTorch pose estimation service
│   │   └── form_analyzer.py   # Form analysis service
│   ├── scraping/           # Data collection tools
│   │   ├── video_scraper.py   # Video scraping from YouTube/web
│   │   ├── data_pipeline.py   # PyTorch Dataset and DataLoader
│   │   ├── config.py          # Scraper configuration
│   │   └── cli.py             # Command-line interface
│   ├── utils/              # Utility functions
│   └── main.py             # FastAPI application
├── data/
│   ├── models/             # PyTorch model files (.pth)
│   ├── scraped/            # Scraped training videos
│   │   ├── videos/         # Downloaded videos
│   │   └── frames/         # Extracted frames
│   ├── annotations/        # Video metadata and labels
│   └── samples/            # Sample data for testing
├── tests/                  # Unit and integration tests
├── requirements.txt        # Python dependencies (PyTorch, FastAPI, yt-dlp, etc.)
├── scraper_config.json.example  # Example scraper configuration
├── Dockerfile              # Docker configuration
├── docker-compose.yml      # Docker Compose setup
├── README.md               # This file
└── SCRAPING_TOOL.md        # Video scraping documentation
```

### Tech Stack

- **Framework**: FastAPI (async Python web framework)
- **ML Framework**: PyTorch 2.1.2 + TorchVision
- **Computer Vision**: OpenCV
- **Data Collection**: yt-dlp, BeautifulSoup4
- **Validation**: Pydantic
- **Testing**: Pytest
- **Containerization**: Docker

## Quick Start

### Option 1: Local Development

#### Prerequisites
- Python 3.11+
- pip

#### Setup

```bash
# Navigate to server directory
cd server

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Linux/Mac:
source venv/bin/activate
# Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Run the server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

### Option 2: Docker

```bash
# Build and run with Docker Compose
cd server
docker-compose up --build

# Or use Docker directly
docker build -t liftup-ml-service .
docker run -p 8000:8000 liftup-ml-service
```

## API Documentation

Once the server is running, access the interactive API documentation:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Key Endpoints

#### Health Check
```bash
GET /api/v1/health
```

#### Pose Estimation
```bash
# Estimate pose from image
POST /api/v1/pose/estimate
Content-Type: multipart/form-data
Body: file (image)

# Estimate pose from video
POST /api/v1/pose/estimate-video
Content-Type: multipart/form-data
Body: file (video)

# Get keypoint names
GET /api/v1/pose/keypoints/names
```

#### Form Analysis
```bash
# Analyze workout form
POST /api/v1/analysis/analyze-form
Content-Type: application/json
Body: {
  "exercise_type": "squat",
  "keypoints": [...],
  "metadata": {...}
}

# Real-time feedback
POST /api/v1/analysis/real-time-feedback

# Get supported exercises
GET /api/v1/analysis/exercises

# Get exercise guidelines
GET /api/v1/analysis/exercises/{exercise_type}/guidelines
```

## Example Usage

### Python

```python
import requests

# Health check
response = requests.get("http://localhost:8000/api/v1/health")
print(response.json())

# Upload image for pose estimation
with open("workout_photo.jpg", "rb") as f:
    response = requests.post(
        "http://localhost:8000/api/v1/pose/estimate",
        files={"file": f}
    )
    pose_data = response.json()
    print(f"Detected {len(pose_data['keypoints'])} keypoints")

# Get exercise guidelines
response = requests.get("http://localhost:8000/api/v1/analysis/exercises/squat/guidelines")
guidelines = response.json()
print(guidelines)
```

### cURL

```bash
# Health check
curl http://localhost:8000/api/v1/health

# Pose estimation
curl -X POST http://localhost:8000/api/v1/pose/estimate \
  -F "file=@workout_photo.jpg"

# Get exercises
curl http://localhost:8000/api/v1/analysis/exercises
```

### Flutter (Dart)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> analyzePose() async {
  final uri = Uri.parse('http://localhost:8000/api/v1/pose/estimate');
  
  var request = http.MultipartRequest('POST', uri);
  request.files.add(await http.MultipartFile.fromPath('file', imagePath));
  
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  var poseData = jsonDecode(responseData);
  
  print('Confidence: ${poseData['confidence']}');
}
```

## Development

### Running Tests

```bash
# Install dev dependencies
pip install -r requirements-dev.txt

# Run tests
pytest

# Run tests with coverage
pytest --cov=app tests/

# Run specific test file
pytest tests/test_pose_estimator.py
```

### Code Quality

```bash
# Format code with Black
black app/ tests/

# Lint with flake8
flake8 app/ tests/

# Type checking with mypy
mypy app/
```

### Adding New Exercises

1. Add exercise to `supported_exercises` list in `app/services/form_analyzer.py`
2. Add guidelines to `_load_guidelines()` method
3. Implement exercise-specific analysis logic
4. Update tests

## ML Model Integration

### Framework: PyTorch

This service is **built on PyTorch** for maximum flexibility and state-of-the-art model support.

### Current Status
The service currently uses **mock implementations** for pose estimation and form analysis. These are placeholders that return dummy data for testing the API structure.

The service is configured to use:
- **PyTorch 2.1.2**: Main deep learning framework
- **TorchVision 0.16.2**: Pre-trained models and transforms
- **OpenCV**: Video processing and frame extraction
- **GPU Support**: Auto-detects CUDA and uses GPU when available

### Integrating Real Models

#### Option 1: Pre-trained Keypoint R-CNN (TorchVision)

The easiest way to get started with a real model:

```python
# Update app/services/pose_estimator.py
import torch
import torchvision

class PoseEstimator:
    def __init__(self):
        # Load pre-trained Keypoint R-CNN
        self.model = torchvision.models.detection.keypointrcnn_resnet50_fpn(pretrained=True)
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model.to(self.device)
        self.model.eval()
    
    async def estimate_pose(self, image_data: bytes):
        # Preprocess
        input_tensor = self.transform(image).unsqueeze(0).to(self.device)
        
        # Inference
        with torch.no_grad():
            predictions = self.model(input_tensor)
        
        # Process predictions
        keypoints = predictions[0]['keypoints'][0]  # First person
        return self._convert_to_api_format(keypoints)
```

#### Option 2: Custom PyTorch Model

Train your own model on workout-specific data:

```python
import torch
import torch.nn as nn

class WorkoutPoseNet(nn.Module):
    def __init__(self):
        super().__init__()
        # Your custom architecture
        self.backbone = ...
        self.keypoint_head = ...
    
    def forward(self, x):
        features = self.backbone(x)
        keypoints = self.keypoint_head(features)
        return keypoints

# In pose_estimator.py
class PoseEstimator:
    def __init__(self):
        self.model = WorkoutPoseNet()
        
        # Load trained weights
        checkpoint = torch.load('data/models/workout_pose_model.pth')
        self.model.load_state_dict(checkpoint['model_state_dict'])
        
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model.to(self.device)
        self.model.eval()
```

#### Option 3: HRNet or Other SOTA Models

Use state-of-the-art pose estimation architectures:

```python
# Install mmpose or other framework
# pip install mmpose mmcv

# Or implement HRNet in PyTorch from scratch
# See: https://github.com/leoxiaobin/deep-high-resolution-net.pytorch
```

### Model Files

Place your trained models in:
```
data/
└── models/
    ├── pose_model.pth          # Pose estimation model
    ├── form_classifier.pth     # Form quality classifier
    └── rep_counter.pth         # Rep counting model
```

### Training Your Own Models

See the [Data Collection & Training](#data-collection--training) section below for information on collecting training data with the video scraping tool.

## Data Collection & Training

### Video Scraping Tool

The service includes a comprehensive **video scraping tool** for collecting training data from YouTube and other sources.

**Full documentation**: See [SCRAPING_TOOL.md](./SCRAPING_TOOL.md)

#### Quick Start

```bash
# Initialize scraper configuration
python -m app.scraping.cli init

# Edit scraper_config.json to customize sources and queries

# Enable sources and start scraping
python -m app.scraping.cli scrape --enable-sources "Workout YouTube"

# View collected data statistics
python -m app.scraping.cli stats

# Split dataset for training
python -m app.scraping.cli split --train-ratio 0.8 --val-ratio 0.1 --test-ratio 0.1
```

#### Features

- ✅ **YouTube video downloading** with quality/duration filtering
- ✅ **Automatic frame extraction** at configurable frame rates
- ✅ **Exercise type detection** from video titles/descriptions
- ✅ **Metadata collection** and organization
- ✅ **PyTorch DataLoader integration** for seamless training
- ✅ **Train/val/test splitting** with configurable ratios
- ✅ **Rate limiting** and concurrent download management

#### Data Pipeline Integration

The scraper integrates directly with PyTorch for training:

```python
from app.scraping.data_pipeline import DataPipeline
from torchvision import transforms

# Create transforms
transform = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])

# Create data pipeline
pipeline = DataPipeline()

# Create DataLoaders
train_loader = pipeline.create_frame_dataloader(
    batch_size=32,
    exercise_filter=['squat', 'deadlift'],
    transform=transform,
    shuffle=True,
)

# Use in training loop
for batch in train_loader:
    images = batch['image']  # (batch_size, 3, 256, 256)
    exercise_types = batch['exercise_type']
    # ... your training code ...
```

#### Safety Notes

⚠️ **IMPORTANT**: The scraping tool is **disabled by default**. You must explicitly:
1. Enable sources in configuration
2. Use `--enable-sources` flag when running
3. Comply with YouTube Terms of Service
4. Respect copyright and only use videos you have permission to use

For detailed documentation, usage examples, and best practices, see [SCRAPING_TOOL.md](./SCRAPING_TOOL.md).

### Training Workflow

1. **Collect Data**: Use scraping tool to collect workout videos
2. **Extract Frames**: Automatically extract frames at target frame rate
3. **Annotate** (optional): Add ground truth annotations if needed
4. **Split Dataset**: Create train/val/test splits
5. **Train Model**: Use PyTorch DataLoaders to train your model
6. **Evaluate**: Test on held-out test set
7. **Deploy**: Save model to `data/models/` and update pose_estimator.py

Example training script structure:

```python
# train.py
import torch
from app.scraping.data_pipeline import DataPipeline

# Setup
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
pipeline = DataPipeline()

# Create DataLoaders
train_loader = pipeline.create_frame_dataloader(batch_size=32, transform=transform)
val_loader = pipeline.create_frame_dataloader(batch_size=32, shuffle=False)

# Initialize model
model = YourPoseModel().to(device)
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
criterion = nn.MSELoss()

# Training loop
for epoch in range(num_epochs):
    for batch in train_loader:
        images = batch['image'].to(device)
        # ... training code ...
```

## Configuration

Edit `.env` file to customize settings:

```env
# API Settings
HOST=0.0.0.0
PORT=8000
DEBUG=True

# Model Settings
POSE_MODEL_PATH=data/models/pose_model.pt
CONFIDENCE_THRESHOLD=0.5

# Processing
MAX_UPLOAD_SIZE=10485760  # 10MB
```

## Deployment

### Production Considerations

1. **Set DEBUG=False** in production
2. **Use proper CORS settings** - Update `ALLOWED_ORIGINS` in config
3. **Add authentication** if needed
4. **Set up logging** and monitoring
5. **Use HTTPS** in production
6. **Scale with workers**: `uvicorn app.main:app --workers 4`
7. **Consider GPU support** for ML models

### Docker Production

```dockerfile
# Use multi-stage build for smaller images
# Add GPU support if needed
# Use gunicorn/uvicorn workers
```

## Troubleshooting

### Common Issues

**Port already in use**
```bash
# Kill process on port 8000
lsof -ti:8000 | xargs kill -9
```

**Import errors**
```bash
# Ensure you're in virtual environment
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

**CORS errors from Flutter app**
- Check `ALLOWED_ORIGINS` in config
- Ensure Flutter app uses correct API URL
- For Android emulator, use `http://10.0.2.2:8000`

## Roadmap

### Completed ✅
- [x] **PyTorch integration** with GPU support
- [x] **Video scraping tool** for data collection
- [x] **PyTorch DataLoader pipeline** for training
- [x] **Frame extraction** from videos
- [x] **Exercise type detection** from metadata
- [x] **Train/val/test splitting**
- [x] FastAPI REST API structure
- [x] Mock implementations for development
- [x] Docker containerization
- [x] Comprehensive documentation

### In Progress 🚧
- [ ] Integrate real pose estimation model (Keypoint R-CNN or custom)
- [ ] Train custom model on scraped workout data
- [ ] Implement actual form analysis algorithms

### Planned 📋
- [ ] Rep counting with temporal models
- [ ] Real-time video streaming with WebSockets
- [ ] User session management
- [ ] Fine-tune models on workout-specific data
- [ ] Add more exercise types (currently supports 8+)
- [ ] Performance optimization and model quantization
- [ ] Active learning for continuous improvement
- [ ] Multi-person pose tracking
- [ ] Mobile model optimization (TorchScript/ONNX)

## Contributing

1. Create a new branch for your feature
2. Make changes and test thoroughly
3. Run code quality checks (black, flake8, mypy)
4. Write/update tests
5. Update documentation
6. Create pull request

## License

[Your License Here]

## Support

For issues and questions, please create an issue in the GitHub repository.
