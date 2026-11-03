from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.common import bar_height, bar_offset, hip_angle, side_only, view_ratio
from app.ml.exercises.registry import register_exercise
from app.ml.features import FeatureSet, FeatureSpec, duration_feature, signal_features
from app.ml.rules import Severity, ThresholdRule
from app.ml.segmentation import SegmentationConfig

BAR = ("left_wrist", "right_wrist", "left_ankle", "right_ankle")
HIPS = ("left_shoulder", "left_hip", "left_knee", "right_shoulder", "right_hip", "right_knee")


@register_exercise
class Deadlift(ExerciseModule):
    name = "deadlift"
    display_name = "Deadlift"
    segmentation_config = SegmentationConfig(
        direction="min",
        min_prominence=0.5,
        min_rep_seconds=1.0,
        max_rep_seconds=12.0,
    )

    def primary_signal(self, seq):
        return bar_height(seq)

    def build_features(self) -> FeatureSet:
        return FeatureSet(
            signal_features("bar", bar_height, stats=("max", "range"))
            + signal_features("bar_offset", bar_offset, stats=("max",))
            + signal_features("hip", hip_angle, stats=("min", "max", "range"))
            + [FeatureSpec("view_ratio", view_ratio), duration_feature()]
        )

    def build_faults(self):
        return [
            FaultSpec("bar_away_from_body", "Bar travels forward, away from the shins.",
                      "Keep the bar close to your shins for the whole rep.",
                      Severity.WARNING, BAR),
            FaultSpec("incomplete_lockout", "Hips do not fully extend at the top of the rep.",
                      "Stand tall at the top: squeeze your glutes to finish the hip extension.",
                      Severity.INFO, HIPS),
        ]

    def build_rules(self):
        return [
            side_only(ThresholdRule("bar_away_from_body", "bar_offset_max", ">", 0.35,
                                    "Keep the bar close to your shins for the whole rep.",
                                    Severity.WARNING, BAR)),
            ThresholdRule("incomplete_lockout", "hip_max", "<", 160.0,
                          "Stand tall at the top: squeeze your glutes to finish the hip extension.",
                          Severity.INFO, HIPS),
        ]
