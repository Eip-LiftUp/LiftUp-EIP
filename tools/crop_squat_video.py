#!/usr/bin/env python3
"""Keep only the parts of a video where a person is visibly doing a squat."""

from __future__ import annotations

import argparse
import importlib
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Sequence, Tuple

import numpy as np


SCORE_THRESHOLD = 0.75
DEFAULT_PADDING_SEC = 0.1
DEFAULT_MIN_SEGMENT_SEC = 1.5
DEFAULT_MAX_GAP_SEC = 0.1
DEFAULT_SAMPLE_RATE = 60
DEFAULT_MAX_WIDTH = 320


@dataclass
class Segment:
    start: int
    end: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Trim a video to only the frames where a human is doing a squat-like motion."
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
        help="Motion score threshold used to keep frames.",
    )
    parser.add_argument(
        "--padding-seconds",
        type=float,
        default=DEFAULT_PADDING_SEC,
        help="Padding added before and after each detected squat segment.",
    )
    parser.add_argument(
        "--min-segment-seconds",
        type=float,
        default=DEFAULT_MIN_SEGMENT_SEC,
        help="Minimum valid duration for a squat segment.",
    )
    parser.add_argument(
        "--max-gap-seconds",
        type=float,
        default=DEFAULT_MAX_GAP_SEC,
        help="Gap allowed between detected motion bursts before they are split.",
    )
    parser.add_argument(
        "--sample-rate",
        type=int,
        default=DEFAULT_SAMPLE_RATE,
        help="Process one frame out of N to keep detection fast.",
    )
    parser.add_argument(
        "--max-width",
        type=int,
        default=DEFAULT_MAX_WIDTH,
        help="Resize the frame before motion detection to speed it up.",
    )
    return parser.parse_args()


