import numpy as np
import pytest

from app.ml.exercises import get_exercise, load_builtin_exercises
from app.ml.pipeline import AnalysisPipeline
from tests.ml.synthetic_chain import chain, rep_fractions, sequence_from_frames

SIDE = 0.0
FRONT = 0.6


def pushup_frame(elbow_deg, sag_deg=0.0, width=SIDE):
    hip = np.array([0.9, 0.0])
    ankle = np.array([0.0, 0.0])
    shoulder = hip + np.array([np.cos(np.radians(sag_deg)), np.sin(np.radians(sag_deg))])
    arm = chain(shoulder, heading=60, lengths=[0.6, 0.6], interior_angles=[elbow_deg])
    offset = np.array([0.0, width])
    return {
        "left_ankle": ankle, "right_ankle": ankle + offset,
        "left_hip": hip, "right_hip": hip + offset,
        "left_shoulder": shoulder, "right_shoulder": shoulder + offset,
        "left_elbow": arm[1], "right_elbow": arm[1] + offset,
        "left_wrist": arm[2], "right_wrist": arm[2] + offset,
    }


def pushup_sequence(reps=3, top=170.0, bottom=80.0, fps=30.0, sag_deg=0.0, width=SIDE):
    angles = top - (top - bottom) * rep_fractions(reps, fps)
    return sequence_from_frames([pushup_frame(a, sag_deg, width) for a in angles], fps)


@pytest.fixture(scope="module")
def pushup():
    load_builtin_exercises()
    return get_exercise("pushup")


def faults(result):
    return [{f.fault for f in rep.findings} for rep in result.reps]


def analyze(pushup, **kw):
    return AnalysisPipeline(pushup).analyze_sequence(pushup_sequence(**kw))


def test_registered_and_valid(pushup):
    assert "pushup" in load_builtin_exercises()
    assert set(pushup.fault_names) == {r.fault for r in pushup.rule_engine.rules}


@pytest.mark.parametrize("width", [SIDE, FRONT])
def test_counts_reps_in_both_views(pushup, width):
    assert analyze(pushup, reps=3, width=width).rep_count == 3


@pytest.mark.parametrize("width", [SIDE, FRONT])
def test_clean_pushup_has_no_findings(pushup, width):
    assert faults(analyze(pushup, reps=3, width=width)) == [set()] * 3


@pytest.mark.parametrize("sag", [25.0, -25.0])
def test_sagging_or_piked_hips(pushup, sag):
    assert faults(analyze(pushup, reps=2, sag_deg=sag)) == [{"hips_out_of_line"}] * 2


def test_shallow_depth(pushup):
    assert faults(analyze(pushup, reps=2, bottom=120.0)) == [{"shallow_depth"}] * 2


def test_incomplete_lockout(pushup):
    assert faults(analyze(pushup, reps=2, top=140.0)) == [{"incomplete_lockout"}] * 2


def test_body_line_is_not_judged_from_the_front(pushup):
    assert all("hips_out_of_line" not in f for f in faults(analyze(pushup, reps=2, sag_deg=25.0, width=FRONT)))
