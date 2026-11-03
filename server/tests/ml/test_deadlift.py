import pytest

from app.ml.exercises import get_exercise, load_builtin_exercises
from app.ml.pipeline import AnalysisPipeline
from tests.ml.synthetic_chain import keyframe_sequence, paired

SIDE = 0.0
FRONT = 0.6

STANDING = {
    "ankle": (0.0, 0.0), "knee": (0.0, -0.5), "hip": (0.0, -1.0),
    "shoulder": (0.05, -2.0), "elbow": (0.05, -1.5), "wrist": (0.05, -1.0),
}
HINGED = {
    "ankle": (0.0, 0.0), "knee": (0.2, -0.5), "hip": (-0.5, -0.6),
    "shoulder": (0.25, -0.3), "elbow": (0.25, -0.2), "wrist": (0.25, 0.1),
}
BAR_AWAY = dict(HINGED, elbow=(0.5, -0.2), wrist=(0.6, 0.1))
LOCKOUT = dict(STANDING, shoulder=(0.35, -1.85))


def deadlift_sequence(reps=3, top=STANDING, bottom=HINGED, width=SIDE):
    return keyframe_sequence(paired(top, width), paired(bottom, width), reps, rep_seconds=3.0)


@pytest.fixture(scope="module")
def deadlift():
    load_builtin_exercises()
    return get_exercise("deadlift")


def faults(result):
    return [{f.fault for f in rep.findings} for rep in result.reps]


def analyze(deadlift, **kw):
    return AnalysisPipeline(deadlift).analyze_sequence(deadlift_sequence(**kw))


def test_registered_and_valid(deadlift):
    assert "deadlift" in load_builtin_exercises()
    assert set(deadlift.fault_names) == {r.fault for r in deadlift.rule_engine.rules}


@pytest.mark.parametrize("width", [SIDE, FRONT])
def test_counts_reps_in_both_views(deadlift, width):
    assert analyze(deadlift, width=width).rep_count == 3


@pytest.mark.parametrize("width", [SIDE, FRONT])
def test_clean_deadlift_has_no_findings(deadlift, width):
    assert faults(analyze(deadlift, width=width)) == [set()] * 3


def test_bar_travelling_forward_is_a_fault(deadlift):
    assert faults(analyze(deadlift, bottom=BAR_AWAY)) == [{"bar_away_from_body"}] * 3


def test_bar_offset_is_not_judged_from_the_front(deadlift):
    assert all("bar_away_from_body" not in f for f in faults(analyze(deadlift, bottom=BAR_AWAY, width=FRONT)))


def test_incomplete_lockout(deadlift):
    assert faults(analyze(deadlift, top=LOCKOUT)) == [{"incomplete_lockout"}] * 3
