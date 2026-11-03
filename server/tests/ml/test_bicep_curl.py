import numpy as np
import pytest

from app.ml.exercises import get_exercise, load_builtin_exercises
from app.ml.pipeline import AnalysisPipeline
from tests.ml.synthetic_chain import chain, rep_fractions, sequence_from_frames

SIDE = 0.0
FRONT = 0.6


def curl_frame(elbow_deg, swing=0.0, lean=0.0, width=SIDE):
    hip = np.array([0.0, -1.0])
    shoulder = hip + np.array([np.sin(np.radians(lean)), -np.cos(np.radians(lean))])
    offset = np.array([width, 0.0])
    left = chain(shoulder, heading=90.0 - swing, lengths=[0.6, 0.6], interior_angles=[elbow_deg], turn=-1.0)
    right = chain(shoulder + offset, heading=90.0 - swing, lengths=[0.6, 0.6], interior_angles=[elbow_deg], turn=-1.0)
    return {
        "left_hip": hip, "right_hip": hip + offset,
        "left_shoulder": shoulder, "right_shoulder": shoulder + offset,
        "left_elbow": left[1], "left_wrist": left[2],
        "right_elbow": right[1], "right_wrist": right[2],
    }


def curl_sequence(reps=3, extended=170.0, curled=40.0, fps=30.0, **kw):
    angles = extended - (extended - curled) * rep_fractions(reps, fps)
    return sequence_from_frames([curl_frame(a, **kw) for a in angles], fps)


@pytest.fixture(scope="module")
def curl():
    load_builtin_exercises()
    return get_exercise("bicep_curl")


def faults(result):
    return [{f.fault for f in rep.findings} for rep in result.reps]


def analyze(curl, **kw):
    return AnalysisPipeline(curl).analyze_sequence(curl_sequence(**kw))


def test_registered_and_valid(curl):
    assert "bicep_curl" in load_builtin_exercises()
    assert set(curl.fault_names) == {r.fault for r in curl.rule_engine.rules}


@pytest.mark.parametrize("width", [SIDE, FRONT])
def test_counts_reps_in_both_views(curl, width):
    assert analyze(curl, width=width).rep_count == 3


@pytest.mark.parametrize("width", [SIDE, FRONT])
def test_clean_curl_has_no_findings(curl, width):
    assert faults(analyze(curl, width=width)) == [set()] * 3


def test_incomplete_curl(curl):
    assert faults(analyze(curl, curled=80.0)) == [{"incomplete_curl"}] * 3


def test_incomplete_extension(curl):
    assert faults(analyze(curl, extended=130.0)) == [{"incomplete_extension"}] * 3


def test_elbow_swing_from_the_side(curl):
    assert faults(analyze(curl, swing=50.0)) == [{"elbow_swing"}] * 3


def test_elbow_swing_is_not_judged_from_the_front(curl):
    assert all("elbow_swing" not in f for f in faults(analyze(curl, swing=50.0, width=FRONT)))


def test_body_swing(curl):
    assert faults(analyze(curl, lean=20.0)) == [{"body_swing"}] * 3
