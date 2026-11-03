import numpy as np
import pytest

from app.ml.exercises import get_exercise, load_builtin_exercises
from app.ml.pipeline import AnalysisPipeline
from tests.ml.synthetic_chain import chain, rep_fractions, sequence_from_frames

SIDE = 0.0
FRONT = 0.6
TUCKED = -120.0
FLARED = -90.0


def bench_frame(elbow_deg, width=SIDE, upper_heading=TUCKED):
    shoulder = np.array([0.0, 0.0])
    hip = np.array([-1.0, 0.0])
    offset = np.array([0.0, width])
    arm = chain(shoulder, heading=upper_heading, lengths=[0.6, 0.6], interior_angles=[elbow_deg], turn=-1.0)
    return {
        "left_hip": hip, "right_hip": hip + offset,
        "left_shoulder": shoulder, "right_shoulder": shoulder + offset,
        "left_elbow": arm[1], "right_elbow": arm[1] + offset,
        "left_wrist": arm[2], "right_wrist": arm[2] + offset,
    }


def bench_sequence(reps=3, top=170.0, bottom=80.0, fps=30.0, width=SIDE, upper_heading=TUCKED):
    angles = top - (top - bottom) * rep_fractions(reps, fps)
    frames = [bench_frame(a, width, upper_heading) for a in angles]
    return sequence_from_frames(frames, fps)


@pytest.fixture(scope="module")
def bench():
    load_builtin_exercises()
    return get_exercise("bench_press")


def faults(result):
    return [{f.fault for f in rep.findings} for rep in result.reps]


def analyze(bench, **kw):
    return AnalysisPipeline(bench).analyze_sequence(bench_sequence(**kw))


def test_registered_and_valid(bench):
    assert "bench_press" in load_builtin_exercises()
    assert set(bench.fault_names) == {r.fault for r in bench.rule_engine.rules}


@pytest.mark.parametrize("width", [SIDE, FRONT])
def test_counts_reps_in_both_views(bench, width):
    assert analyze(bench, width=width).rep_count == 3


@pytest.mark.parametrize("width", [SIDE, FRONT])
def test_clean_bench_press_has_no_findings(bench, width):
    assert faults(analyze(bench, width=width)) == [set()] * 3


def test_shallow_range(bench):
    assert faults(analyze(bench, bottom=120.0)) == [{"shallow_range"}] * 3


def test_incomplete_lockout(bench):
    assert faults(analyze(bench, top=140.0)) == [{"incomplete_lockout"}] * 3


def test_flared_elbows_are_judged_from_the_front(bench):
    assert faults(analyze(bench, width=FRONT, upper_heading=FLARED)) == [{"elbows_flared"}] * 3


def test_flared_elbows_are_not_judged_from_the_side(bench):
    assert all("elbows_flared" not in f for f in faults(analyze(bench, upper_heading=FLARED)))
