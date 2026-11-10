import json

import numpy as np
import pytest

from app.ml.pose import PoseExtractor
from app.ml.pose import batch
from app.ml.pose.batch import extract_directory, iter_sequences, load_manifest, recording_id
from tests.ml.synthetic import squat_sequence

INFO = {"name": "fake", "model_complexity": 1}


class FakeExtractor(PoseExtractor):
    """Squat poses for every video; `broken` videos fail, `hidden` ones lose half their frames."""

    def __init__(self):
        self.calls = []

    def extract(self, video_path):
        self.calls.append(video_path.name)
        if "broken" in video_path.name:
            raise ValueError("No frames decoded")
        seq = squat_sequence(reps=1, fps=30)
        seq.metadata.update(source=str(video_path), width=1280, height=720)
        if "hidden" in video_path.name:
            data = seq.landmarks.copy()
            data[: seq.num_frames // 2] = 0
            seq = seq.copy_with(data)
        return seq


def _video(folder, relative, content=b"video"):
    path = folder / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)
    return path


@pytest.fixture
def videos(tmp_path):
    folder = tmp_path / "videos"
    _video(folder, "proper_squat_form_exercise/abc123_squat_only.mp4")
    _video(folder, "proper_squat_form_exercise/abc123.webm")  # original before trimming
    _video(folder, "bad_squat_form_exercise/hidden9_squat_only.mp4")
    _video(folder, "bad_squat_form_exercise/broken7_squat_only.mp4")
    return folder


def _run(videos, out, extractor=None, **kwargs):
    return extract_directory(videos, out, extractor or FakeExtractor(), extractor_info=INFO, log=lambda _: None, **kwargs)


def test_recording_id_strips_the_trim_suffix(tmp_path):
    video = tmp_path / "bad_lean" / "xyz_squat_only.mp4"
    assert recording_id(video, tmp_path) == ("bad_lean/xyz", "bad_lean", "xyz")
    assert recording_id(tmp_path / "solo.mp4", tmp_path) == ("solo", "", "solo")


def test_every_video_is_taken_but_a_trimmed_clip_replaces_its_original(tmp_path):
    folder = tmp_path / "videos"
    for name in ("q/a.webm", "q/a_squat_only.mp4", "q/b.mp4", "q/c.MOV", "q/notes.txt", "q/d.webm.part", "other/a.mp4"):
        _video(folder, name)
    found = [p.relative_to(folder).as_posix() for p in batch.find_videos(folder)]
    assert found == ["other/a.mp4", "q/a_squat_only.mp4", "q/b.mp4", "q/c.MOV"]


def test_a_clip_trimmed_later_replaces_the_extracted_original(tmp_path):
    folder = tmp_path / "videos"
    _video(folder, "q/a.webm")
    out = tmp_path / "poses"
    _run(folder, out)
    assert load_manifest(out)["recordings"][0]["video"] == "q/a.webm"

    _video(folder, "q/a_squat_only.mp4")  # same size as the original on purpose
    extractor = FakeExtractor()
    _run(folder, out, extractor)

    assert extractor.calls == ["a_squat_only.mp4"]
    [entry] = load_manifest(out)["recordings"]
    assert (entry["id"], entry["video"]) == ("q/a", "q/a_squat_only.mp4")


def test_extracts_videos_into_poses_and_manifest(videos, tmp_path):
    out = tmp_path / "poses"
    report = _run(videos, out)

    assert (report.ok, report.low_detection, report.errors, report.skipped) == (1, 1, 1, 0)
    manifest = load_manifest(out)
    assert manifest["exercise"] == "squat"
    assert manifest["extractor"] == INFO
    entries = {e["id"]: e for e in manifest["recordings"]}
    assert set(entries) == {
        "proper_squat_form_exercise/abc123",
        "bad_squat_form_exercise/hidden9",
        "bad_squat_form_exercise/broken7",
    }

    ok = entries["proper_squat_form_exercise/abc123"]
    assert ok["status"] == "ok"
    assert ok["query"] == "proper_squat_form_exercise"
    assert ok["youtube_id"] == "abc123"
    assert ok["video"] == "proper_squat_form_exercise/abc123_squat_only.mp4"
    assert (ok["fps"], ok["width"], ok["height"], ok["detection_rate"]) == (30.0, 1280, 720, 1.0)
    assert (out / ok["poses"]).exists()

    assert entries["bad_squat_form_exercise/hidden9"]["status"] == "low_detection"
    assert entries["bad_squat_form_exercise/hidden9"]["detection_rate"] == pytest.approx(0.5, abs=0.02)

    broken = entries["bad_squat_form_exercise/broken7"]
    assert broken["status"] == "error"
    assert broken["poses"] is None
    assert broken["error"] == "ValueError: No frames decoded"


def test_a_second_run_only_retries_failures(videos, tmp_path):
    out = tmp_path / "poses"
    _run(videos, out)
    extractor = FakeExtractor()
    report = _run(videos, out, extractor)

    assert extractor.calls == ["broken7_squat_only.mp4"]
    assert report.skipped == 2


def test_force_and_changed_videos_are_extracted_again(videos, tmp_path):
    out = tmp_path / "poses"
    _run(videos, out)

    _video(videos, "proper_squat_form_exercise/abc123_squat_only.mp4", b"a longer, re-trimmed video")
    extractor = FakeExtractor()
    _run(videos, out, extractor)
    assert sorted(extractor.calls) == ["abc123_squat_only.mp4", "broken7_squat_only.mp4"]

    extractor = FakeExtractor()
    _run(videos, out, extractor, force=True)
    assert len(extractor.calls) == 3


def test_other_extractor_settings_extract_everything_again(videos, tmp_path):
    out = tmp_path / "poses"
    _run(videos, out)
    extractor = FakeExtractor()
    extract_directory(videos, out, extractor, extractor_info={**INFO, "model_complexity": 2}, log=lambda _: None)
    assert len(extractor.calls) == 3


def test_an_interrupted_run_keeps_what_was_extracted(videos, tmp_path):
    class Interrupted(FakeExtractor):
        def extract(self, video_path):
            if "hidden" in video_path.name:
                raise KeyboardInterrupt
            return super().extract(video_path)

    out = tmp_path / "poses"
    with pytest.raises(KeyboardInterrupt):
        _run(videos, out, Interrupted())
    # Sorted order: bad_.../broken7, then bad_.../hidden9 is interrupted.
    ids = [e["id"] for e in load_manifest(out)["recordings"]]
    assert ids == ["bad_squat_form_exercise/broken7"]
    assert not (out / "manifest.json.tmp").exists()


def test_iter_sequences_loads_usable_recordings(videos, tmp_path):
    out = tmp_path / "poses"
    _run(videos, out)

    loaded = list(iter_sequences(out))
    assert [entry.id for entry, _ in loaded] == ["proper_squat_form_exercise/abc123"]
    entry, sequence = loaded[0]
    assert sequence.num_frames == entry.frames
    assert np.all(sequence.landmarks[:, :, 3] > 0)

    with_low = list(iter_sequences(out, statuses=("ok", "low_detection")))
    assert len(with_low) == 2


def test_cli_writes_next_to_the_videos_and_reports_errors(videos, monkeypatch):
    monkeypatch.setattr(batch, "MediaPipeExtractor", lambda model_complexity: FakeExtractor())
    assert batch.main([str(videos)]) == 1
    manifest = json.loads((videos.parent / "poses" / "manifest.json").read_text())
    assert manifest["extractor"]["model_complexity"] == 1
    assert len(manifest["recordings"]) == 3

    assert batch.main([str(videos / "missing")]) == 2
