from app.ml.exercises import ExerciseModule, FaultSpec
from app.ml.features import FeatureSet, angle_features, tilt_features, symmetry_feature, duration_feature, joint_angle
from app.ml.rules import ThresholdRule, Severity


class FakeSquat(ExerciseModule):
    name = "test_squat"
    display_name = "Test squat"

    def primary_signal(self, seq):
        return (joint_angle(seq, "left_hip", "left_knee", "left_ankle")
                + joint_angle(seq, "right_hip", "right_knee", "right_ankle")) / 2

    def build_features(self):
        return FeatureSet(
            angle_features("knee_l", "left_hip", "left_knee", "left_ankle")
            + angle_features("knee_r", "right_hip", "right_knee", "right_ankle")
            + tilt_features("torso", "mid_hip", "mid_shoulder")
            + [symmetry_feature("knee_sym", ("left_hip", "left_knee", "left_ankle"),
                                ("right_hip", "right_knee", "right_ankle")),
               duration_feature()]
        )

    def build_faults(self):
        return [
            FaultSpec("shallow", "Did not reach depth", "Go a bit deeper", joints=("left_knee", "right_knee")),
            FaultSpec("forward_lean", "Torso leans too far", "Keep your chest up",
                      Severity.CRITICAL, ("left_shoulder", "right_shoulder", "left_hip", "right_hip")),
        ]

    def build_rules(self):
        return [
            ThresholdRule("shallow", "knee_l_min", ">", 110.0, "Go a bit deeper", joints=("left_knee",)),
        ]