def clamp(value: float, minimum: float = 0.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def find_person_bbox(mask, min_area: int = 400, frame_h: int = 1, frame_w: int = 1) -> Optional[tuple[int, int, int, int]]:
    cv2 = importlib.import_module("cv2")
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None

    valid: List[tuple[float, int, int, int, int]] = []
    for contour in contours:
        area = float(cv2.contourArea(contour))
        if area < min_area:
            continue
        x, y, w, h = cv2.boundingRect(contour)
        if w <= 0 or h <= 0:
            continue
        if h < 8 or w < 8:
            continue
        if h > max(40, frame_h * 0.9):
            continue
        if w > max(120, frame_h * 1.4):
            continue

        area_ratio = (w * h) / max(1, frame_w * frame_h)
        if area_ratio < 0.003 or area_ratio > 0.25:
            continue

        center_x = (x + w / 2.0) / max(1, frame_w)
        center_y = (y + h / 2.0) / max(1, frame_h)
        if center_x < 0.10 or center_x > 0.90 or center_y < 0.08 or center_y > 0.92:
            continue

        valid.append((area, x, y, w, h))

    if not valid:
        return None

    _, x, y, w, h = max(valid, key=lambda item: item[0])
    return x, y, w, h


def motion_score(
    bbox: Optional[tuple[int, int, int, int]],
    prev_bbox: Optional[tuple[int, int, int, int]],
    motion_area: float,
    frame_h: int = 1,
    frame_w: int = 1,
) -> float:
    if bbox is None:
        return 0.0

    x, y, w, h = bbox
    area = max(1, w * h)
    body_ratio = clamp(w / max(h, 1), 0.0, 1.0)

    if prev_bbox is None:
        motion_factor = clamp(motion_area / max(1, (frame_w * frame_h) * 0.12), 0.0, 1.0)
        return clamp((motion_factor * 0.7) + (body_ratio * 0.3), 0.0, 1.0)

    px, py, pw, ph = prev_bbox
    center_y = y + h / 2.0
    prev_center_y = py + ph / 2.0
    height_change = abs(h - ph)
    vertical_move = abs(center_y - prev_center_y)
    area_change = abs(area - (pw * ph))

    normalized_vertical = clamp(vertical_move / max(10.0, frame_h * 0.18), 0.0, 1.0)
    normalized_height = clamp(height_change / max(10.0, frame_h * 0.18), 0.0, 1.0)
    normalized_area = clamp(area_change / max(1.0, (frame_w * frame_h) * 0.10), 0.0, 1.0)
    score = 0.50 * normalized_vertical + 0.25 * normalized_height + 0.25 * normalized_area
    score = clamp(score + (body_ratio * 0.10), 0.0, 1.0)
    return score


def smooth_scores(scores: Sequence[float], window: int = 5) -> List[float]:
    if not scores:
        return []
    if window <= 1:
        return list(scores)

    smoothed: List[float] = []
    half = window // 2
    for index in range(len(scores)):
        start = max(0, index - half)
        end = min(len(scores), index + half + 1)
        segment = scores[start:end]
        smoothed.append(sum(segment) / len(segment))
    return smoothed


def build_segments(
    scores: Sequence[float],
    frame_numbers: Sequence[int],
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
    start_index: Optional[int] = None
    for index, is_active in enumerate(active):
        if is_active and start_index is None:
            start_index = index
        elif not is_active and start_index is not None:
            raw_segments.append(Segment(start=frame_numbers[start_index], end=frame_numbers[index - 1]))
            start_index = None
    if start_index is not None:
        raw_segments.append(Segment(start=frame_numbers[start_index], end=frame_numbers[-1]))

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
    for segment in merged:
        start_frame = max(0, segment.start - padded_frames)
        end_frame = max(start_frame, segment.end + padded_frames)
        if end_frame - start_frame + 1 >= min_frames:
            final_segments.append(Segment(start=start_frame, end=end_frame))
    return final_segments


def open_video_writer(output_path: Path, fps: float, width: int, height: int):
    cv2 = importlib.import_module("cv2")
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(output_path), fourcc, fps, (width, height))
    if not writer.isOpened():
        raise RuntimeError(f"Could not open output video writer for {output_path}")
    return writer


def analyze_video(video_path: Path, sample_rate: int = DEFAULT_SAMPLE_RATE, max_width: int = DEFAULT_MAX_WIDTH) -> Tuple[List[float], List[int], float, int, int]:
    cv2 = importlib.import_module("cv2")

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Could not open video: {video_path}")

    fps = float(cap.get(cv2.CAP_PROP_FPS) or 30.0)
    original_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    original_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)

    print(f"[1/2] Analyzing {video_path.name} (fps={fps:.2f}, resolution={original_width}x{original_height}, sample_rate={sample_rate})")

    scores: List[float] = []
    frame_numbers: List[int] = []
    previous_bbox: Optional[tuple[int, int, int, int]] = None
    previous_gray: Optional[np.ndarray] = None
    frame_index = 0
    processed = 0

    while True:
        success, frame = cap.read()
        if not success:
            break

        if frame_index % sample_rate != 0:
            frame_index += 1
            continue

        working_width = original_width
        working_height = original_height
        if max_width and working_width and working_width > max_width:
            scale = max_width / float(working_width)
            working_height = max(1, int(round(working_height * scale)))
            frame = cv2.resize(frame, (max_width, working_height), interpolation=cv2.INTER_LINEAR)
            working_width = max_width

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (5, 5), 0)

        if previous_gray is None:
            previous_gray = gray.copy()
            previous_bbox = None
            frame_index += 1
            continue

        diff = cv2.absdiff(gray, previous_gray)
        _, thresh = cv2.threshold(diff, 20, 255, cv2.THRESH_BINARY)
        thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
        thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, np.ones((7, 7), np.uint8))
        motion_area = float(np.count_nonzero(thresh))

        current_bbox = find_person_bbox(
            thresh,
            min_area=max(200, int((working_width * working_height) * 0.003)),
            frame_h=working_height,
            frame_w=working_width,
        )
        score = motion_score(current_bbox, previous_bbox, motion_area, frame_h=working_height, frame_w=working_width)
        scores.append(score)
        frame_numbers.append(frame_index)
        previous_bbox = current_bbox
        previous_gray = gray
        processed += 1
        frame_index += 1

        if total_frames > 0 and processed % max(1, min(250, total_frames // 10)) == 0:
            progress = (frame_index / max(1, total_frames)) * 100.0
            print(f"  progress: {progress:.1f}% ({frame_index}/{total_frames} frames scanned)")

    cap.release()

    if not scores:
        raise RuntimeError("No frames were read from the input video")

    print(f"[1/2] Detection finished: {len(scores)} scored samples from {video_path.name}")
    return scores, frame_numbers, fps, original_width, original_height


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

    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    print(f"[2/2] Writing trimmed clip to {output_path.name} with {len(segments)} detected segment(s)")

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
        if total_frames > 0 and frame_index % max(1, total_frames // 10) == 0:
            progress = (frame_index / max(1, total_frames)) * 100.0
            print(f"  progress: {progress:.1f}% ({frame_index}/{total_frames} frames written)")

    writer.release()
    cap.release()

    if written_frames == 0:
        output_path.unlink(missing_ok=True)
        raise RuntimeError("No squat-like segments were written to the output video")

    print(f"[2/2] Finished writing {written_frames} frames to {output_path.name}")


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).expanduser().resolve()
    if not input_path.exists():
        print(f"Input video not found: {input_path}", file=sys.stderr)
        return 1

    try:
        import cv2
        import numpy as np
    except ModuleNotFoundError as exc:
        print(f"Missing dependency: {exc.name}. Install OpenCV and NumPy first.", file=sys.stderr)
        return 3

    output_path = (
        Path(args.output).expanduser().resolve()
        if args.output
        else input_path.with_name(f"{input_path.stem}_squat_only.mp4")
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)

    scores, frame_numbers, fps, width, height = analyze_video(
        input_path,
        sample_rate=max(1, args.sample_rate),
        max_width=args.max_width,
    )
    smoothed_scores = smooth_scores(scores)
    segments = build_segments(
        smoothed_scores,
        frame_numbers,
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

    total_frames = len(scores)
    kept_frames = sum(segment.end - segment.start + 1 for segment in segments)
    print(f"Saved {output_path}")
    print(f"Detected {len(segments)} segment(s) and kept {kept_frames}/{total_frames} sampled frames")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
