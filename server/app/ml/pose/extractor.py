from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Union

import numpy as np

from app.ml.pose.sequence import PoseSequence
from app.ml.pose.skeleton import NUM_LANDMARKS, CHANNELS


class PoseExtractor(ABC):
    @abstractmethod
    def extract(self, video_path: Union[str, Path]) -> PoseSequence:
        ...


class MediaPipeExtractor(PoseExtractor):
    def __init__(
        self,
        model_complexity: int = 1,
        min_detection_confidence: float = 0.5,
        min_tracking_confidence: float = 0.5,
    ) -> None:
        self.model_complexity = model_complexity
        self.min_detection_confidence = min_detection_confidence
        self.min_tracking_confidence = min_tracking_confidence

    def extract(self, video_path: Union[str, Path]) -> PoseSequence:
        try:
            import cv2
            import mediapipe as mp
        except ImportError as exc:
            raise RuntimeError(
                "MediaPipeExtractor requires 'mediapipe' and 'opencv-python'"
            ) from exc

        capture = cv2.VideoCapture(str(video_path))
        if not capture.isOpened():
            raise FileNotFoundError(f"Cannot open video '{video_path}'")
        fps = capture.get(cv2.CAP_PROP_FPS) or 30.0

        frames = []
        with mp.solutions.pose.Pose(
            static_image_mode=False,
            model_complexity=self.model_complexity,
            min_detection_confidence=self.min_detection_confidence,
            min_tracking_confidence=self.min_tracking_confidence,
        ) as pose:
            while True:
                ok, frame = capture.read()
                if not ok:
                    break
                result = pose.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
                frames.append(self._to_array(result))
        capture.release()

        if not frames:
            raise ValueError(f"No frames decoded from '{video_path}'")
        return PoseSequence(
            np.stack(frames),
            fps=float(fps),
            metadata={"source": str(video_path), "extractor": "mediapipe"},
        )

    @staticmethod
    def _to_array(result) -> np.ndarray:
        out = np.zeros((NUM_LANDMARKS, len(CHANNELS)))
        if result.pose_landmarks is None:
            return out
        for i, lm in enumerate(result.pose_landmarks.landmark):
            out[i] = (lm.x, lm.y, lm.z, lm.visibility)
        return out
