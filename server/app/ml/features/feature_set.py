from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Dict, Iterable, List, Tuple

import numpy as np

from app.ml.pose import PoseSequence
from app.ml.features.geometry import joint_angle, segment_tilt

SignalFn = Callable[[PoseSequence], np.ndarray]
FeatureFn = Callable[[PoseSequence], float]

STATS = ("min", "max", "mean", "std", "range", "argmin_frac", "argmax_frac")


@dataclass(frozen=True)
class FeatureSpec:
    name: str
    fn: FeatureFn


def summarize(signal: np.ndarray, prefix: str) -> Dict[str, float]:
    n = len(signal)
    denom = max(n - 1, 1)
    return {
        f"{prefix}_min": float(np.min(signal)),
        f"{prefix}_max": float(np.max(signal)),
        f"{prefix}_mean": float(np.mean(signal)),
        f"{prefix}_std": float(np.std(signal)),
        f"{prefix}_range": float(np.ptp(signal)),
        f"{prefix}_argmin_frac": float(np.argmin(signal)) / denom,
        f"{prefix}_argmax_frac": float(np.argmax(signal)) / denom,
    }


def _stat_specs(prefix: str, signal_fn: SignalFn, stats: Iterable[str]) -> List[FeatureSpec]:
    return [
        FeatureSpec(f"{prefix}_{stat}", lambda seq, s=stat: summarize(signal_fn(seq), prefix)[f"{prefix}_{s}"])
        for stat in stats
    ]


def signal_features(prefix: str, signal_fn: SignalFn, stats: Iterable[str] = STATS) -> List[FeatureSpec]:
    return _stat_specs(prefix, signal_fn, stats)


def angle_features(prefix: str, a: str, b: str, c: str, stats: Iterable[str] = STATS) -> List[FeatureSpec]:
    return _stat_specs(prefix, lambda seq: joint_angle(seq, a, b, c), stats)


def tilt_features(prefix: str, lower: str, upper: str, stats: Iterable[str] = STATS) -> List[FeatureSpec]:
    return _stat_specs(prefix, lambda seq: segment_tilt(seq, lower, upper), stats)


def symmetry_feature(name: str, left: Tuple[str, str, str], right: Tuple[str, str, str]) -> FeatureSpec:
    def fn(seq: PoseSequence) -> float:
        return float(np.mean(np.abs(joint_angle(seq, *left) - joint_angle(seq, *right))))
    return FeatureSpec(name, fn)


def duration_feature(name: str = "duration_s") -> FeatureSpec:
    return FeatureSpec(name, lambda seq: seq.duration_s)


class FeatureSet:
    def __init__(self, specs: Iterable[FeatureSpec]) -> None:
        self.specs: List[FeatureSpec] = list(specs)
        names = [s.name for s in self.specs]
        duplicates = {n for n in names if names.count(n) > 1}
        if duplicates:
            raise ValueError(f"duplicate feature names: {sorted(duplicates)}")

    @property
    def names(self) -> List[str]:
        return [s.name for s in self.specs]

    def compute(self, seq: PoseSequence) -> Dict[str, float]:
        return {s.name: float(s.fn(seq)) for s in self.specs}

    def compute_vector(self, seq: PoseSequence) -> np.ndarray:
        values = self.compute(seq)
        return np.array([values[n] for n in self.names], dtype=np.float64)

    def __len__(self) -> int:
        return len(self.specs)

    def __add__(self, other: "FeatureSet") -> "FeatureSet":
        return FeatureSet(self.specs + other.specs)
