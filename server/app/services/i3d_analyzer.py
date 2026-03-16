"""
I3D (Inflated 3D CNN) Video Analysis Service

Analyzes workout videos using I3D architecture to provide:
- Movement quality scores
- Form feedback and corrections
- Action recognition for exercises

Based on "Quo Vadis, Action Recognition? A New Model and the Kinetics Dataset"
https://arxiv.org/abs/1705.07750
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import cv2
import numpy as np
from typing import Dict, Any, List, Optional, Tuple
from pathlib import Path
import tempfile
import os
from datetime import datetime
import uuid

from app.core.config import settings


class I3DBlock(nn.Module):
    """
    Inflated 3D Convolutional Block
    
    Inflates 2D convolutions to 3D by adding temporal dimension
    """
    
    def __init__(
        self,
        in_channels: int,
        out_channels: int,
        kernel_size: Tuple[int, int, int] = (3, 3, 3),
        stride: Tuple[int, int, int] = (1, 1, 1),
        padding: Tuple[int, int, int] = (1, 1, 1),
        use_bn: bool = True,
        use_relu: bool = True
    ):
        super().__init__()
        self.conv = nn.Conv3d(
            in_channels, out_channels, 
            kernel_size=kernel_size,
            stride=stride,
            padding=padding,
            bias=not use_bn
        )
        self.bn = nn.BatchNorm3d(out_channels) if use_bn else nn.Identity()
        self.relu = nn.ReLU(inplace=True) if use_relu else nn.Identity()
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.conv(x)
        x = self.bn(x)
        x = self.relu(x)
        return x


class I3DInceptionModule(nn.Module):
    """
    Inflated Inception Module for I3D
    
    Multi-scale feature extraction with 1x1, 3x3, and 5x5 convolutions
    """
    
    def __init__(
        self,
        in_channels: int,
        out_1x1: int,
        reduce_3x3: int,
        out_3x3: int,
        reduce_5x5: int,
        out_5x5: int,
        out_pool: int
    ):
        super().__init__()
        
        # 1x1 branch
        self.branch1 = I3DBlock(in_channels, out_1x1, kernel_size=(1, 1, 1), padding=(0, 0, 0))
        
        # 3x3 branch
        self.branch2 = nn.Sequential(
            I3DBlock(in_channels, reduce_3x3, kernel_size=(1, 1, 1), padding=(0, 0, 0)),
            I3DBlock(reduce_3x3, out_3x3, kernel_size=(3, 3, 3), padding=(1, 1, 1))
        )
        
        # 5x5 branch (using two 3x3 for efficiency)
        self.branch3 = nn.Sequential(
            I3DBlock(in_channels, reduce_5x5, kernel_size=(1, 1, 1), padding=(0, 0, 0)),
            I3DBlock(reduce_5x5, out_5x5, kernel_size=(3, 3, 3), padding=(1, 1, 1))
        )
        
        # Pool branch
        self.branch4 = nn.Sequential(
            nn.MaxPool3d(kernel_size=(3, 3, 3), stride=(1, 1, 1), padding=(1, 1, 1)),
            I3DBlock(in_channels, out_pool, kernel_size=(1, 1, 1), padding=(0, 0, 0))
        )
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        b1 = self.branch1(x)
        b2 = self.branch2(x)
        b3 = self.branch3(x)
        b4 = self.branch4(x)
        return torch.cat([b1, b2, b3, b4], dim=1)


class I3DModel(nn.Module):
    """
    I3D (Inflated 3D ConvNet) for action recognition and quality assessment
    
    Architecture:
    - Inflated Inception modules (from Inception-V1)
    - RGB stream input
    - Quality score and action classification heads
    """
    
    def __init__(
        self,
        num_classes: int = 10,  # Number of exercise types
        dropout_prob: float = 0.5,
        input_frames: int = 64,
        input_height: int = 224,
        input_width: int = 224
    ):
        super().__init__()
        
        self.num_classes = num_classes
        self.input_frames = input_frames
        self.input_height = input_height
        self.input_width = input_width
        
        # Initial convolutions
        self.conv1 = I3DBlock(3, 64, kernel_size=(7, 7, 7), stride=(2, 2, 2), padding=(3, 3, 3))
        self.pool1 = nn.MaxPool3d(kernel_size=(1, 3, 3), stride=(1, 2, 2), padding=(0, 1, 1))
        
        self.conv2 = I3DBlock(64, 64, kernel_size=(1, 1, 1), padding=(0, 0, 0))
        self.conv3 = I3DBlock(64, 192, kernel_size=(3, 3, 3), padding=(1, 1, 1))
        self.pool2 = nn.MaxPool3d(kernel_size=(1, 3, 3), stride=(1, 2, 2), padding=(0, 1, 1))
        
        # Inception modules
        self.inception3a = I3DInceptionModule(192, 64, 96, 128, 16, 32, 32)
        self.inception3b = I3DInceptionModule(256, 128, 128, 192, 32, 96, 64)
        self.pool3 = nn.MaxPool3d(kernel_size=(3, 3, 3), stride=(2, 2, 2), padding=(1, 1, 1))
        
        self.inception4a = I3DInceptionModule(480, 192, 96, 208, 16, 48, 64)
        self.inception4b = I3DInceptionModule(512, 160, 112, 224, 24, 64, 64)
        self.inception4c = I3DInceptionModule(512, 128, 128, 256, 24, 64, 64)
        self.inception4d = I3DInceptionModule(512, 112, 144, 288, 32, 64, 64)
        self.inception4e = I3DInceptionModule(528, 256, 160, 320, 32, 128, 128)
        self.pool4 = nn.MaxPool3d(kernel_size=(2, 2, 2), stride=(2, 2, 2), padding=(0, 0, 0))
        
        self.inception5a = I3DInceptionModule(832, 256, 160, 320, 32, 128, 128)
        self.inception5b = I3DInceptionModule(832, 384, 192, 384, 48, 128, 128)
        
        # Global average pooling
        self.avg_pool = nn.AdaptiveAvgPool3d((1, 1, 1))
        self.dropout = nn.Dropout(dropout_prob)
        
        # Classification head (exercise type)
        self.action_classifier = nn.Linear(1024, num_classes)
        
        # Quality assessment head (0-100 score)
        self.quality_head = nn.Sequential(
            nn.Linear(1024, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(256, 64),
            nn.ReLU(inplace=True),
            nn.Linear(64, 1),
            nn.Sigmoid()  # Output in [0, 1], multiply by 100 for score
        )
        
        # Form feedback head (multi-label for different aspects)
        self.form_aspects = [
            "depth", "alignment", "stability", "tempo", "range_of_motion"
        ]
        self.form_head = nn.Sequential(
            nn.Linear(1024, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(256, len(self.form_aspects)),
            nn.Sigmoid()
        )
        
        self._initialize_weights()
    
    def _initialize_weights(self):
        """Initialize weights using He initialization"""
        for m in self.modules():
            if isinstance(m, nn.Conv3d):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm3d):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.Linear):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                nn.init.constant_(m.bias, 0)
    
    def forward(self, x: torch.Tensor) -> Dict[str, torch.Tensor]:
        """
        Forward pass
        
        Args:
            x: Input tensor of shape (B, C, T, H, W)
               B = batch size
               C = channels (3 for RGB)
               T = temporal frames
               H, W = spatial dimensions
        
        Returns:
            Dictionary with action logits, quality score, and form scores
        """
        # Initial convolutions
        x = self.conv1(x)
        x = self.pool1(x)
        x = self.conv2(x)
        x = self.conv3(x)
        x = self.pool2(x)
        
        # Inception modules
        x = self.inception3a(x)
        x = self.inception3b(x)
        x = self.pool3(x)
        
        x = self.inception4a(x)
        x = self.inception4b(x)
        x = self.inception4c(x)
        x = self.inception4d(x)
        x = self.inception4e(x)
        x = self.pool4(x)
        
        x = self.inception5a(x)
        x = self.inception5b(x)
        
        # Global pooling
        x = self.avg_pool(x)
        x = x.view(x.size(0), -1)
        x = self.dropout(x)
        
        # Outputs
        action_logits = self.action_classifier(x)
        quality_score = self.quality_head(x) * 100  # Scale to 0-100
        form_scores = self.form_head(x) * 100  # Scale to 0-100
        
        return {
            "action_logits": action_logits,
            "quality_score": quality_score,
            "form_scores": form_scores
        }


class I3DVideoAnalyzer:
    """
    High-level service for analyzing workout videos using I3D
    
    Handles:
    - Video loading and preprocessing
    - Frame sampling and normalization
    - Model inference
    - Result post-processing and feedback generation
    """
    
    # Supported exercise types
    EXERCISE_CLASSES = [
        "squat", "deadlift", "bench_press", "shoulder_press",
        "bicep_curl", "lunge", "plank", "pushup", "pull_up", "row"
    ]
    
    # Form aspects analyzed
    FORM_ASPECTS = ["depth", "alignment", "stability", "tempo", "range_of_motion"]
    
    # Feedback templates based on scores
    FEEDBACK_TEMPLATES = {
        "depth": {
            "high": "Excellent depth on your movement! You're hitting full range.",
            "medium": "Try to go a bit deeper to maximize muscle engagement.",
            "low": "Focus on increasing your depth gradually for better results."
        },
        "alignment": {
            "high": "Great body alignment throughout the movement!",
            "medium": "Watch your posture - keep your spine neutral and core engaged.",
            "low": "Body alignment needs work. Consider using a mirror to check form."
        },
        "stability": {
            "high": "Very stable and controlled movement. Keep it up!",
            "medium": "Some wobbling detected. Focus on engaging your core.",
            "low": "Stability is an issue. Try reducing weight and focusing on control."
        },
        "tempo": {
            "high": "Perfect tempo! Controlled and consistent throughout.",
            "medium": "Try to maintain a more consistent speed during the movement.",
            "low": "Slow down and focus on a controlled 2-1-2 tempo (down-pause-up)."
        },
        "range_of_motion": {
            "high": "Full range of motion achieved. Excellent work!",
            "medium": "You can extend your range of motion for better muscle activation.",
            "low": "Work on flexibility to improve your range of motion."
        }
    }
    
    def __init__(
        self,
        model_path: Optional[str] = None,
        device: Optional[str] = None,
        num_frames: int = 64,
        frame_height: int = 224,
        frame_width: int = 224
    ):
        """
        Initialize the I3D Video Analyzer
        
        Args:
            model_path: Path to pretrained model weights (optional)
            device: Device to run inference on ('cuda' or 'cpu')
            num_frames: Number of frames to sample from video
            frame_height: Height to resize frames to
            frame_width: Width to resize frames to
        """
        self.num_frames = num_frames
        self.frame_height = frame_height
        self.frame_width = frame_width
        
        # Set device
        if device is None:
            self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        else:
            self.device = torch.device(device)
        
        print(f"[I3D] Using device: {self.device}")
        
        # Initialize model
        self.model = I3DModel(
            num_classes=len(self.EXERCISE_CLASSES),
            input_frames=num_frames,
            input_height=frame_height,
            input_width=frame_width
        ).to(self.device)
        
        # Load pretrained weights if available
        if model_path and os.path.exists(model_path):
            print(f"[I3D] Loading weights from: {model_path}")
            state_dict = torch.load(model_path, map_location=self.device)
            self.model.load_state_dict(state_dict)
        else:
            print("[I3D] No pretrained weights loaded - using random initialization")
            print("[I3D] For production, train on your exercise dataset or use pretrained Kinetics weights")
        
        self.model.eval()
        
        # Normalization parameters (ImageNet mean/std)
        self.mean = torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1, 1).to(self.device)
        self.std = torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1, 1).to(self.device)
    
    def _load_video(self, video_path: str) -> np.ndarray:
        """
        Load video and extract frames
        
        Args:
            video_path: Path to video file
            
        Returns:
            NumPy array of shape (T, H, W, C)
        """
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            raise ValueError(f"Could not open video: {video_path}")
        
        frames = []
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        
        # Calculate frame indices to sample
        if total_frames <= self.num_frames:
            # If video has fewer frames than needed, use all and pad
            indices = list(range(total_frames))
        else:
            # Sample uniformly across the video
            indices = np.linspace(0, total_frames - 1, self.num_frames, dtype=int)
        
        for idx in indices:
            cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
            ret, frame = cap.read()
            if ret:
                # Convert BGR to RGB
                frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                # Resize
                frame = cv2.resize(frame, (self.frame_width, self.frame_height))
                frames.append(frame)
        
        cap.release()
        
        # Pad if necessary
        while len(frames) < self.num_frames:
            frames.append(frames[-1] if frames else np.zeros((self.frame_height, self.frame_width, 3), dtype=np.uint8))
        
        return np.array(frames[:self.num_frames]), fps, total_frames
    
    def _preprocess(self, frames: np.ndarray) -> torch.Tensor:
        """
        Preprocess frames for model input
        
        Args:
            frames: NumPy array of shape (T, H, W, C)
            
        Returns:
            Tensor of shape (1, C, T, H, W)
        """
        # Convert to float and normalize to [0, 1]
        tensor = torch.from_numpy(frames).float() / 255.0
        
        # Rearrange to (C, T, H, W)
        tensor = tensor.permute(3, 0, 1, 2)
        
        # Add batch dimension
        tensor = tensor.unsqueeze(0).to(self.device)
        
        # Normalize with ImageNet mean/std
        tensor = (tensor - self.mean) / self.std
        
        return tensor
    
    def _generate_feedback(
        self,
        quality_score: float,
        form_scores: Dict[str, float],
        detected_exercise: str
    ) -> List[Dict[str, Any]]:
        """
        Generate detailed feedback based on analysis results
        
        Args:
            quality_score: Overall quality score (0-100)
            form_scores: Dictionary of form aspect scores
            detected_exercise: Detected exercise type
            
        Returns:
            List of feedback comments
        """
        feedback = []
        
        # Overall feedback
        if quality_score >= 80:
            feedback.append({
                "id": str(uuid.uuid4()),
                "type": "positive",
                "category": "overall",
                "text": f"Excellent {detected_exercise} form! Your overall score is {quality_score:.1f}/100.",
                "score": quality_score,
                "severity": 1
            })
        elif quality_score >= 60:
            feedback.append({
                "id": str(uuid.uuid4()),
                "type": "encouragement",
                "category": "overall",
                "text": f"Good {detected_exercise}! Your score is {quality_score:.1f}/100. Some areas to improve.",
                "score": quality_score,
                "severity": 2
            })
        else:
            feedback.append({
                "id": str(uuid.uuid4()),
                "type": "correction",
                "category": "overall",
                "text": f"Your {detected_exercise} needs work. Score: {quality_score:.1f}/100. Focus on the tips below.",
                "score": quality_score,
                "severity": 3
            })
        
        # Aspect-specific feedback
        for aspect, score in form_scores.items():
            if aspect not in self.FEEDBACK_TEMPLATES:
                continue
            
            templates = self.FEEDBACK_TEMPLATES[aspect]
            
            if score >= 80:
                level = "high"
                fb_type = "positive"
                severity = 1
            elif score >= 50:
                level = "medium"
                fb_type = "encouragement"
                severity = 2
            else:
                level = "low"
                fb_type = "correction"
                severity = 3
            
            feedback.append({
                "id": str(uuid.uuid4()),
                "type": fb_type,
                "category": aspect,
                "text": templates[level],
                "score": score,
                "severity": severity
            })
        
        # Sort by severity (most important first)
        feedback.sort(key=lambda x: x["severity"], reverse=True)
        
        return feedback
    
    async def analyze_video(
        self,
        video_path: str,
        exercise_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Analyze a workout video and return quality assessment
        
        Args:
            video_path: Path to the video file
            exercise_type: Optional exercise type hint (if known)
            
        Returns:
            Dictionary containing:
                - quality_score: Overall quality score (0-100)
                - detected_exercise: Detected exercise type
                - form_scores: Scores for each form aspect
                - feedback: List of feedback comments
                - metrics: Additional analysis metrics
        """
        start_time = datetime.utcnow()
        
        # Load and preprocess video
        try:
            frames, fps, total_frames = self._load_video(video_path)
        except Exception as e:
            raise ValueError(f"Failed to load video: {str(e)}")
        
        input_tensor = self._preprocess(frames)
        
        # Run inference
        with torch.no_grad():
            outputs = self.model(input_tensor)
        
        # Extract results
        action_probs = F.softmax(outputs["action_logits"], dim=1)[0]
        quality_score = outputs["quality_score"][0].item()
        form_tensor = outputs["form_scores"][0]
        
        # Get detected exercise
        predicted_class = action_probs.argmax().item()
        detected_exercise = self.EXERCISE_CLASSES[predicted_class]
        confidence = action_probs[predicted_class].item()
        
        # If exercise type was provided, use it but note discrepancy
        if exercise_type and exercise_type.lower() != detected_exercise:
            # Still use user-provided type but flag potential mismatch
            detected_exercise = exercise_type.lower()
        
        # Extract form scores
        form_scores = {
            aspect: form_tensor[i].item()
            for i, aspect in enumerate(self.FORM_ASPECTS)
        }
        
        # Generate feedback
        feedback = self._generate_feedback(quality_score, form_scores, detected_exercise)
        
        # Calculate processing time
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        
        return {
            "analysis_id": str(uuid.uuid4()),
            "timestamp": datetime.utcnow().isoformat(),
            "quality_score": round(quality_score, 2),
            "detected_exercise": detected_exercise,
            "detection_confidence": round(confidence * 100, 2),
            "form_scores": {k: round(v, 2) for k, v in form_scores.items()},
            "feedback": feedback,
            "metrics": {
                "video_fps": fps,
                "total_frames": total_frames,
                "frames_analyzed": self.num_frames,
                "processing_time_seconds": round(processing_time, 3),
                "model_device": str(self.device)
            }
        }
    
    async def analyze_video_bytes(
        self,
        video_bytes: bytes,
        filename: str,
        exercise_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Analyze video from bytes (for API uploads)
        
        Args:
            video_bytes: Video file content as bytes
            filename: Original filename
            exercise_type: Optional exercise type hint
            
        Returns:
            Analysis results dictionary
        """
        # Save to temporary file
        suffix = Path(filename).suffix or ".mp4"
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp_file:
            tmp_file.write(video_bytes)
            tmp_path = tmp_file.name
        
        try:
            # Analyze the video
            result = await self.analyze_video(tmp_path, exercise_type)
            result["original_filename"] = filename
            return result
        finally:
            # Clean up temporary file
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)


# Global analyzer instance (lazy initialization)
_analyzer_instance: Optional[I3DVideoAnalyzer] = None


def get_i3d_analyzer() -> I3DVideoAnalyzer:
    """Get or create the global I3D analyzer instance"""
    global _analyzer_instance
    if _analyzer_instance is None:
        model_path = getattr(settings, 'I3D_MODEL_PATH', None)
        _analyzer_instance = I3DVideoAnalyzer(model_path=model_path)
    return _analyzer_instance
