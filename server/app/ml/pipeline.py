from __future__ import annotations

from dataclasses import dataclass, field, replace
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

import numpy as np

from app.ml.exercises import ExerciseModule, get_exercise
from app.ml.models import FaultClassifier, FeatureMismatchError, ModelStore
from app.ml.pose import PoseExtractor, PoseSequence
from app.ml.preprocessing import PoseQualityError
from app.ml.processing import process_sequence
from app.ml.rules import Finding

MAX_UNDETECTED_FRACTION = 0.3


@dataclass
class RepResult:
    index: int
    start_s: float
    end_s: float
    features: Dict[str, float]
    findings: List[Finding]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "index": self.index,
            "start_s": self.start_s,
            "end_s": self.end_s,
            "features": self.features,
            "findings": [f.to_dict() for f in self.findings],
        }


@dataclass
class AnalysisResult:
    exercise: str
    duration_s: float
    reps: List[RepResult]
    warnings: List[str] = field(default_factory=list)
    active_models: List[str] = field(default_factory=list)

    @property
    def rep_count(self) -> int:
        return len(self.reps)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "exercise": self.exercise,
            "duration_s": self.duration_s,
            "rep_count": self.rep_count,
            "reps": [r.to_dict() for r in self.reps],
            "warnings": self.warnings,
            "active_models": self.active_models,
        }


class AnalysisPipeline:
    def __init__(
        self,
        exercise: ExerciseModule,
        models: Optional[Dict[str, FaultClassifier]] = None,
        extractor: Optional[PoseExtractor] = None,
        warnings: Optional[List[str]] = None,
    ) -> None:
        self.exercise = exercise
        self.models = {f: m for f, m in (models or {}).items() if m.enabled}
        self.extractor = extractor
        self._load_warnings = list(warnings or [])

    @classmethod
    def from_store(
        cls,
        exercise_name: str,
        store: Union[ModelStore, str, Path],
        extractor: Optional[PoseExtractor] = None,
    ) -> "AnalysisPipeline":
        exercise = get_exercise(exercise_name)
        store = store if isinstance(store, ModelStore) else ModelStore(store)
        models, warnings = {}, []
        for fault in exercise.fault_names:
            try:
                clf = store.load(exercise.name, fault, exercise.features.names)
            except FeatureMismatchError as exc:
                warnings.append(str(exc))
                continue
            if clf is not None:
                models[fault] = clf
        return cls(exercise, models, extractor, warnings)

    def analyze_video(self, video_path: Union[str, Path]) -> AnalysisResult:
        if self.extractor is None:
            raise RuntimeError("no PoseExtractor configured for video analysis")
        return self.analyze_sequence(self.extractor.extract(video_path))

    def analyze_sequence(self, raw: PoseSequence) -> AnalysisResult:
        warnings = list(self._load_warnings)
        undetected = float(np.mean(raw.landmarks[:, :, 3].max(axis=1) < 0.5))
        if undetected > MAX_UNDETECTED_FRACTION:
            warnings.append(f"no person detected in {undetected:.0%} of frames; results may be unreliable")

        try:
            processed = process_sequence(self.exercise, raw)
        except PoseQualityError as exc:
            warnings.append(f"could not analyse the recording: {exc}")
            return AnalysisResult(self.exercise.name, raw.duration_s, [], warnings, sorted(self.models))
        if not processed.reps:
            warnings.append("no repetitions detected")

        model_hits = self._model_findings(processed.matrix)
        reps = []
        for i, rep in enumerate(processed.reps):
            findings = self.exercise.rule_engine.evaluate(processed.features[i], rep.index)
            findings = self._merge(findings, model_hits.get(i, []))
            reps.append(RepResult(
                index=rep.index,
                start_s=rep.start / raw.fps,
                end_s=rep.end / raw.fps,
                features=processed.features[i],
                findings=findings,
            ))
        return AnalysisResult(
            exercise=self.exercise.name,
            duration_s=raw.duration_s,
            reps=reps,
            warnings=warnings,
            active_models=sorted(self.models),
        )

    def _model_findings(self, matrix: np.ndarray) -> Dict[int, List[Finding]]:
        hits: Dict[int, List[Finding]] = {}
        if matrix.shape[0] == 0:
            return hits
        for fault, clf in self.models.items():
            spec = self.exercise.fault(fault)
            proba = clf.predict_proba(matrix)
            for i in np.nonzero(proba >= clf.threshold)[0]:
                hits.setdefault(int(i), []).append(Finding(
                    fault=fault,
                    message=spec.message,
                    severity=spec.severity,
                    source="model",
                    rep_index=int(i),
                    confidence=float(proba[i]),
                    joints=spec.joints,
                    evidence={"probability": float(proba[i]), "threshold": clf.threshold},
                ))
        return hits

    @staticmethod
    def _merge(rule_findings: List[Finding], model_findings: List[Finding]) -> List[Finding]:
        by_fault = {f.fault: f for f in model_findings}
        merged = []
        for f in rule_findings:
            model = by_fault.pop(f.fault, None)
            if model is not None:
                f = replace(f, evidence={**f.evidence, "model_probability": model.confidence})
            merged.append(f)
        return merged + list(by_fault.values())
