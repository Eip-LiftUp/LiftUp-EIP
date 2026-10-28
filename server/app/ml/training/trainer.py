from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Optional

import numpy as np
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import GroupKFold

from app.ml.exercises import ExerciseModule
from app.ml.models import FaultClassifier, ModelStore, DEFAULT_MIN_PRECISION
from app.ml.training.dataset import RepDataset


@dataclass
class FaultReport:
    fault: str
    trained: bool
    enabled: bool = False
    reason: str = ""
    n_samples: int = 0
    n_positive: int = 0
    n_subjects: int = 0
    cv_auc: Optional[float] = None
    metrics: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


def _out_of_fold_proba(X, y, groups, feature_names, fault, n_splits, params) -> np.ndarray:
    proba = np.full(len(y), np.nan)
    for train_idx, test_idx in GroupKFold(n_splits=n_splits).split(X, y, groups):
        if len(np.unique(y[train_idx])) < 2:
            continue
        clf = FaultClassifier(fault, feature_names, params).fit(X[train_idx], y[train_idx])
        proba[test_idx] = clf.predict_proba(X[test_idx])
    return proba


def train_fault(
    dataset: RepDataset,
    fault: str,
    n_splits: int = 5,
    min_precision: float = DEFAULT_MIN_PRECISION,
    min_positives: int = 10,
    params: Optional[Dict[str, Any]] = None,
):
    X, y, groups = dataset.labels_for(fault)
    report = FaultReport(fault, trained=False, n_samples=len(y), n_positive=int(y.sum()),
                         n_subjects=len(set(groups)))
    if report.n_positive < min_positives or len(y) - report.n_positive < min_positives:
        report.reason = f"need at least {min_positives} positive and negative reps"
        return None, report
    if report.n_subjects < 2:
        report.reason = "need at least 2 subjects for grouped cross-validation"
        return None, report

    proba = _out_of_fold_proba(X, y, groups, dataset.feature_names, fault,
                               min(n_splits, report.n_subjects), params)
    scored = ~np.isnan(proba)
    clf = FaultClassifier(fault, dataset.feature_names, params).fit(X, y)
    if len(np.unique(y[scored])) == 2:
        report.cv_auc = float(roc_auc_score(y[scored], proba[scored]))
        clf.calibrate(y[scored], proba[scored], min_precision)
    else:
        clf.calibrate(np.zeros(0), np.zeros(0), min_precision)
    clf.metrics.update({"cv_auc": report.cv_auc, "n_samples": report.n_samples,
                        "n_positive": report.n_positive, "n_subjects": report.n_subjects})
    report.trained = True
    report.enabled = clf.enabled
    report.metrics = dict(clf.metrics)
    if not clf.enabled:
        report.reason = f"precision floor {min_precision} not reached on held-out subjects"
    return clf, report


def train_exercise(
    exercise: ExerciseModule,
    dataset: RepDataset,
    store: Optional[ModelStore] = None,
    **kwargs: Any,
) -> List[FaultReport]:
    if dataset.feature_names != exercise.features.names:
        raise ValueError("dataset features do not match the exercise; rebuild the dataset")
    reports = []
    for fault in exercise.fault_names:
        clf, report = train_fault(dataset, fault, **kwargs)
        if clf is not None and store is not None:
            store.save(exercise.name, clf, extra={"report": report.to_dict()})
        reports.append(report)
    return reports
