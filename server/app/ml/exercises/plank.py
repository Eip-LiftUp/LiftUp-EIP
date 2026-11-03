import numpy as np

from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.common import body_line_angle, side_only, torso_tilt, view_ratio
from app.ml.exercises.registry import register_exercise
from app.ml.features import FeatureSet, FeatureSpec, duration_feature, point, signal_features
from app.ml.pose import PoseSequence
from app.ml.rules import Severity, ThresholdRule
from app.ml.segmentation import HoldConfig

BODY = ("left_shoulder", "right_shoulder", "left_hip", "right_hip", "left_ankle", "right_ankle")
ARMS = ("left_shoulder", "right_shoulder", "left_elbow", "right_elbow")
HORIZONTAL_TILT = 60.0
STRAIGHT_BODY = 150.0


def elbow_offset(seq: PoseSequence) -> np.ndarray:
    elbows = (point(seq, "left_elbow")[:, 0] + point(seq, "right_elbow")[:, 0]) / 2.0
    shoulders = (point(seq, "left_shoulder")[:, 0] + point(seq, "right_shoulder")[:, 0]) / 2.0
    return np.abs(elbows - shoulders)


@register_exercise
class Plank(ExerciseModule):
    name = "plank"
    display_name = "Plank"
    hold_config = HoldConfig(min_seconds=5.0, max_gap_seconds=0.5)

    def primary_signal(self, seq: PoseSequence) -> np.ndarray:
        return body_line_angle(seq)

    def hold_mask(self, seq: PoseSequence) -> np.ndarray:
        return (body_line_angle(seq) > STRAIGHT_BODY) & (torso_tilt(seq) > HORIZONTAL_TILT)

    def build_features(self) -> FeatureSet:
        return FeatureSet(
            signal_features("body_line", body_line_angle, stats=("min", "mean", "std"))
            + signal_features("elbow_offset", elbow_offset, stats=("max",))
            + [FeatureSpec("view_ratio", view_ratio), duration_feature()]
        )

    def build_faults(self):
        return [
            FaultSpec("hips_out_of_line", "Hips sag or pike during the hold.",
                      "Keep your body in one straight line from head to heels.",
                      Severity.WARNING, BODY),
            FaultSpec("elbows_misplaced", "Elbows sit well ahead of or behind the shoulders.",
                      "Place your elbows directly under your shoulders.",
                      Severity.INFO, ARMS),
        ]

    def build_rules(self):
        return [
            side_only(ThresholdRule("hips_out_of_line", "body_line_mean", "<", 165.0,
                                    "Keep your body in one straight line from head to heels.",
                                    Severity.WARNING, BODY)),
            side_only(ThresholdRule("elbows_misplaced", "elbow_offset_max", ">", 0.3,
                                    "Place your elbows directly under your shoulders.",
                                    Severity.INFO, ARMS)),
        ]
