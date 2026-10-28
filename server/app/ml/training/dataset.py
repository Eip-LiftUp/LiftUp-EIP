from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Union

import numpy as np

from app.ml.exercises import ExerciseModule
from app.ml.pose import PoseSequence
from app.ml.processing import process_sequence


@dataclass
class LabelledRecording:
    sequence: PoseSequence
    subject_id: str
    rep_labels: List[Dict[str, Optional[int]]]
    recording_id: str = ""


@dataclass
class RepDataset:
    exercise: str
    feature_names: List[str]
    faults: List[str]
    X: np.ndarray
    y: np.ndarray
    groups: np.ndarray
    skipped: List[str] = field(default_factory=list)

    def __len__(self) -> int:
        return self.X.shape[0]

    def labels_for(self, fault: str):
        col = self.y[:, self.faults.index(fault)]
        mask = ~np.isnan(col)
        return self.X[mask], col[mask].astype(int), self.groups[mask]

    def save(self, path: Union[str, Path]) -> None:
        np.savez_compressed(
            path, exercise=self.exercise, feature_names=np.array(self.feature_names),
            faults=np.array(self.faults), X=self.X, y=self.y, groups=self.groups,
        )

    @classmethod
    def load(cls, path: Union[str, Path]) -> "RepDataset":
        data = np.load(path, allow_pickle=False)
        return cls(
            exercise=str(data["exercise"]), feature_names=data["feature_names"].tolist(),
            faults=data["faults"].tolist(), X=data["X"], y=data["y"], groups=data["groups"],
        )


def build_dataset(exercise: ExerciseModule, recordings: Iterable[LabelledRecording]) -> RepDataset:
    names = exercise.features.names
    faults = exercise.fault_names
    rows, labels, groups, skipped = [], [], [], []
    for i, rec in enumerate(recordings):
        rid = rec.recording_id or f"recording_{i}"
        processed = process_sequence(exercise, rec.sequence)
        if len(processed.reps) != len(rec.rep_labels):
            skipped.append(f"{rid}: detected {len(processed.reps)} reps, labelled {len(rec.rep_labels)}")
            continue
        for vector, rep_label in zip(processed.matrix, rec.rep_labels):
            unknown = set(rep_label) - set(faults)
            if unknown:
                raise ValueError(f"{rid}: labels for undeclared faults {sorted(unknown)}")
            rows.append(vector)
            labels.append([np.nan if rep_label.get(f) is None else float(rep_label[f]) for f in faults])
            groups.append(rec.subject_id)
    return RepDataset(
        exercise=exercise.name,
        feature_names=names,
        faults=faults,
        X=np.array(rows, dtype=np.float64).reshape(len(rows), len(names)),
        y=np.array(labels, dtype=np.float64).reshape(len(labels), len(faults)),
        groups=np.array(groups, dtype=str),
        skipped=skipped,
    )
