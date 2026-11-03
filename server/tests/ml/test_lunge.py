import numpy as np
import pytest

from app.ml.exercises import get_exercise, load_builtin_exercises
from app.ml.pipeline import AnalysisPipeline
from tests.ml.synthetic_chain import chain, rep_fractions, sequence_from_frames


def lunge_frame(knee_deg, lean=0.0):
    hip = np.array([0.0, -1.0])
    shoulder = hip + np.array([np.sin(np.radians(lean)), -np.cos(np.radians(lean))])
    leg = chain(hip, heading=90.0, lengths=[0.5, 0.5], interior_angles=[knee_deg], turn=-1.0)
    return {
        "left_hip": hip, "right_hip": hip,
        "left_shoulder": shoulder, "right_shoulder": shoulder,
        "left_knee": leg[1], "right_knee": leg[1],
        "left_ankle": leg[2], "right_ankle": leg[2],
    }


def lunge_sequence(reps=3, standing=170.0, bottom=90.0, lean=0.0, fps=30.0):
    angles = standing - (standing - bottom) * rep_fractions(reps, fps)
    return sequence_from_frames([lunge_frame(a, lean) for a in angles], fps)


@pytest.fixture(scope="module")
def lunge():
    load_builtin_exercises()
    return get_exercise("lunge")


def faults(result):
    return [{f.fault for f in rep.findings} for rep in result.reps]


def analyze(lunge, **kw):
    return AnalysisPipeline(lunge).analyze_sequence(lunge_sequence(**kw))


def test_registered_and_valid(lunge):
    assert "lunge" in load_builtin_exercises()
    assert set(lunge.fault_names) == {r.fault for r in lunge.rule_engine.rules}


def test_counts_reps(lunge):
    assert analyze(lunge).rep_count == 3


def test_clean_lunge_has_no_findings(lunge):
    assert faults(analyze(lunge)) == [set()] * 3


def test_shallow_depth(lunge):
    assert faults(analyze(lunge, bottom=130.0)) == [{"shallow_depth"}] * 3


def test_torso_lean(lunge):
    assert faults(analyze(lunge, lean=30.0)) == [{"torso_lean"}] * 3
