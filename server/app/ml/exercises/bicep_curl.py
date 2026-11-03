from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.common import elbow_angle, elbow_swing, side_only, view_ratio
from app.ml.exercises.registry import register_exercise
from app.ml.features import FeatureSet, FeatureSpec, duration_feature, signal_features, tilt_features
from app.ml.rules import Severity, ThresholdRule
from app.ml.segmentation import SegmentationConfig

ARMS = ("left_shoulder", "left_elbow", "left_wrist", "right_shoulder", "right_elbow", "right_wrist")
TORSO = ("left_shoulder", "right_shoulder", "left_hip", "right_hip")


@register_exercise
class BicepCurl(ExerciseModule):
    name = "bicep_curl"
    display_name = "Bicep curl"
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
            + tilt_features("torso", "mid_hip", "mid_shoulder", stats=("max", "range"))
            + signal_features("elbow_swing", elbow_swing, stats=("max",))
            + [FeatureSpec("view_ratio", view_ratio), duration_feature()]
        )

    def build_faults(self):
        return [
            FaultSpec("incomplete_curl", "Weight does not come up far enough at the top.",
                      "Curl all the way up, bringing your hands towards your shoulders.",
                      Severity.WARNING, ARMS),
            FaultSpec("incomplete_extension", "Arms do not fully straighten at the bottom.",
                      "Lower the weight until your arms are fully extended.",
                      Severity.INFO, ARMS),
            FaultSpec("elbow_swing", "Elbows swing forward instead of staying by your sides.",
                      "Keep your elbows pinned to your sides.",
                      Severity.WARNING, ARMS),
            FaultSpec("body_swing", "Torso leans back and forth to lift the weight.",
                      "Keep your torso still and let only the elbows move.",
                      Severity.WARNING, TORSO),
        ]

    def build_rules(self):
        return [
            ThresholdRule("incomplete_curl", "elbow_min", ">", 60.0,
                          "Curl all the way up, bringing your hands towards your shoulders.",
                          Severity.WARNING, ARMS),
            ThresholdRule("incomplete_extension", "elbow_max", "<", 150.0,
                          "Lower the weight until your arms are fully extended.",
                          Severity.INFO, ARMS),
            side_only(ThresholdRule("elbow_swing", "elbow_swing_max", ">", 0.3,
                                    "Keep your elbows pinned to your sides.",
                                    Severity.WARNING, ARMS)),
            ThresholdRule("body_swing", "torso_max", ">", 12.0,
                          "Keep your torso still and let only the elbows move.",
                          Severity.WARNING, TORSO),
        ]
