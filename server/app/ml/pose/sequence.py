from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, Union

import numpy as np

from app.ml.pose.skeleton import NUM_LANDMARKS, CHANNELS, landmark_index


@dataclass
class PoseSequence:
    landmarks: np.ndarray
    fps: float
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        self.landmarks = np.asarray(self.landmarks, dtype=np.float64)
        expected = (NUM_LANDMARKS, len(CHANNELS))
        if self.landmarks.ndim != 3 or self.landmarks.shape[1:] != expected:
            raise ValueError(
                f"landmarks must have shape (frames, {expected[0]}, {expected[1]}), "
                f"got {self.landmarks.shape}"
            )
        if self.fps <= 0:
            raise ValueError("fps must be positive")

    @property
    def num_frames(self) -> int:
        return self.landmarks.shape[0]

    @property
    def duration_s(self) -> float:
        return self.num_frames / self.fps

    @property
    def detection_rate(self) -> float:
        # Extractors leave the frames without a detected person at zero.
        detected = np.any(self.landmarks != 0, axis=(1, 2))
        return float(detected.mean()) if self.num_frames else 0.0

    def joint(self, name: str) -> np.ndarray:
        return self.landmarks[:, landmark_index(name), :3]

    def visibility(self, name: str) -> np.ndarray:
        return self.landmarks[:, landmark_index(name), 3]

    def slice(self, start: int, end: int) -> "PoseSequence":
        if not 0 <= start < end <= self.num_frames:
            raise IndexError(f"invalid slice [{start}, {end}) for {self.num_frames} frames")
        return PoseSequence(self.landmarks[start:end].copy(), self.fps, dict(self.metadata))

    def copy_with(self, landmarks: np.ndarray) -> "PoseSequence":
        return PoseSequence(landmarks, self.fps, dict(self.metadata))

    def save(self, path: Union[str, Path]) -> Path:
        # float32 halves the file size; MediaPipe outputs carry less precision anyway.
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        np.savez_compressed(
            path,
            landmarks=self.landmarks.astype(np.float32),
            fps=np.float64(self.fps),
            metadata=np.array(json.dumps(self.metadata, default=str)),
        )
        return path

    @classmethod
    def load(cls, path: Union[str, Path]) -> "PoseSequence":
        with np.load(path, allow_pickle=False) as data:
            return cls(data["landmarks"], float(data["fps"]), json.loads(str(data["metadata"])))
