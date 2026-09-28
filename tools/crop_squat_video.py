#!/usr/bin/env python3
"""Crop a workout video to keep only squat-like movement.

The script uses MediaPipe Pose to score each frame, finds continuous squat
segments, and writes a new video containing only those segments.

Example:
    python3 tools/crop_squat_video.py input.mp4 --output input_squat_only.mp4
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import importlib
import math
import sys
from pathlib import Path
from typing import List, Optional, Sequence, Tuple


VISIBILITY_THRESHOLD = 0.55
SCORE_THRESHOLD = 0.45
SMOOTHING_WINDOW = 7
DEFAULT_PADDING_SEC = 0.75
DEFAULT_MIN_SEGMENT_SEC = 1.0
DEFAULT_MAX_GAP_SEC = 0.4

LEFT_SHOULDER = 11
RIGHT_SHOULDER = 12
LEFT_HIP = 23
RIGHT_HIP = 24
LEFT_KNEE = 25
RIGHT_KNEE = 26
LEFT_ANKLE = 27
RIGHT_ANKLE = 28


class LandmarkPoint:
    def __init__(self, x: float, y: float, visibility: float) -> None:
        self.x = x
        self.y = y
        self.visibility = visibility


@dataclass
class Segment:
    start: int
    end: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Keep only squat-like sections from a workout video."
    )
    parser.add_argument("input", help="Path to the source video")
    parser.add_argument(
        "--output",
        help="Output video path. Defaults to <input_stem>_squat_only.mp4",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=SCORE_THRESHOLD,
        help="Squat score threshold used to keep frames",
    )
    parser.add_argument(
        "--padding-seconds",
        type=float,
        default=DEFAULT_PADDING_SEC,
        help="Seconds added before and after each detected segment",
    )
    parser.add_argument(
        "--min-segment-seconds",
        type=float,
        default=DEFAULT_MIN_SEGMENT_SEC,
        help="Discard squat segments shorter than this duration",
    )
    parser.add_argument(
        "--max-gap-seconds",
        type=float,
        default=DEFAULT_MAX_GAP_SEC,
        help="Merge segments separated by a shorter gap",
    )
    parser.add_argument(
        "--keep-audio",
        action="store_true",
        help="Keep the flag for compatibility; video output is written without audio",
    )
    return parser.parse_args()


def get_point(landmarks, index: int) -> Optional[LandmarkPoint]:
    lm = landmarks.landmark[index]
    if lm.visibility < VISIBILITY_THRESHOLD:
        return None
    return LandmarkPoint(lm.x, lm.y, lm.visibility)


def angle(a: LandmarkPoint, b: LandmarkPoint, c: LandmarkPoint) -> float:
    ab_x = a.x - b.x
    ab_y = a.y - b.y
    cb_x = c.x - b.x
    cb_y = c.y - b.y
    denominator = (math.hypot(ab_x, ab_y) * math.hypot(cb_x, cb_y)) + 1e-6
    cosine = float((ab_x * cb_x + ab_y * cb_y) / denominator)
    cosine = max(-1.0, min(1.0, cosine))
    return math.degrees(math.acos(cosine))


def clamp(value: float, minimum: float = 0.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def score_frame(landmarks, previous_metrics: Optional[dict] = None) -> Tuple[float, Optional[dict]]:
    required_indices = [
        LEFT_SHOULDER,
        RIGHT_SHOULDER,
        LEFT_HIP,
        RIGHT_HIP,
        LEFT_KNEE,
        RIGHT_KNEE,
        LEFT_ANKLE,
        RIGHT_ANKLE,
    ]
    points = {index: get_point(landmarks, index) for index in required_indices}
    left_shoulder = points[LEFT_SHOULDER]
    right_shoulder = points[RIGHT_SHOULDER]
    left_hip = points[LEFT_HIP]
    right_hip = points[RIGHT_HIP]
    left_knee = points[LEFT_KNEE]
    right_knee = points[RIGHT_KNEE]
    left_ankle = points[LEFT_ANKLE]
    right_ankle = points[RIGHT_ANKLE]

    if any(point is None for point in (
        left_shoulder,
        right_shoulder,
        left_hip,
        right_hip,
        left_knee,
        right_knee,
        left_ankle,
        right_ankle,
    )):
        return 0.0, None

    assert left_shoulder is not None
    assert right_shoulder is not None
    assert left_hip is not None
    assert right_hip is not None
    assert left_knee is not None
    assert right_knee is not None
    assert left_ankle is not None
    assert right_ankle is not None

    left_knee_angle = angle(left_hip, left_knee, left_ankle)
    right_knee_angle = angle(right_hip, right_knee, right_ankle)
    knee_angle = (left_knee_angle + right_knee_angle) / 2.0

    shoulder_y = (left_shoulder.y + right_shoulder.y) / 2.0
    hip_y = (left_hip.y + right_hip.y) / 2.0
    knee_y = (left_knee.y + right_knee.y) / 2.0
    ankle_y = (left_ankle.y + right_ankle.y) / 2.0

    bend_score = clamp((180.0 - knee_angle) / 90.0)
    depth_denom = max(1e-6, knee_y - shoulder_y)
    depth_score = clamp((hip_y - shoulder_y) / depth_denom)
    ankle_anchor = clamp((ankle_y - knee_y) / max(1e-6, ankle_y - shoulder_y))

    motion_score = 0.0
    if previous_metrics is not None:
        knee_delta = abs(knee_angle - previous_metrics["knee_angle"])
        hip_delta = abs(hip_y - previous_metrics["hip_y"])
        motion_score = clamp((knee_delta / 25.0) + (hip_delta / 0.035)) / 2.0

    score = (0.55 * bend_score) + (0.30 * depth_score) + (0.10 * motion_score) + (0.05 * ankle_anchor)
    metrics = {
        "knee_angle": knee_angle,
        "hip_y": hip_y,
    }
    return score, metrics


def smooth_scores(scores: Sequence[float], window: int = SMOOTHING_WINDOW) -> List[float]:
    if not scores:
        return []
    if window <= 1:
        return list(scores)

    half_window = window // 2
    smoothed: List[float] = []
    for index in range(len(scores)):
        start = max(0, index - half_window)
        end = min(len(scores), index + half_window + 1)
        segment = scores[start:end]
        smoothed.append(sum(segment) / len(segment))
    return smoothed


def build_segments(
    scores: Sequence[float],
    fps: float,
    threshold: float,
    padding_seconds: float,
    min_segment_seconds: float,
    max_gap_seconds: float,
) -> List[Segment]:
    if not scores or fps <= 0:
        return []

    active = [score >= threshold for score in scores]
    raw_segments: List[Segment] = []
    start = None
    for index, is_active in enumerate(active):
        if is_active and start is None:
            start = index
        elif not is_active and start is not None:
            raw_segments.append(Segment(start=start, end=index - 1))
            start = None
    if start is not None:
        raw_segments.append(Segment(start=start, end=len(scores) - 1))

    if not raw_segments:
        return []

    gap_frames = max(0, int(round(max_gap_seconds * fps)))
    padded_frames = max(0, int(round(padding_seconds * fps)))
    min_frames = max(1, int(round(min_segment_seconds * fps)))

    merged: List[Segment] = []
    for segment in raw_segments:
        if not merged:
            merged.append(segment)
            continue
        previous = merged[-1]
        if segment.start - previous.end <= gap_frames + 1:
            previous.end = max(previous.end, segment.end)
        else:
            merged.append(segment)

    final_segments: List[Segment] = []
    last_index = len(scores) - 1
    for segment in merged:
        start_index = max(0, segment.start - padded_frames)
        end_index = min(last_index, segment.end + padded_frames)
        if end_index - start_index + 1 >= min_frames:
            final_segments.append(Segment(start=start_index, end=end_index))
    return final_segments


def open_video_writer(output_path: Path, fps: float, width: int, height: int):
    cv2 = importlib.import_module("cv2")

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(output_path), fourcc, fps, (width, height))
    if not writer.isOpened():
        raise RuntimeError(f"Could not open output video writer for {output_path}")
    return writer


def analyze_video(video_path: Path) -> Tuple[List[float], float, int, int]:
    cv2 = importlib.import_module("cv2")
    mp = importlib.import_module("mediapipe")

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Could not open video: {video_path}")

    fps = float(cap.get(cv2.CAP_PROP_FPS) or 30.0)
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)

    pose = mp.solutions.pose.Pose(
        static_image_mode=False,
        model_complexity=1,
        enable_segmentation=False,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    )

    scores: List[float] = []
    previous_metrics: Optional[dict] = None

    while True:
        success, frame = cap.read()
        if not success:
            break
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose.process(rgb)
        if result.pose_landmarks is None:
            scores.append(0.0)
            previous_metrics = None
            continue
        score, metrics = score_frame(result.pose_landmarks, previous_metrics)
        scores.append(score)
        previous_metrics = metrics

    pose.close()
    cap.release()

    if not scores:
        raise RuntimeError("No frames were read from the input video")

    return scores, fps, width, height


def write_trimmed_video(
    video_path: Path,
    output_path: Path,
    segments: Sequence[Segment],
    fps: float,
    width: int,
    height: int,
) -> None:
    cv2 = importlib.import_module("cv2")

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Could not reopen video: {video_path}")

    writer = open_video_writer(output_path, fps, width, height)
    segment_iter = iter(segments)
    current_segment = next(segment_iter, None)

    frame_index = 0
    written_frames = 0
    while True:
        success, frame = cap.read()
        if not success:
            break
        while current_segment is not None and frame_index > current_segment.end:
            current_segment = next(segment_iter, None)
        if current_segment is not None and current_segment.start <= frame_index <= current_segment.end:
            writer.write(frame)
            written_frames += 1
        frame_index += 1

    writer.release()
    cap.release()

    if written_frames == 0:
        output_path.unlink(missing_ok=True)
        raise RuntimeError("No squat-like segments were written to the output video")


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).expanduser().resolve()
    if not input_path.exists():
        print(f"Input video not found: {input_path}", file=sys.stderr)
        return 1

    try:
        importlib.import_module("cv2")
        importlib.import_module("mediapipe")
    except ModuleNotFoundError as exc:
        print(
            "Missing runtime dependency: "
            f"{exc.name}. Install the video stack in the project environment first.",
            file=sys.stderr,
        )
        return 3

    output_path = (
        Path(args.output).expanduser().resolve()
        if args.output
        else input_path.with_name(f"{input_path.stem}_squat_only.mp4")
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)

    scores, fps, width, height = analyze_video(input_path)
    smoothed_scores = smooth_scores(scores)
    segments = build_segments(
        smoothed_scores,
        fps=fps,
        threshold=args.threshold,
        padding_seconds=args.padding_seconds,
        min_segment_seconds=args.min_segment_seconds,
        max_gap_seconds=args.max_gap_seconds,
    )

    if not segments:
        print("No squat-like movement was detected. Try lowering --threshold or check the video.", file=sys.stderr)
        return 2

    write_trimmed_video(input_path, output_path, segments, fps, width, height)

    total_original = len(scores)
    kept_frames = sum(segment.end - segment.start + 1 for segment in segments)
    print(f"Saved {output_path}")
    print(f"Detected {len(segments)} segment(s) and kept {kept_frames}/{total_original} frames")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
