from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.common import knee_angle, torso_tilt, view_ratio
from app.ml.exercises.registry import register_exercise
from app.ml.features import FeatureSet, FeatureSpec, duration_feature, signal_features
from app.ml.rules import Severity, ThresholdRule
from app.ml.segmentation import SegmentationConfig

KNEES = ("left_hip", "left_knee", "left_ankle", "right_hip", "right_knee", "right_ankle")
TORSO = ("left_shoulder", "right_shoulder", "left_hip", "right_hip")


@register_exercise
class Lunge(ExerciseModule):
    name = "lunge"
    display_name = "Lunge"
    segmentation_config = SegmentationConfig(
        direction="min",
        min_prominence=25.0,
        min_rep_seconds=0.8,
        max_rep_seconds=10.0,
    )

    def primary_signal(self, seq):
        return knee_angle(seq)

    def build_features(self) -> FeatureSet:
        return FeatureSet(
            signal_features("knee", knee_angle, stats=("min", "max", "range"))
            + signal_features("torso", torso_tilt, stats=("max",))
            + [FeatureSpec("view_ratio", view_ratio), duration_feature()]
        )

    def build_faults(self):
        return [
            FaultSpec("shallow_depth", "Back knee stays high instead of dropping towards the floor.",
                      "Lower your back knee towards the floor.",
                      Severity.WARNING, KNEES),
            FaultSpec("torso_lean", "Torso leans well forward during the lunge.",
                      "Keep your chest up and your torso upright.",
                      Severity.INFO, TORSO),
        ]

    def build_rules(self):
        return [
            ThresholdRule("shallow_depth", "knee_min", ">", 110.0,
                          "Lower your back knee towards the floor.",
                          Severity.WARNING, KNEES),
            ThresholdRule("torso_lean", "torso_max", ">", 20.0,
                          "Keep your chest up and your torso upright.",
                          Severity.INFO, TORSO),
        ]
