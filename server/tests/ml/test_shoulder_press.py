import numpy as np
import pytest

from app.ml.exercises import get_exercise, load_builtin_exercises
from app.ml.pipeline import AnalysisPipeline
from tests.ml.synthetic_chain import chain, rep_fractions, sequence_from_frames


def press_frame(left_deg, right_deg, s):
    hip = np.array([0.0, -1.0])
    shoulder = np.array([0.0, -2.0])
    heading = -90.0 * (1 - s)
    left = chain(shoulder, heading=heading, lengths=[0.6, 0.6], interior_angles=[left_deg], turn=-1.0)
    right = chain(shoulder, heading=heading, lengths=[0.6, 0.6], interior_angles=[right_deg], turn=-1.0)
    return {
        "left_hip": hip, "right_hip": hip, "left_shoulder": shoulder, "right_shoulder": shoulder,
        "left_elbow": left[1], "left_wrist": left[2], "right_elbow": right[1], "right_wrist": right[2],
    }


def press_sequence(reps=3, top=170.0, bottom=90.0, right_top=None, fps=30.0):
    right_top = top if right_top is None else right_top
    s = rep_fractions(reps, fps)
    frames = []
    for value in s:
        left = top - (top - bottom) * value
        right = right_top - (right_top - bottom) * value
        frames.append(press_frame(left, right, value))
    return sequence_from_frames(frames, fps)


@pytest.fixture(scope="module")
def press():
    load_builtin_exercises()
    return get_exercise("shoulder_press")


def faults(result):
    return [{f.fault for f in rep.findings} for rep in result.reps]


def analyze(press, **kw):
    return AnalysisPipeline(press).analyze_sequence(press_sequence(**kw))


def test_registered_and_valid(press):
    assert "shoulder_press" in load_builtin_exercises()
    assert set(press.fault_names) == {r.fault for r in press.rule_engine.rules}


def test_counts_reps(press):
    assert analyze(press).rep_count == 3


def test_clean_press_has_no_findings(press):
    assert faults(analyze(press)) == [set()] * 3


def test_shallow_start(press):
    assert faults(analyze(press, bottom=120.0)) == [{"shallow_start"}] * 3


def test_incomplete_lockout(press):
    assert faults(analyze(press, top=140.0)) == [{"incomplete_lockout"}] * 3


def test_uneven_press(press):
    assert faults(analyze(press, top=180.0, right_top=160.0)) == [{"uneven_press"}] * 3
