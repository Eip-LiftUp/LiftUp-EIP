from dataclasses import dataclass

from app.ml.pose import PoseSequence
from app.ml.preprocessing.cleaning import fill_gaps, smooth
from app.ml.preprocessing.normalization import normalize


@dataclass(frozen=True)
class PreprocessConfig:
    min_visibility: float = 0.5
    smoothing_window: int = 5
    normalize: bool = True


def preprocess(seq: PoseSequence, config: PreprocessConfig = PreprocessConfig()) -> PoseSequence:
    out = fill_gaps(seq, config.min_visibility)
    out = smooth(out, config.smoothing_window)
    if config.normalize:
        out = normalize(out)
    return out
