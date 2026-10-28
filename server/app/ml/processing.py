from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List

import numpy as np

from app.ml.exercises import ExerciseModule
from app.ml.pose import PoseSequence
from app.ml.preprocessing import preprocess
from app.ml.segmentation import Rep, segment_reps


@dataclass
class ProcessedRecording:
    sequence: PoseSequence
    signal: np.ndarray
    reps: List[Rep]
    features: List[Dict[str, float]]
    matrix: np.ndarray


def process_sequence(exercise: ExerciseModule, raw: PoseSequence) -> ProcessedRecording:
    seq = preprocess(raw, exercise.preprocess_config)
    signal = np.asarray(exercise.primary_signal(seq), dtype=np.float64)
    reps = segment_reps(signal, seq.fps, exercise.segmentation_config)
    features = [exercise.features.compute(seq.slice(r.start, r.end)) for r in reps]
    names = exercise.features.names
    matrix = np.array([[f[n] for n in names] for f in features], dtype=np.float64).reshape(len(reps), len(names))
    return ProcessedRecording(seq, signal, reps, features, matrix)
