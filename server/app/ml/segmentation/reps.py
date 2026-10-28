from __future__ import annotations

from dataclasses import dataclass
from typing import List, Literal

import numpy as np
from scipy.signal import find_peaks


@dataclass(frozen=True)
class Rep:
    index: int
    start: int
    end: int
    extreme: int

    @property
    def num_frames(self) -> int:
        return self.end - self.start


@dataclass(frozen=True)
class SegmentationConfig:
    direction: Literal["min", "max"] = "min"
    min_prominence: float = 30.0
    min_rep_seconds: float = 0.4
    max_rep_seconds: float = 10.0
    edge_fraction: float = 0.1


def _edge(signal: np.ndarray, lo: int, hi: int, extreme: int, threshold: float, backwards: bool) -> int:
    if backwards:
        above = np.nonzero(signal[lo:extreme + 1] >= threshold)[0]
        return lo + int(above[-1]) if above.size else lo
    above = np.nonzero(signal[extreme:hi] >= threshold)[0]
    return extreme + int(above[0]) + 1 if above.size else hi


def segment_reps(signal: np.ndarray, fps: float, config: SegmentationConfig = SegmentationConfig()) -> List[Rep]:
    signal = np.asarray(signal, dtype=np.float64)
    if signal.ndim != 1:
        raise ValueError("signal must be 1-D")
    if signal.size < 3:
        return []
    work = -signal if config.direction == "min" else signal
    peaks, props = find_peaks(work, prominence=config.min_prominence,
                              distance=max(1, int(config.min_rep_seconds * fps)))
    oriented = -work
    reps: List[Rep] = []
    for i, p in enumerate(peaks):
        lo = int(peaks[i - 1]) if i > 0 else 0
        hi = int(peaks[i + 1]) + 1 if i + 1 < len(peaks) else signal.size
        top = max(oriented[lo:p + 1].max(), oriented[p:hi].max())
        threshold = top - config.edge_fraction * (top - oriented[p])
        start = _edge(oriented, lo, hi, int(p), threshold, backwards=True)
        end = _edge(oriented, lo, hi, int(p), threshold, backwards=False)
        duration = (end - start) / fps
        if config.min_rep_seconds <= duration <= config.max_rep_seconds:
            reps.append(Rep(index=len(reps), start=start, end=end, extreme=int(p)))
    return reps
