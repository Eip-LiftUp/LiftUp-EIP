from __future__ import annotations

import numpy as np

from app.ml.features import joint_angle, point, segment_tilt
from app.ml.pose import PoseSequence
from app.ml.rules import GuardedRule, Rule

FRONT_VIEW_RATIO = 0.5


def view_ratio(seq: PoseSequence) -> float:
    shoulders = np.linalg.norm(point(seq, "left_shoulder") - point(seq, "right_shoulder"), axis=1)
    torso = np.linalg.norm(point(seq, "mid_shoulder") - point(seq, "mid_hip"), axis=1)
    return float(np.median(shoulders) / max(np.median(torso), 1e-6))


def elbow_angle(seq: PoseSequence) -> np.ndarray:
    return (joint_angle(seq, "left_shoulder", "left_elbow", "left_wrist")
            + joint_angle(seq, "right_shoulder", "right_elbow", "right_wrist")) / 2.0


def knee_angle(seq: PoseSequence) -> np.ndarray:
    return (joint_angle(seq, "left_hip", "left_knee", "left_ankle")
            + joint_angle(seq, "right_hip", "right_knee", "right_ankle")) / 2.0


def hip_angle(seq: PoseSequence) -> np.ndarray:
    return (joint_angle(seq, "left_shoulder", "left_hip", "left_knee")
            + joint_angle(seq, "right_shoulder", "right_hip", "right_knee")) / 2.0


def body_line_angle(seq: PoseSequence) -> np.ndarray:
    return joint_angle(seq, "mid_shoulder", "mid_hip", "mid_ankle")


def torso_tilt(seq: PoseSequence) -> np.ndarray:
    return segment_tilt(seq, "mid_hip", "mid_shoulder")


def wrist_height(seq: PoseSequence) -> np.ndarray:
    return (point(seq, "left_wrist")[:, 1] + point(seq, "right_wrist")[:, 1]) / 2.0


def bar_height(seq: PoseSequence) -> np.ndarray:
    return point(seq, "mid_ankle")[:, 1] - wrist_height(seq)


def bar_offset(seq: PoseSequence) -> np.ndarray:
    wrist_x = (point(seq, "left_wrist")[:, 0] + point(seq, "right_wrist")[:, 0]) / 2.0
    return np.abs(wrist_x - point(seq, "mid_ankle")[:, 0])


def elbow_swing(seq: PoseSequence) -> np.ndarray:
    left = np.abs(point(seq, "left_elbow")[:, 0] - point(seq, "left_shoulder")[:, 0])
    right = np.abs(point(seq, "right_elbow")[:, 0] - point(seq, "right_shoulder")[:, 0])
    return (left + right) / 2.0


def side_only(rule: Rule) -> GuardedRule:
    return GuardedRule(rule, "view_ratio", "<", FRONT_VIEW_RATIO)


def front_only(rule: Rule) -> GuardedRule:
    return GuardedRule(rule, "view_ratio", ">=", FRONT_VIEW_RATIO)
