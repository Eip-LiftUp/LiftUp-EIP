import numpy as np

from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.common import elbow_angle, front_only, view_ratio
from app.ml.exercises.registry import register_exercise
from app.ml.features import FeatureSet, FeatureSpec, duration_feature, joint_angle, signal_features
from app.ml.pose import PoseSequence
from app.ml.rules import Severity, ThresholdRule
from app.ml.segmentation import SegmentationConfig

ARMS = ("left_shoulder", "left_elbow", "left_wrist", "right_shoulder", "right_elbow", "right_wrist")
FLARE = ("left_shoulder", "left_elbow", "right_shoulder", "right_elbow")


def elbow_flare(seq: PoseSequence) -> np.ndarray:
    return (joint_angle(seq, "left_hip", "left_shoulder", "left_elbow")
            + joint_angle(seq, "right_hip", "right_shoulder", "right_elbow")) / 2.0


@register_exercise
class BenchPress(ExerciseModule):
    name = "bench_press"
    display_name = "Bench press"
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
            + signal_features("flare", elbow_flare, stats=("max",))
            + [FeatureSpec("view_ratio", view_ratio), duration_feature()]
        )

    def build_faults(self):
        return [
            FaultSpec("shallow_range", "Bar stops well above the chest at the bottom of the rep.",
                      "Lower the bar until it touches your chest.",
                      Severity.WARNING, ARMS),
            FaultSpec("incomplete_lockout", "Arms do not fully straighten at the top.",
                      "Press until your arms are straight at the top.",
                      Severity.INFO, ARMS),
            FaultSpec("elbows_flared", "Elbows point straight out to the sides, away from the torso.",
                      "Tuck your elbows to roughly 45 degrees from your body.",
                      Severity.WARNING, FLARE),
        ]

    def build_rules(self):
        return [
            ThresholdRule("shallow_range", "elbow_min", ">", 100.0,
                          "Lower the bar until it touches your chest.",
                          Severity.WARNING, ARMS),
            ThresholdRule("incomplete_lockout", "elbow_max", "<", 160.0,
                          "Press until your arms are straight at the top.",
                          Severity.INFO, ARMS),
            front_only(ThresholdRule("elbows_flared", "flare_max", ">", 80.0,
                                     "Tuck your elbows to roughly 45 degrees from your body.",
                                     Severity.WARNING, FLARE)),
        ]
