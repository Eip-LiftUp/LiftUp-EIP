import json

import pytest

from app.ml.exercises import register_exercise, unregister_exercise
from app.ml.models import ModelStore, FaultClassifier
from app.ml.pipeline import AnalysisPipeline
from app.ml.pose import PoseExtractor
from app.ml.training import build_dataset, train_exercise
from tests.ml.fake_exercise import FakeSquat
from tests.ml.synthetic import labelled_recordings, squat_sequence


@pytest.fixture(scope="module")
def trained_store(tmp_path_factory):
    register_exercise(FakeSquat)
    ex = FakeSquat()
    store = ModelStore(tmp_path_factory.mktemp("models"))
    train_exercise(ex, build_dataset(ex, labelled_recordings()), store)
    yield store
    unregister_exercise("test_squat")


def test_rules_only_pipeline_counts_and_flags():
    pipe = AnalysisPipeline(FakeSquat())
    result = pipe.analyze_sequence(squat_sequence(reps=3, bottom_angle=125))
    assert result.rep_count == 3 and result.active_models == []
    for rep in result.reps:
        assert [f.fault for f in rep.findings] == ["shallow"]
        assert rep.findings[0].source == "rule"
        assert rep.start_s < rep.end_s


def test_pipeline_with_models_from_store(trained_store):
    pipe = AnalysisPipeline.from_store("test_squat", trained_store)
    assert "forward_lean" in pipe.models
    result = pipe.analyze_sequence(squat_sequence(reps=2, bottom_angle=80, torso_lean_deg=50, seed=42))
    faults = {(f.fault, f.source) for r in result.reps for f in r.findings}
    assert ("forward_lean", "model") in faults
    assert not any(f == "shallow" for f, _ in faults)
    json.dumps(result.to_dict())


def test_rule_and_model_same_fault_are_merged(trained_store):
    pipe = AnalysisPipeline.from_store("test_squat", trained_store)
    if "shallow" not in pipe.models:
        pytest.skip("shallow model not enabled on this synthetic data")
    result = pipe.analyze_sequence(squat_sequence(reps=1, bottom_angle=135, seed=7))
    shallow = [f for f in result.reps[0].findings if f.fault == "shallow"]
    assert len(shallow) == 1 and shallow[0].source == "rule"
    assert "model_probability" in shallow[0].evidence


def test_disabled_models_are_ignored():
    clf = FaultClassifier("forward_lean", FakeSquat().features.names)
    assert AnalysisPipeline(FakeSquat(), {"forward_lean": clf}).models == {}


def test_warnings_for_no_reps_and_missing_person():
    seq = squat_sequence(reps=1)
    data = seq.landmarks.copy()
    data[: int(0.5 * len(data)), :, 3] = 0.0
    result = AnalysisPipeline(FakeSquat()).analyze_sequence(seq.copy_with(data))
    assert any("no person detected" in w for w in result.warnings)
    still = squat_sequence(reps=2, bottom_angle=170)
    assert "no repetitions detected" in AnalysisPipeline(FakeSquat()).analyze_sequence(still).warnings


def test_analyze_video_uses_extractor():
    class FakeExtractor(PoseExtractor):
        def extract(self, video_path):
            return squat_sequence(reps=2)

    assert AnalysisPipeline(FakeSquat(), extractor=FakeExtractor()).analyze_video("x.mp4").rep_count == 2
    with pytest.raises(RuntimeError):
        AnalysisPipeline(FakeSquat()).analyze_video("x.mp4")


@pytest.mark.parametrize("hidden", [None, (11, 12, 23, 24)])
def test_unmeasurable_body_returns_warning_not_crash(hidden):
    seq = squat_sequence(reps=2)
    data = seq.landmarks.copy()
    if hidden is None:
        data[:] = 0.0
    else:
        data[:, list(hidden)] = 0.0
    result = AnalysisPipeline(FakeSquat()).analyze_sequence(seq.copy_with(data))
    assert result.rep_count == 0
    assert any("could not analyse" in w for w in result.warnings)
    json.dumps(result.to_dict())
