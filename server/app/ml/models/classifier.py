from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence, Tuple

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import precision_recall_curve

DEFAULT_MIN_PRECISION = 0.80

DEFAULT_PARAMS: Dict[str, Any] = {
    "max_iter": 200,
    "learning_rate": 0.05,
    "max_leaf_nodes": 15,
    "min_samples_leaf": 5,
    "l2_regularization": 1.0,
    "class_weight": "balanced",
    "random_state": 0,
}


def choose_threshold(
    y_true: np.ndarray, proba: np.ndarray, min_precision: float = DEFAULT_MIN_PRECISION
) -> Optional[Tuple[float, float, float]]:
    y_true = np.asarray(y_true).astype(int)
    if y_true.sum() == 0:
        return None
    precision, recall, thresholds = precision_recall_curve(y_true, proba)
    precision, recall = precision[:-1], recall[:-1]
    ok = np.nonzero(precision >= min_precision)[0]
    if ok.size == 0:
        return None
    best = ok[np.argmax(recall[ok])]
    return float(thresholds[best]), float(precision[best]), float(recall[best])


class FaultClassifier:
    def __init__(self, fault: str, feature_names: Sequence[str], params: Optional[Dict[str, Any]] = None) -> None:
        self.fault = fault
        self.feature_names: List[str] = list(feature_names)
        self.params = {**DEFAULT_PARAMS, **(params or {})}
        self.model = HistGradientBoostingClassifier(**self.params)
        self.threshold: Optional[float] = None
        self.metrics: Dict[str, Any] = {}
        self.fitted = False

    @property
    def enabled(self) -> bool:
        return self.fitted and self.threshold is not None

    def _check(self, X: np.ndarray) -> np.ndarray:
        X = np.asarray(X, dtype=np.float64)
        if X.ndim != 2 or X.shape[1] != len(self.feature_names):
            raise ValueError(f"expected X with {len(self.feature_names)} columns, got shape {X.shape}")
        return X

    def fit(self, X: np.ndarray, y: np.ndarray) -> "FaultClassifier":
        X = self._check(X)
        y = np.asarray(y).astype(int)
        if len(np.unique(y)) < 2:
            raise ValueError(f"fault '{self.fault}' needs both positive and negative examples")
        self.model.fit(X, y)
        self.fitted = True
        return self

    def calibrate(self, y_true: np.ndarray, proba: np.ndarray, min_precision: float = DEFAULT_MIN_PRECISION) -> None:
        chosen = choose_threshold(y_true, proba, min_precision)
        self.metrics["min_precision"] = min_precision
        if chosen is None:
            self.threshold = None
            self.metrics.update({"threshold": None, "precision": None, "recall": None})
            return
        self.threshold, precision, recall = chosen
        self.metrics.update({"threshold": self.threshold, "precision": precision, "recall": recall})

    def predict_proba(self, X: np.ndarray) -> np.ndarray:
        if not self.fitted:
            raise RuntimeError(f"classifier for '{self.fault}' is not fitted")
        return self.model.predict_proba(self._check(X))[:, 1]

    def predict(self, X: np.ndarray) -> np.ndarray:
        if not self.enabled:
            return np.zeros(len(np.atleast_2d(X)), dtype=bool)
        return self.predict_proba(X) >= self.threshold
