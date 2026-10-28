from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict

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
