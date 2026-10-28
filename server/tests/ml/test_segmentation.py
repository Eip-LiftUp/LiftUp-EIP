import numpy as np
import pytest

from app.ml.features import joint_angle
from app.ml.segmentation import segment_reps, SegmentationConfig
from tests.ml.synthetic import squat_sequence


def knee_signal(seq):
    return joint_angle(seq, "left_hip", "left_knee", "left_ankle")


@pytest.mark.parametrize("reps", [1, 3, 5])
def test_counts_reps(reps):
    seq = squat_sequence(reps=reps, noise=0.002, seed=reps)
    found = segment_reps(knee_signal(seq), seq.fps)
    assert len(found) == reps
    assert [r.index for r in found] == list(range(reps))


def test_rep_boundaries_surround_bottom_and_skip_rest():
    seq = squat_sequence(reps=2, rep_seconds=2.0, rest_seconds=1.0, fps=30)
    reps = segment_reps(knee_signal(seq), seq.fps)
    for r in reps:
        assert r.start < r.extreme < r.end
        assert 1.2 <= r.num_frames / seq.fps <= 2.1
    assert reps[0].end <= reps[1].start


def test_small_wobbles_are_not_reps():
    seq = squat_sequence(reps=3, bottom_angle=165.0)
    assert segment_reps(knee_signal(seq), seq.fps) == []


def test_max_direction():
    t = np.linspace(0, 6 * np.pi, 300)
    signal = 10 + 40 * (1 - np.cos(t)) / 2
    reps = segment_reps(signal, 30.0, SegmentationConfig(direction="max", min_prominence=20))
    assert len(reps) == 3


def test_rejects_bad_input():
    with pytest.raises(ValueError):
        segment_reps(np.zeros((3, 3)), 30)
    assert segment_reps(np.array([1.0]), 30) == []
