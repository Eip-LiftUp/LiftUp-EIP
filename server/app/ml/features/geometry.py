import numpy as np

from app.ml.pose import PoseSequence

VIRTUAL_POINTS = {
    "mid_shoulder": ("left_shoulder", "right_shoulder"),
    "mid_hip": ("left_hip", "right_hip"),
    "mid_knee": ("left_knee", "right_knee"),
    "mid_ankle": ("left_ankle", "right_ankle"),
}


def point(seq: PoseSequence, name: str, dims: int = 2) -> np.ndarray:
    if name in VIRTUAL_POINTS:
        left, right = VIRTUAL_POINTS[name]
        return ((seq.joint(left) + seq.joint(right)) / 2.0)[:, :dims]
    return seq.joint(name)[:, :dims]


def angle(a: np.ndarray, b: np.ndarray, c: np.ndarray) -> np.ndarray:
    v1 = a - b
    v2 = c - b
    norms = np.linalg.norm(v1, axis=-1) * np.linalg.norm(v2, axis=-1)
    cos = np.sum(v1 * v2, axis=-1) / np.maximum(norms, 1e-9)
    return np.degrees(np.arccos(np.clip(cos, -1.0, 1.0)))


def joint_angle(seq: PoseSequence, a: str, b: str, c: str, dims: int = 2) -> np.ndarray:
    return angle(point(seq, a, dims), point(seq, b, dims), point(seq, c, dims))


def segment_tilt(seq: PoseSequence, lower: str, upper: str) -> np.ndarray:
    v = point(seq, upper) - point(seq, lower)
    return np.degrees(np.arctan2(np.abs(v[:, 0]), -v[:, 1]))


def distance(seq: PoseSequence, a: str, b: str, dims: int = 2) -> np.ndarray:
    return np.linalg.norm(point(seq, a, dims) - point(seq, b, dims), axis=-1)
