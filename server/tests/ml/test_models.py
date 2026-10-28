import numpy as np
import pytest

from app.ml.models import FaultClassifier, choose_threshold, ModelStore, FeatureMismatchError


def toy_data(n=200, seed=0):
    rng = np.random.default_rng(seed)
    X = rng.normal(size=(n, 3))
    y = (X[:, 0] + 0.2 * rng.normal(size=n) > 0.5).astype(int)
    return X, y


def test_choose_threshold_meets_precision():
    y = np.array([0, 0, 0, 1, 1, 1])
    p = np.array([0.1, 0.2, 0.6, 0.55, 0.8, 0.9])
    thr, precision, recall = choose_threshold(y, p, 0.8)
    assert precision >= 0.8
    assert thr == pytest.approx(0.8)
    assert choose_threshold(np.zeros(3), np.ones(3)) is None
    assert choose_threshold(np.array([0, 1]), np.array([0.9, 0.1]), 0.99) is None


def test_classifier_fit_calibrate_predict():
    X, y = toy_data()
    clf = FaultClassifier("f", ["a", "b", "c"]).fit(X[:150], y[:150])
    assert not clf.enabled
    assert not clf.predict(X[150:]).any()
    clf.calibrate(y[150:], clf.predict_proba(X[150:]))
    assert clf.enabled and clf.metrics["precision"] >= 0.8
    assert clf.predict(X[150:]).dtype == bool


def test_classifier_input_checks():
    clf = FaultClassifier("f", ["a", "b"])
    with pytest.raises(RuntimeError):
        clf.predict_proba(np.zeros((1, 2)))
    with pytest.raises(ValueError):
        clf.fit(np.zeros((4, 3)), [0, 1, 0, 1])
    with pytest.raises(ValueError):
        clf.fit(np.zeros((4, 2)), [0, 0, 0, 0])


def test_store_roundtrip_and_mismatch(tmp_path):
    X, y = toy_data()
    clf = FaultClassifier("f", ["a", "b", "c"]).fit(X, y)
    clf.calibrate(y, clf.predict_proba(X))
    store = ModelStore(tmp_path)
    store.save("ex", clf, extra={"n_train": 200})
    meta = store.metadata("ex", "f")
    assert meta["feature_names"] == ["a", "b", "c"] and meta["n_train"] == 200 and meta["enabled"]
    assert meta["sklearn_version"]
    loaded = store.load("ex", "f", ["a", "b", "c"])
    assert np.allclose(loaded.predict_proba(X), clf.predict_proba(X))
    assert store.load("ex", "missing") is None
    assert store.metadata("ex", "missing") is None
    with pytest.raises(FeatureMismatchError):
        store.load("ex", "f", ["a", "b"])
    assert list(store.load_all("ex", ["f", "missing"], ["a", "b", "c"])) == ["f"]
