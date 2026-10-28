import numpy as np

from app.ml.pose import PoseSequence


class PoseQualityError(ValueError):
    pass


def _midpoint(seq: PoseSequence, left: str, right: str) -> np.ndarray:
    return (seq.joint(left) + seq.joint(right)) / 2.0


def torso_length(seq: PoseSequence) -> float:
    shoulders = _midpoint(seq, "left_shoulder", "right_shoulder")[:, :2]
    hips = _midpoint(seq, "left_hip", "right_hip")[:, :2]
    length = float(np.median(np.linalg.norm(shoulders - hips, axis=1)))
    if length <= 1e-6:
        raise PoseQualityError("torso length is zero; shoulders and hips not detected")
    return length


def normalize(seq: PoseSequence) -> PoseSequence:
    data = seq.landmarks.copy()
    center = _midpoint(seq, "left_hip", "right_hip")
    scale = torso_length(seq)
    data[:, :, :3] = (data[:, :, :3] - center[:, None, :]) / scale
    out = seq.copy_with(data)
    out.metadata["normalized"] = True
    out.metadata["torso_length"] = scale
    return out
