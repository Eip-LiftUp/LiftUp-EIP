import numpy as np

from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.common import elbow_angle, view_ratio
from app.ml.exercises.registry import register_exercise
from app.ml.features import FeatureSet, FeatureSpec, duration_feature, joint_angle, signal_features
from app.ml.pose import PoseSequence
from app.ml.rules import Severity, ThresholdRule
from app.ml.segmentation import SegmentationConfig

ARMS = ("left_shoulder", "left_elbow", "left_wrist", "right_shoulder", "right_elbow", "right_wrist")


def elbow_gap(seq: PoseSequence) -> np.ndarray:
    left = joint_angle(seq, "left_shoulder", "left_elbow", "left_wrist")
    right = joint_angle(seq, "right_shoulder", "right_elbow", "right_wrist")
    return np.abs(left - right)


@register_exercise
class ShoulderPress(ExerciseModule):
    name = "shoulder_press"
    display_name = "Shoulder press"
    segmentation_config = SegmentationConfig(
        direction="min",
        min_prominence=40.0,
        min_rep_seconds=0.8,
        max_rep_seconds=10.0,
    )

    def primary_signal(self, seq):
        return elbow_angle(seq)

    def build_features(self) -> FeatureSet:
        return FeatureSet(
            signal_features("elbow", elbow_angle, stats=("min", "max", "range"))
            + signal_features("elbow_gap", elbow_gap, stats=("max",))
            + [FeatureSpec("view_ratio", view_ratio), duration_feature()]
        )

    def build_faults(self):
        return [
            FaultSpec("shallow_start", "Bar is not lowered to shoulder height at the bottom.",
                      "Lower the bar to shoulder height before each press.",
                      Severity.WARNING, ARMS),
            FaultSpec("incomplete_lockout", "Arms do not fully straighten at the top.",
                      "Press until your arms are straight overhead.",
                      Severity.WARNING, ARMS),
            FaultSpec("uneven_press", "One arm presses noticeably higher than the other.",
                      "Press both arms evenly.",
                      Severity.INFO, ARMS),
        ]

    def build_rules(self):
        return [
            ThresholdRule("shallow_start", "elbow_min", ">", 110.0,
                          "Lower the bar to shoulder height before each press.",
                          Severity.WARNING, ARMS),
            ThresholdRule("incomplete_lockout", "elbow_max", "<", 160.0,
                          "Press until your arms are straight overhead.",
                          Severity.WARNING, ARMS),
            ThresholdRule("uneven_press", "elbow_gap_max", ">", 15.0,
                          "Press both arms evenly.",
                          Severity.INFO, ARMS),
        ]
