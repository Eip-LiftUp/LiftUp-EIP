import numpy as np
import pytest

from app.ml.exercises import get_exercise, load_builtin_exercises
from app.ml.pipeline import AnalysisPipeline
from tests.ml.synthetic_chain import paired, sequence_from_frames

SIDE = 0.0
FRONT = 0.6
FPS = 30.0

STANDING = paired({
    "ankle": (0.0, 0.0), "knee": (0.0, -0.5), "hip": (0.0, -1.0),
    "shoulder": (0.0, -2.0), "elbow": (0.05, -1.5),
})


def plank_frame(sag_deg=0.0, elbow_forward=0.0, width=SIDE):
    hip = np.array([0.9, 0.0])
    shoulder = hip + np.array([np.cos(np.radians(sag_deg)), np.sin(np.radians(sag_deg))])
    return paired({
        "ankle": (0.0, 0.0), "hip": hip, "shoulder": shoulder,
        "elbow": (shoulder[0] + elbow_forward, 0.0),
    }, width=width, axis=1)


def plank_sequence(hold_seconds=12.0, lead_seconds=2.0, **kw):
    lead = [STANDING] * int(lead_seconds * FPS)
    hold = [plank_frame(**kw)] * int(hold_seconds * FPS)
    return sequence_from_frames(lead + hold + lead, FPS)


@pytest.fixture(scope="module")
def plank():
    load_builtin_exercises()
    return get_exercise("plank")


def analyze(plank, seq):
    return AnalysisPipeline(plank).analyze_sequence(seq)


def faults(result):
    return [{f.fault for f in hold.findings} for hold in result.reps]


def test_registered_and_valid(plank):
    assert "plank" in load_builtin_exercises()
    assert plank.hold_config is not None
    assert set(plank.fault_names) == {r.fault for r in plank.rule_engine.rules}


def test_one_hold_with_its_duration(plank):
    result = analyze(plank, plank_sequence(hold_seconds=12.0))
    assert result.rep_count == 1
    assert result.reps[0].features["duration_s"] == pytest.approx(12.0, abs=0.5)


def test_short_hold_is_not_counted(plank):
    assert analyze(plank, plank_sequence(hold_seconds=2.0)).rep_count == 0


def test_standing_is_not_a_hold(plank):
    seq = sequence_from_frames([STANDING] * int(10 * FPS), FPS)
    assert analyze(plank, seq).rep_count == 0


def test_clean_plank_has_no_findings(plank):
    assert faults(analyze(plank, plank_sequence())) == [set()]


def test_sagging_hips(plank):
    assert faults(analyze(plank, plank_sequence(sag_deg=25.0))) == [{"hips_out_of_line"}]


def test_piking_hips(plank):
    assert faults(analyze(plank, plank_sequence(sag_deg=-25.0))) == [{"hips_out_of_line"}]


def test_elbows_ahead_of_shoulders(plank):
    assert faults(analyze(plank, plank_sequence(elbow_forward=0.5))) == [{"elbows_misplaced"}]


def test_hips_are_not_judged_from_the_front(plank):
    result = analyze(plank, plank_sequence(sag_deg=25.0, width=FRONT))
    assert result.rep_count == 1
    assert all("hips_out_of_line" not in f for f in faults(result))
