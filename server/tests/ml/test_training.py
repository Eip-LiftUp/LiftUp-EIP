import numpy as np
import pytest

from app.ml.models import ModelStore
from app.ml.processing import process_sequence
from app.ml.training import LabelledRecording, RepDataset, build_dataset, train_fault, train_exercise
from tests.ml.fake_exercise import FakeSquat
from tests.ml.synthetic import labelled_recordings, squat_sequence


@pytest.fixture(scope="module")
def exercise():
    return FakeSquat()


@pytest.fixture(scope="module")
def dataset(exercise):
    return build_dataset(exercise, labelled_recordings())


def test_process_sequence_shapes(exercise):
    out = process_sequence(exercise, squat_sequence(reps=3))
    assert len(out.reps) == 3
    assert out.matrix.shape == (3, len(exercise.features))
    assert out.signal.shape == (out.sequence.num_frames,)


def test_build_dataset(dataset, exercise):
    assert len(dataset) == 6 * 4 * 3
    assert dataset.feature_names == exercise.features.names
    assert dataset.y.shape == (len(dataset), 2)
    assert set(dataset.groups) == {f"subject_{i}" for i in range(6)}


def test_build_dataset_skips_mismatch_and_handles_missing_labels(exercise):
    recs = [
        LabelledRecording(squat_sequence(reps=3), "a", [{"shallow": 0}] * 2, "wrong_count"),
        LabelledRecording(squat_sequence(reps=2), "a", [{"shallow": 1}, {}], "partial"),
    ]
    ds = build_dataset(exercise, recs)
    assert len(ds) == 2 and ds.skipped[0].startswith("wrong_count")
    X, y, g = ds.labels_for("shallow")
    assert y.tolist() == [1] and X.shape == (1, len(exercise.features))
    assert np.isnan(ds.y[:, ds.faults.index("forward_lean")]).all()
    with pytest.raises(ValueError, match="undeclared"):
        build_dataset(exercise, [LabelledRecording(squat_sequence(reps=1), "a", [{"bogus": 1}])])


def test_dataset_save_load(dataset, tmp_path):
    path = tmp_path / "ds.npz"
    dataset.save(path)
    loaded = RepDataset.load(path)
    assert loaded.feature_names == dataset.feature_names
    assert np.allclose(loaded.X, dataset.X) and (loaded.groups == dataset.groups).all()


def test_train_fault_learns_separable_fault(dataset):
    clf, report = train_fault(dataset, "forward_lean")
    assert report.trained and report.enabled, report.reason
    assert report.cv_auc > 0.9
    assert clf.metrics["precision"] >= 0.8


def test_train_fault_refuses_tiny_data(dataset):
    clf, report = train_fault(dataset, "shallow", min_positives=10_000)
    assert clf is None and not report.trained and "at least" in report.reason


def test_train_exercise_saves_models(exercise, dataset, tmp_path):
    store = ModelStore(tmp_path)
    reports = train_exercise(exercise, dataset, store)
    assert [r.fault for r in reports] == exercise.fault_names
    assert store.metadata("test_squat", "forward_lean")["report"]["enabled"]
    assert set(store.load_all("test_squat", exercise.fault_names, exercise.features.names)) == {
        r.fault for r in reports if r.trained
    }
