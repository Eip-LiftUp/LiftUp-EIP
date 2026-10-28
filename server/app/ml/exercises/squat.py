import numpy as np

from app.ml.exercises.base import ExerciseModule, FaultSpec
from app.ml.exercises.registry import register_exercise
from app.ml.features import (
    FeatureSet,
    FeatureSpec,
    signal_features,
    angle_features,
    tilt_features,
    symmetry_feature,
    duration_feature,
    joint_angle,
    segment_tilt,
    point,
)
from app.ml.pose import PoseSequence
from app.ml.rules import ThresholdRule, GuardedRule, Severity
from app.ml.segmentation import SegmentationConfig

FRONT_VIEW_RATIO = 0.5

KNEES = ("left_knee", "right_knee")
HIPS = ("left_hip", "right_hip")
SHOULDERS = ("left_shoulder", "right_shoulder")
FEET = ("left_heel", "right_heel", "left_foot_index", "right_foot_index")


def knee_angle(seq: PoseSequence) -> np.ndarray:
    return (joint_angle(seq, "left_hip", "left_knee", "left_ankle")
            + joint_angle(seq, "right_hip", "right_knee", "right_ankle")) / 2.0


def hip_angle(seq: PoseSequence) -> np.ndarray:
    return (joint_angle(seq, "left_shoulder", "left_hip", "left_knee")
            + joint_angle(seq, "right_shoulder", "right_hip", "right_knee")) / 2.0


def hip_height(seq: PoseSequence) -> np.ndarray:
    return point(seq, "mid_ankle")[:, 1] - point(seq, "mid_hip")[:, 1]


def hip_below_knee(seq: PoseSequence) -> np.ndarray:
    return point(seq, "mid_hip")[:, 1] - point(seq, "mid_knee")[:, 1]


def shin_tilt(seq: PoseSequence) -> np.ndarray:
    return (segment_tilt(seq, "left_ankle", "left_knee") + segment_tilt(seq, "right_ankle", "right_knee")) / 2.0


def torso_lead(seq: PoseSequence) -> np.ndarray:
    return segment_tilt(seq, "mid_hip", "mid_shoulder") - shin_tilt(seq)


def hip_level_diff(seq: PoseSequence) -> np.ndarray:
    return np.abs(point(seq, "left_hip")[:, 1] - point(seq, "right_hip")[:, 1])


def knee_ankle_width_ratio(seq: PoseSequence) -> np.ndarray:
    knees = np.abs(point(seq, "left_knee")[:, 0] - point(seq, "right_knee")[:, 0])
    ankles = np.abs(point(seq, "left_ankle")[:, 0] - point(seq, "right_ankle")[:, 0])
    return knees / np.maximum(ankles, 1e-6)


def heel_rise(seq: PoseSequence) -> np.ndarray:
    side = max(("left", "right"), key=lambda s: float(
        np.mean(seq.visibility(f"{s}_heel")) + np.mean(seq.visibility(f"{s}_foot_index"))))
    lift = point(seq, f"{side}_foot_index")[:, 1] - point(seq, f"{side}_heel")[:, 1]
    return lift - lift[0]


def view_ratio(seq: PoseSequence) -> float:
    shoulders = np.abs(point(seq, "left_shoulder")[:, 0] - point(seq, "right_shoulder")[:, 0])
    torso = np.linalg.norm(point(seq, "mid_shoulder") - point(seq, "mid_hip"), axis=1)
    return float(np.median(shoulders) / max(np.median(torso), 1e-6))


def _side_only(rule):
    return GuardedRule(rule, "view_ratio", "<", FRONT_VIEW_RATIO)


def _front_only(rule):
    return GuardedRule(rule, "view_ratio", ">=", FRONT_VIEW_RATIO)


@register_exercise
class Squat(ExerciseModule):
    name = "squat"
    display_name = "Squat"
    segmentation_config = SegmentationConfig(
        direction="min",
        min_prominence=0.1,
        min_rep_seconds=0.8,
        max_rep_seconds=8.0,
    )

    def primary_signal(self, seq: PoseSequence) -> np.ndarray:
        return hip_height(seq)

    def build_features(self) -> FeatureSet:
        return FeatureSet(
            signal_features("knee", knee_angle)
            + angle_features("knee_l", "left_hip", "left_knee", "left_ankle", stats=("min",))
            + angle_features("knee_r", "right_hip", "right_knee", "right_ankle", stats=("min",))
            + signal_features("hip", hip_angle, stats=("min", "mean", "range"))
            + tilt_features("torso", "mid_hip", "mid_shoulder", stats=("max", "mean", "argmax_frac"))
            + signal_features("shin", shin_tilt, stats=("max", "mean"))
            + signal_features("torso_lead", torso_lead, stats=("max", "mean"))
            + signal_features("hip_level_diff", hip_level_diff, stats=("max",))
            + signal_features("hip_height", hip_height, stats=("min", "range"))
            + signal_features("hip_below_knee", hip_below_knee, stats=("max",))
            + signal_features("knee_ankle_ratio", knee_ankle_width_ratio, stats=("min", "mean"))
            + signal_features("heel_rise", heel_rise, stats=("max",))
            + [
                symmetry_feature("knee_sym", ("left_hip", "left_knee", "left_ankle"),
                                 ("right_hip", "right_knee", "right_ankle")),
                FeatureSpec("view_ratio", view_ratio),
                duration_feature(),
            ]
        )

    def build_faults(self):
        return [
            FaultSpec("shallow_depth", "Thighs stay well above parallel at the bottom of the rep.",
                      "Try to sit a bit deeper, aiming for thighs parallel to the floor.",
                      Severity.WARNING, KNEES + HIPS),
            FaultSpec("excessive_forward_lean", "Torso tips far forward, chest drops towards the knees.",
                      "Keep your chest up and brace your core.",
                      Severity.WARNING, SHOULDERS + HIPS),
            FaultSpec("heel_lift", "Heels come off the floor during the rep.",
                      "Keep your whole foot planted, push through your heels.",
                      Severity.WARNING, FEET),
            FaultSpec("knee_valgus", "Knees cave inwards relative to the feet.",
                      "Push your knees out in line with your toes.",
                      Severity.CRITICAL, KNEES + ("left_ankle", "right_ankle")),
            FaultSpec("asymmetric_depth", "One leg bends noticeably more than the other; the pelvis tilts.",
                      "Try to share the load evenly between both legs.",
                      Severity.INFO, HIPS + KNEES),
        ]

    def build_rules(self):
        return [
            _side_only(ThresholdRule("shallow_depth", "knee_min", ">", 100.0,
                                     "Try to sit a bit deeper, aiming for thighs parallel to the floor.",
                                     Severity.WARNING, KNEES + HIPS)),
            _side_only(ThresholdRule("excessive_forward_lean", "torso_lead_max", ">", 25.0,
                                     "Keep your chest up and brace your core.",
                                     Severity.WARNING, SHOULDERS + HIPS)),
            _side_only(ThresholdRule("heel_lift", "heel_rise_max", ">", 0.05,
                                     "Keep your whole foot planted, push through your heels.",
                                     Severity.WARNING, FEET)),
            _front_only(ThresholdRule("knee_valgus", "knee_ankle_ratio_min", "<", 0.8,
                                      "Push your knees out in line with your toes.",
                                      Severity.CRITICAL, KNEES + ("left_ankle", "right_ankle"))),
            _front_only(ThresholdRule("asymmetric_depth", "hip_level_diff_max", ">", 0.1,
                                      "Try to share the load evenly between both legs.",
                                      Severity.INFO, HIPS + KNEES)),
        ]
