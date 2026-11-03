import numpy as np

from app.ml.segmentation import HoldConfig, segment_holds

FPS = 10.0


def mask_from_runs(length, runs):
    mask = np.zeros(length, dtype=bool)
    for start, end in runs:
        mask[start:end] = True
    return mask


def test_single_long_run_is_one_hold():
    holds = segment_holds(mask_from_runs(200, [(20, 120)]), FPS)
    assert [(h.start, h.end) for h in holds] == [(20, 120)]


def test_short_gap_is_bridged():
    holds = segment_holds(mask_from_runs(100, [(0, 30), (33, 63)]), FPS)
    assert [(h.start, h.end) for h in holds] == [(0, 63)]


def test_long_gap_splits_the_holds_and_both_can_be_too_short():
    assert segment_holds(mask_from_runs(100, [(0, 30), (40, 70)]), FPS) == []


def test_run_shorter_than_minimum_is_dropped():
    assert segment_holds(mask_from_runs(100, [(0, 40)]), FPS) == []


def test_minimum_is_configurable():
    holds = segment_holds(mask_from_runs(100, [(0, 40)]), FPS, HoldConfig(min_seconds=3.0))
    assert len(holds) == 1


def test_empty_mask_has_no_holds():
    assert segment_holds(np.zeros(50, dtype=bool), FPS) == []


def test_indices_are_sequential_and_extreme_lies_inside():
    holds = segment_holds(mask_from_runs(300, [(0, 60), (100, 180)]), FPS)
    assert [h.index for h in holds] == [0, 1]
    for h in holds:
        assert h.start <= h.extreme < h.end
