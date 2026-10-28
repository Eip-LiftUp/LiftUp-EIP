import numpy as np

from app.ml.pose import PoseSequence


def fill_gaps(seq: PoseSequence, min_visibility: float = 0.5) -> PoseSequence:
    data = seq.landmarks.copy()
    frames = np.arange(seq.num_frames)
    for j in range(data.shape[1]):
        valid = data[:, j, 3] >= min_visibility
        if valid.all() or not valid.any():
            continue
        for c in range(3):
            data[~valid, j, c] = np.interp(frames[~valid], frames[valid], data[valid, j, c])
    return seq.copy_with(data)


def smooth(seq: PoseSequence, window: int = 5) -> PoseSequence:
    if window < 1 or window % 2 == 0:
        raise ValueError("window must be a positive odd integer")
    if window == 1 or seq.num_frames < window:
        return seq.copy_with(seq.landmarks.copy())
    data = seq.landmarks.copy()
    half = window // 2
    padded = np.pad(data[:, :, :3], ((half, half), (0, 0), (0, 0)), mode="edge")
    kernel = np.ones(window) / window
    data[:, :, :3] = np.apply_along_axis(
        lambda s: np.convolve(s, kernel, mode="valid"), 0, padded
    )
    return seq.copy_with(data)
