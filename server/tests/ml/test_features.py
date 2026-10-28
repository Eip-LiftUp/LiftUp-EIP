import numpy as np
import pytest

from app.ml.features import (
    angle,
    joint_angle,
    segment_tilt,
    distance,
    point,
    summarize,
    angle_features,
    tilt_features,
    symmetry_feature,
    duration_feature,
    FeatureSet,
    FeatureSpec,
)
from tests.ml.synthetic import squat_sequence, squat_frame
from app.ml.pose import PoseSequence


def test_angle_right_and_straight():
    a = np.array([[1.0, 0.0], [1.0, 0.0]])
    b = np.zeros((2, 2))
    c = np.array([[0.0, 1.0], [-1.0, 0.0]])
    assert np.allclose(angle(a, b, c), [90.0, 180.0])


def test_angle_degenerate_does_not_nan():
    z = np.zeros((1, 2))
    assert np.isfinite(angle(z, z, z)).all()


def test_joint_angle_matches_synthetic_knee_angle():
    seq = PoseSequence(np.stack([squat_frame(90.0), squat_frame(150.0)]), fps=30)
    knee = joint_angle(seq, "left_hip", "left_knee", "left_ankle")
    assert np.allclose(knee, [90.0, 150.0], atol=1e-6)


def test_segment_tilt_and_virtual_points():
    seq = PoseSequence(np.stack([squat_frame(170.0, torso_lean_deg=30.0)]), fps=30)
    assert segment_tilt(seq, "mid_hip", "mid_shoulder")[0] == pytest.approx(30.0, abs=1e-6)
    assert point(seq, "mid_hip").shape == (1, 2)
    assert distance(seq, "left_hip", "left_knee")[0] == pytest.approx(0.2)


def test_summarize_keys_and_values():
    out = summarize(np.array([3.0, 1.0, 2.0]), "x")
    assert out["x_min"] == 1.0 and out["x_range"] == 2.0
    assert out["x_argmin_frac"] == 0.5


def test_feature_set_compute_and_vector_order():
    seq = squat_sequence(reps=1, bottom_angle=85)
    fs = FeatureSet(
        angle_features("knee", "left_hip", "left_knee", "left_ankle", stats=("min", "max"))
        + tilt_features("torso", "mid_hip", "mid_shoulder", stats=("max",))
        + [symmetry_feature("knee_sym", ("left_hip", "left_knee", "left_ankle"),
                            ("right_hip", "right_knee", "right_ankle")), duration_feature()]
    )
    values = fs.compute(seq)
    assert values["knee_min"] == pytest.approx(85, abs=1)
    assert values["knee_sym"] == pytest.approx(0, abs=1e-6)
    vec = fs.compute_vector(seq)
    assert vec.shape == (len(fs),)
    assert vec[fs.names.index("knee_max")] == values["knee_max"]


def test_feature_set_rejects_duplicates_and_concatenates():
    a = FeatureSet([FeatureSpec("a", lambda s: 1.0)])
    b = FeatureSet([FeatureSpec("b", lambda s: 2.0)])
    assert (a + b).names == ["a", "b"]
    with pytest.raises(ValueError):
        a + a
