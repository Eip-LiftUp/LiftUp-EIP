import numpy as np
import pytest

from app.ml.exercises import get_exercise, load_builtin_exercises
from app.ml.exercises.squat import FRONT_VIEW_RATIO
from app.ml.pipeline import AnalysisPipeline
from tests.ml.synthetic import squat_sequence

FRONT = 0.15


@pytest.fixture(scope="module")
def squat():
    load_builtin_exercises()
    return get_exercise("squat")


def faults(result):
    return [{f.fault for f in rep.findings} for rep in result.reps]


def analyze(squat, **kw):
    return AnalysisPipeline(squat).analyze_sequence(squat_sequence(noise=0.001, **kw))


def test_registered_and_valid(squat):
    assert "squat" in load_builtin_exercises()
    assert len(squat.features) == 29
    assert set(squat.fault_names) == {r.fault for r in squat.rule_engine.rules}


def test_view_detection(squat):
    side = analyze(squat, reps=1)
    front = analyze(squat, reps=1, half_width=FRONT)
    assert side.reps[0].features["view_ratio"] < FRONT_VIEW_RATIO
    assert front.reps[0].features["view_ratio"] >= FRONT_VIEW_RATIO


@pytest.mark.parametrize("reps", [1, 3, 5])
def test_counts_reps_both_views(squat, reps):
    assert analyze(squat, reps=reps, seed=reps).rep_count == reps
    assert analyze(squat, reps=reps, seed=reps, half_width=FRONT).rep_count == reps


def test_clean_squat_has_no_findings(squat):
    assert faults(analyze(squat, reps=3, bottom_angle=85)) == [set()] * 3
    assert faults(analyze(squat, reps=3, bottom_angle=85, half_width=FRONT)) == [set()] * 3


def test_side_view_faults(squat):
    assert faults(analyze(squat, reps=2, bottom_angle=125)) == [{"shallow_depth"}] * 2
    assert faults(analyze(squat, reps=2, bottom_angle=85, torso_lean_deg=60)) == [{"excessive_forward_lean"}] * 2
    assert faults(analyze(squat, reps=2, bottom_angle=85, heel_raise=0.03)) == [{"heel_lift"}] * 2


def test_front_view_valgus_is_critical(squat):
    result = analyze(squat, reps=2, bottom_angle=85, half_width=FRONT, knee_valgus=0.1)
    for rep in result.reps:
        valgus = [f for f in rep.findings if f.fault == "knee_valgus"]
        assert valgus and valgus[0].severity.value == "critical"


def test_view_guards_suppress_unreliable_checks(squat):
    assert all("knee_valgus" not in f for f in faults(analyze(squat, reps=1, bottom_angle=85, knee_valgus=0.1)))
    assert all("shallow_depth" not in f for f in faults(analyze(squat, reps=1, bottom_angle=125, half_width=FRONT)))


def test_partial_wobble_not_counted(squat):
    assert analyze(squat, reps=3, bottom_angle=168).rep_count == 0


def test_deep_squat_with_torso_following_shins_is_not_a_lean_fault(squat):
    deep = analyze(squat, reps=2, bottom_angle=50, torso_lean_deg=60, lean_with_depth=True)
    assert faults(deep) == [set()] * 2
    good_morning = analyze(squat, reps=2, bottom_angle=100, torso_lean_deg=75, lean_with_depth=True)
    assert all("excessive_forward_lean" in f for f in faults(good_morning))


def test_occluded_far_foot_does_not_fake_heel_lift(squat):
    from app.ml.pose import LANDMARK_INDEX
    seq = squat_sequence(reps=2, bottom_angle=85, noise=0.001)
    data = seq.landmarks.copy()
    rng = np.random.default_rng(3)
    for name in ("right_heel", "right_foot_index"):
        j = LANDMARK_INDEX[name]
        data[:, j, 3] = 0.55
        data[:, j, 1] += rng.normal(0, 0.02, len(data))
    result = AnalysisPipeline(squat).analyze_sequence(seq.copy_with(data))
    assert all("heel_lift" not in f for f in faults(result))


def test_front_view_pelvis_tilt_is_asymmetry(squat):
    tilted = analyze(squat, reps=2, bottom_angle=85, half_width=FRONT, hip_drop=0.05)
    assert all("asymmetric_depth" in f for f in faults(tilted))
