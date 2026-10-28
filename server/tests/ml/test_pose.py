import numpy as np
import pytest

from app.ml.pose import PoseSequence, NUM_LANDMARKS, landmark_index, MediaPipeExtractor
from tests.ml.synthetic import squat_sequence


def test_landmark_index_known_and_unknown():
    assert landmark_index("nose") == 0
    assert landmark_index("right_foot_index") == NUM_LANDMARKS - 1
    with pytest.raises(KeyError):
        landmark_index("tail")


def test_sequence_shape_validation():
    with pytest.raises(ValueError):
        PoseSequence(np.zeros((10, 17, 4)), fps=30)
    with pytest.raises(ValueError):
        PoseSequence(np.zeros((10, NUM_LANDMARKS, 4)), fps=0)


def test_sequence_accessors_and_slice():
    seq = squat_sequence(reps=1, fps=30)
    assert seq.joint("left_knee").shape == (seq.num_frames, 3)
    assert seq.visibility("left_knee").shape == (seq.num_frames,)
    assert seq.duration_s == pytest.approx(seq.num_frames / 30)
    part = seq.slice(5, 15)
    assert part.num_frames == 10
    with pytest.raises(IndexError):
        seq.slice(10, 5)


def test_mediapipe_extractor_missing_file():
    extractor = MediaPipeExtractor()
    with pytest.raises((RuntimeError, FileNotFoundError)):
        extractor.extract("does_not_exist.mp4")
