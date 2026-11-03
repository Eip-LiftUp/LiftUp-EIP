from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.common import body_line_angle, elbow_angle, side_only, view_ratio
from app.ml.exercises.registry import register_exercise
from app.ml.features import FeatureSet, FeatureSpec, duration_feature, signal_features
from app.ml.rules import Severity, ThresholdRule
from app.ml.segmentation import SegmentationConfig

ARMS = ("left_shoulder", "left_elbow", "left_wrist", "right_shoulder", "right_elbow", "right_wrist")
BODY = ("left_shoulder", "right_shoulder", "left_hip", "right_hip", "left_ankle", "right_ankle")


@register_exercise
class PushUp(ExerciseModule):
    name = "pushup"
    display_name = "Push-up"
    segmentation_config = SegmentationConfig(
        direction="min",
        min_prominence=40.0,
        min_rep_seconds=0.6,
        max_rep_seconds=8.0,
    )

    def primary_signal(self, seq):
        return elbow_angle(seq)

    def build_features(self) -> FeatureSet:
        return FeatureSet(
            signal_features("elbow", elbow_angle, stats=("min", "max", "range"))
            + signal_features("body_line", body_line_angle, stats=("min", "mean"))
            + [FeatureSpec("view_ratio", view_ratio), duration_feature()]
        )

    def build_faults(self):
        return [
            FaultSpec("hips_out_of_line", "Hips sag or pike instead of staying in one straight line.",
                      "Keep your body in one straight line from head to heels.",
                      Severity.WARNING, BODY),
            FaultSpec("shallow_depth", "Chest stays high at the bottom of the rep.",
                      "Lower your chest closer to the floor.",
                      Severity.WARNING, ARMS),
            FaultSpec("incomplete_lockout", "Arms do not fully straighten at the top.",
                      "Press all the way up until your arms are straight.",
                      Severity.INFO, ARMS),
        ]

    def build_rules(self):
        return [
            side_only(ThresholdRule("hips_out_of_line", "body_line_min", "<", 160.0,
                                    "Keep your body in one straight line from head to heels.",
                                    Severity.WARNING, BODY)),
            ThresholdRule("shallow_depth", "elbow_min", ">", 100.0,
                          "Lower your chest closer to the floor.",
                          Severity.WARNING, ARMS),
            ThresholdRule("incomplete_lockout", "elbow_max", "<", 160.0,
                          "Press all the way up until your arms are straight.",
                          Severity.INFO, ARMS),
        ]
