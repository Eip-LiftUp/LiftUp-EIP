from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Optional, Sequence, Union

import joblib
import sklearn

from app.ml.models.classifier import FaultClassifier

FORMAT_VERSION = 1


class FeatureMismatchError(ValueError):
    pass


class ModelStore:
    def __init__(self, root: Union[str, Path]) -> None:
        self.root = Path(root)

    def _paths(self, exercise: str, fault: str):
        folder = self.root / exercise
        return folder / f"{fault}.joblib", folder / f"{fault}.json"

    def save(self, exercise: str, clf: FaultClassifier, extra: Optional[Dict] = None) -> Path:
        model_path, meta_path = self._paths(exercise, clf.fault)
        model_path.parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(clf, model_path)
        meta = {
            "format_version": FORMAT_VERSION,
            "sklearn_version": sklearn.__version__,
            "exercise": exercise,
            "fault": clf.fault,
            "feature_names": clf.feature_names,
            "params": clf.params,
            "metrics": clf.metrics,
            "enabled": clf.enabled,
            "saved_at": datetime.now(timezone.utc).isoformat(),
            **(extra or {}),
        }
        meta_path.write_text(json.dumps(meta, indent=2, default=str), encoding="utf-8")
        return model_path

    def metadata(self, exercise: str, fault: str) -> Optional[Dict]:
        _, meta_path = self._paths(exercise, fault)
        if not meta_path.exists():
            return None
        return json.loads(meta_path.read_text(encoding="utf-8"))

    def load(
        self, exercise: str, fault: str, feature_names: Optional[Sequence[str]] = None
    ) -> Optional[FaultClassifier]:
        model_path, _ = self._paths(exercise, fault)
        if not model_path.exists():
            return None
        clf: FaultClassifier = joblib.load(model_path)
        if feature_names is not None and list(feature_names) != clf.feature_names:
            raise FeatureMismatchError(
                f"model '{exercise}/{fault}' was trained on different features; retrain it"
            )
        return clf

    def load_all(
        self, exercise: str, faults: Sequence[str], feature_names: Sequence[str]
    ) -> Dict[str, FaultClassifier]:
        loaded = {}
        for fault in faults:
            clf = self.load(exercise, fault, feature_names)
            if clf is not None:
                loaded[fault] = clf
        return loaded
