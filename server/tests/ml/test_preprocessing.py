import numpy as np
import pytest

from app.ml.pose import LANDMARK_INDEX
from app.ml.preprocessing import fill_gaps, smooth, normalize, torso_length, preprocess, PreprocessConfig
from tests.ml.synthetic import squat_sequence


def test_fill_gaps_interpolates_hidden_frames():
    seq = squat_sequence(reps=1)
    knee = LANDMARK_INDEX["left_knee"]
    original = seq.landmarks[20, knee, :3].copy()
    broken = seq.landmarks.copy()
    broken[20, knee] = (0, 0, 0, 0.0)
    filled = fill_gaps(seq.copy_with(broken))
    assert np.allclose(filled.landmarks[20, knee, :3], original, atol=0.01)


def test_fill_gaps_leaves_never_visible_landmark():
    seq = squat_sequence(reps=1)
    data = seq.landmarks.copy()
    data[:, 0, 3] = 0.0
    out = fill_gaps(seq.copy_with(data))
    assert np.array_equal(out.landmarks[:, 0], data[:, 0])


def test_smooth_reduces_noise_and_validates_window():
    clean = squat_sequence(reps=1)
    noisy = squat_sequence(reps=1, noise=0.01)
    before = np.abs(noisy.landmarks[:, :, :2] - clean.landmarks[:, :, :2]).mean()
    after = np.abs(smooth(noisy, 7).landmarks[:, :, :2] - clean.landmarks[:, :, :2]).mean()
    assert after < before
    with pytest.raises(ValueError):
        smooth(clean, 4)


def test_normalize_centers_hips_and_scales_torso():
    seq = normalize(squat_sequence(reps=1))
    hips = (seq.joint("left_hip") + seq.joint("right_hip")) / 2
    assert np.allclose(hips, 0, atol=1e-9)
    assert torso_length(seq) == pytest.approx(1.0)
    assert seq.metadata["normalized"] is True


def test_normalize_is_scale_invariant():
    seq = squat_sequence(reps=1)
    data = seq.landmarks.copy()
    data[:, :, :2] *= 2.0
    a = normalize(seq).landmarks[:, :, :2]
    b = normalize(seq.copy_with(data)).landmarks[:, :, :2]
    assert np.allclose(a, b)


def test_preprocess_chain_without_normalization():
    seq = squat_sequence(reps=1)
    out = preprocess(seq, PreprocessConfig(normalize=False, smoothing_window=1))
    assert np.allclose(out.landmarks, seq.landmarks)
