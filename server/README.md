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
│   │   ├── pose_estimator.py  # Pose estimation service
│   │   └── form_analyzer.py   # Form analysis service
│   ├── utils/              # Utility functions
│   └── main.py             # FastAPI application
├── data/
│   ├── models/             # ML model files
│   └── samples/            # Sample data for testing
├── tests/                  # Unit and integration tests
├── requirements.txt        # Python dependencies
├── Dockerfile              # Docker configuration
└── docker-compose.yml      # Docker Compose setup
```

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

### Current Status
The service uses **mock implementations** for pose estimation and form analysis. These are placeholders that return dummy data for testing the API structure.

### Integrating Real Models

#### Option 1: MediaPipe (Recommended for getting started)

```python
# Install MediaPipe
pip install mediapipe

# Update app/services/pose_estimator.py
import mediapipe as mp

class PoseEstimator:
    def __init__(self):
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=True,
            model_complexity=2,
            min_detection_confidence=0.5
        )
    
    async def estimate_pose(self, image_data: bytes):
        # Implementation in pose_estimator.py file (commented out)
        pass
```

#### Option 2: Custom PyTorch Model

```python
import torch
from torchvision import models

class PoseEstimator:
    def __init__(self):
        self.model = torch.load(settings.POSE_MODEL_PATH)
        self.model.eval()
    
    async def estimate_pose(self, image_data: bytes):
        # Your custom model inference
        pass
```

#### Option 3: MMPose or Other Frameworks

See comments in `app/services/pose_estimator.py` for integration examples.

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

- [ ] Integrate real pose estimation model (MediaPipe/MMPose)
- [ ] Implement actual form analysis algorithms
- [ ] Add video streaming support
- [ ] Implement rep counting
- [ ] Add user session management
- [ ] Create training data collection tools
- [ ] Fine-tune models on workout-specific data
- [ ] Add more exercise types
- [ ] Performance optimization
- [ ] WebSocket support for real-time streaming

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
