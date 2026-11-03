from __future__ import annotations

from dataclasses import dataclass
from typing import List, Tuple

import numpy as np

from app.ml.segmentation.reps import Rep


@dataclass(frozen=True)
class HoldConfig:
    min_seconds: float = 5.0
    max_gap_seconds: float = 0.5


def _true_runs(mask: np.ndarray) -> List[Tuple[int, int]]:
    padded = np.concatenate([[False], mask, [False]]).astype(np.int8)
    edges = np.diff(padded)
    starts = np.nonzero(edges == 1)[0]
    ends = np.nonzero(edges == -1)[0]
    return list(zip(starts.tolist(), ends.tolist()))


def _merge_close(runs: List[Tuple[int, int]], max_gap: int) -> List[Tuple[int, int]]:
    merged: List[Tuple[int, int]] = []
    for start, end in runs:
        if merged and start - merged[-1][1] <= max_gap:
            merged[-1] = (merged[-1][0], end)
        else:
            merged.append((start, end))
    return merged


def segment_holds(mask: np.ndarray, fps: float, config: HoldConfig = HoldConfig()) -> List[Rep]:
    mask = np.asarray(mask, dtype=bool)
    if mask.ndim != 1:
        raise ValueError("mask must be 1-D")
    merged = _merge_close(_true_runs(mask), int(config.max_gap_seconds * fps))
    holds: List[Rep] = []
    for start, end in merged:
        if (end - start) / fps >= config.min_seconds:
            holds.append(Rep(index=len(holds), start=start, end=end, extreme=(start + end) // 2))
    return holds
