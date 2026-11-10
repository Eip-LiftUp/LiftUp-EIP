"""Batch pose extraction for training videos (issue #78).

Turns every video of a folder (e.g. the clips of tools/squat_downloader, trimmed
by tools/crop_squat_video.py) into one PoseSequence file (.npz) per video,
indexed by a manifest.json:

    python -m app.ml.pose.batch data/datasets/squat/videos
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import asdict, dataclass, fields
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable, Dict, Iterator, List, Optional, Sequence, Tuple, Union

from app.ml.pose.extractor import MediaPipeExtractor, PoseExtractor
from app.ml.pose.sequence import PoseSequence

MANIFEST_NAME = "manifest.json"
MANIFEST_VERSION = 1
VIDEO_EXTENSIONS = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v"}
# Added by tools/crop_squat_video.py, which writes the trimmed clip next to the original.
TRIM_SUFFIX = "_squat_only"
DEFAULT_MIN_DETECTION = 0.8

STATUS_OK = "ok"
STATUS_LOW_DETECTION = "low_detection"
STATUS_ERROR = "error"


@dataclass
class ManifestEntry:
    id: str
    video: str
    query: str
    youtube_id: str
    status: str
    poses: Optional[str] = None
    fps: Optional[float] = None
    frames: Optional[int] = None
    duration_s: Optional[float] = None
    width: Optional[int] = None
    height: Optional[int] = None
    detection_rate: Optional[float] = None
    video_size: Optional[int] = None
    error: Optional[str] = None
    extracted_at: Optional[str] = None

    @classmethod
    def from_dict(cls, data: Dict) -> "ManifestEntry":
        known = {f.name for f in fields(cls)}
        return cls(**{k: v for k, v in data.items() if k in known})


@dataclass
class BatchReport:
    ok: int = 0
    low_detection: int = 0
    errors: int = 0
    skipped: int = 0

    @property
    def processed(self) -> int:
        return self.ok + self.low_detection + self.errors


def recording_id(video: Path, videos_dir: Path) -> Tuple[str, str, str]:
    """`bad_squat_form/abc123_squat_only.mp4` -> ("bad_squat_form/abc123", "bad_squat_form", "abc123")."""
    relative = video.relative_to(videos_dir)
    stem = relative.stem
    if stem.endswith(TRIM_SUFFIX):
        stem = stem[: -len(TRIM_SUFFIX)]
    query = relative.parent.as_posix()
    query = "" if query == "." else query
    return (f"{query}/{stem}" if query else stem), query, stem


def find_videos(videos_dir: Path) -> List[Path]:
    """Every video under [videos_dir]; a trimmed clip replaces its original, so
    the same video is never extracted twice."""
    videos = sorted(p for p in videos_dir.rglob("*") if p.is_file() and p.suffix.lower() in VIDEO_EXTENSIONS)
    trimmed = {(p.parent, p.stem[: -len(TRIM_SUFFIX)]) for p in videos if p.stem.endswith(TRIM_SUFFIX)}
    return [p for p in videos if p.stem.endswith(TRIM_SUFFIX) or (p.parent, p.stem) not in trimmed]


def load_manifest(output_dir: Union[str, Path]) -> Dict:
    path = Path(output_dir) / MANIFEST_NAME
    if not path.exists():
        return {"version": MANIFEST_VERSION, "recordings": []}
    return json.loads(path.read_text(encoding="utf-8"))


def _write_manifest(output_dir: Path, manifest: Dict) -> None:
    # Written to a temporary file first: an interrupted run keeps a readable manifest.
    path = output_dir / MANIFEST_NAME
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    os.replace(tmp, path)


def _is_done(entry: Optional[ManifestEntry], video: str, size: int, output_dir: Path) -> bool:
    if entry is None or entry.status == STATUS_ERROR or entry.poses is None:
        return False
    # Another file (e.g. the trimmed clip after the original) or a changed one.
    return entry.video == video and entry.video_size == size and (output_dir / entry.poses).exists()


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _print(message: str) -> None:
    # Flushed: through `docker exec`/`docker run` stdout is not a terminal, and
    # the progress would otherwise only show at the end of the run.
    print(message, flush=True)


def extract_directory(
    videos_dir: Union[str, Path],
    output_dir: Union[str, Path],
    extractor: PoseExtractor,
    *,
    exercise: str = "squat",
    extractor_info: Optional[Dict] = None,
    min_detection: float = DEFAULT_MIN_DETECTION,
    force: bool = False,
    log: Callable[[str], None] = _print,
) -> BatchReport:
    """Extracts every video under [videos_dir] (see [find_videos]).

    Videos already extracted with the same settings are skipped, failed ones
    are retried. One failing video never stops the run.
    """
    videos_dir = Path(videos_dir)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    extractor_info = extractor_info or {}

    manifest = load_manifest(output_dir)
    # Mixing landmarks from different models would skew the dataset.
    if manifest.get("extractor", extractor_info) != extractor_info:
        log("Extractor settings changed: every video is extracted again.")
        force = True
    entries = {e["id"]: ManifestEntry.from_dict(e) for e in manifest.get("recordings", [])}

    def save_manifest() -> None:
        _write_manifest(output_dir, {
            "version": MANIFEST_VERSION,
            "exercise": exercise,
            "videos_dir": str(videos_dir),
            "extractor": extractor_info,
            "updated_at": _now(),
            "recordings": [asdict(e) for _, e in sorted(entries.items())],
        })

    videos = find_videos(videos_dir)
    report = BatchReport()
    log(f"{len(videos)} video(s) in {videos_dir}")

    for index, video in enumerate(videos, start=1):
        rid, query, youtube_id = recording_id(video, videos_dir)
        relative, size = video.relative_to(videos_dir).as_posix(), video.stat().st_size
        prefix = f"[{index}/{len(videos)}] {rid}"
        if not force and _is_done(entries.get(rid), relative, size, output_dir):
            report.skipped += 1
            continue

        entry = ManifestEntry(
            id=rid,
            video=relative,
            query=query,
            youtube_id=youtube_id,
            status=STATUS_ERROR,
            video_size=size,
            extracted_at=_now(),
        )
        try:
            sequence = extractor.extract(video)
            poses = f"{rid}.npz"
            sequence.save(output_dir / poses)
        except Exception as exc:  # one broken video must not stop the batch
            entry.error = f"{type(exc).__name__}: {exc}"
            report.errors += 1
            log(f"{prefix}: error, {entry.error}")
        else:
            rate = sequence.detection_rate
            entry.status = STATUS_OK if rate >= min_detection else STATUS_LOW_DETECTION
            entry.poses = poses
            entry.fps = sequence.fps
            entry.frames = sequence.num_frames
            entry.duration_s = round(sequence.duration_s, 3)
            entry.width = sequence.metadata.get("width")
            entry.height = sequence.metadata.get("height")
            entry.detection_rate = round(rate, 4)
            if entry.status == STATUS_OK:
                report.ok += 1
            else:
                report.low_detection += 1
            log(f"{prefix}: {entry.status}, {sequence.num_frames} frames, person found in {rate:.0%}")

        entries[rid] = entry
        save_manifest()

    if not videos:
        save_manifest()
    log(
        f"Done: {report.ok} ok, {report.low_detection} low detection, "
        f"{report.errors} error(s), {report.skipped} already extracted"
    )
    return report


def iter_sequences(
    output_dir: Union[str, Path],
    statuses: Sequence[str] = (STATUS_OK,),
) -> Iterator[Tuple[ManifestEntry, PoseSequence]]:
    """The extracted recordings, for building the labelled dataset (#80)."""
    output_dir = Path(output_dir)
    for raw in load_manifest(output_dir).get("recordings", []):
        entry = ManifestEntry.from_dict(raw)
        if entry.status in statuses and entry.poses:
            yield entry, PoseSequence.load(output_dir / entry.poses)


def _mediapipe_version() -> Optional[str]:
    try:
        from importlib.metadata import version

        return version("mediapipe")
    except Exception:
        return None


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="python -m app.ml.pose.batch",
        description="Extract MediaPipe poses from training videos into .npz files and a manifest.json.",
    )
    parser.add_argument("videos_dir", help="Folder of videos, e.g. data/datasets/squat/videos")
    parser.add_argument("--output-dir", help="Where to write the poses (default: <videos_dir>/../poses)")
    parser.add_argument("--exercise", default="squat", help="Exercise recorded in the manifest (default: squat)")
    parser.add_argument(
        "--min-detection",
        type=float,
        default=DEFAULT_MIN_DETECTION,
        help="Share of frames with a person below which a video is flagged low_detection (default: 0.8)",
    )
    parser.add_argument("--model-complexity", type=int, choices=(0, 1, 2), default=1, help="MediaPipe model (default: 1)")
    parser.add_argument("--force", action="store_true", help="Extract again videos already extracted")
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)
    videos_dir = Path(args.videos_dir)
    if not videos_dir.is_dir():
        print(f"Not a folder: {videos_dir}", file=sys.stderr)
        return 2
    output_dir = Path(args.output_dir) if args.output_dir else videos_dir.parent / "poses"
    report = extract_directory(
        videos_dir,
        output_dir,
        MediaPipeExtractor(model_complexity=args.model_complexity),
        exercise=args.exercise,
        extractor_info={
            "name": "mediapipe",
            "mediapipe_version": _mediapipe_version(),
            "model_complexity": args.model_complexity,
        },
        min_detection=args.min_detection,
        force=args.force,
    )
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
