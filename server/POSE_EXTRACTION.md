# Pose extraction for training (squat)

Issue #78. Turns the squat videos collected by the scraper into skeletons the
ML pipeline (`app/ml`) can train on.

```
#76 download ──► #77 trim ──► #78 pose extraction ──► #79 normalization ──► #80 labelled dataset ──► #81 training
tools/squat_downloader   tools/crop_squat_video.py   app/ml/pose/batch.py   app/ml/preprocessing   app/ml/training
```

Poses are extracted with `MediaPipeExtractor` (`app/ml/pose/extractor.py`), the
same extractor and MediaPipe version (0.10.9) the service uses on users'
videos: the model trains on the skeletons it will see in production.

## Folders

Everything lives under `server/data/datasets/`, which git ignores:

```
server/data/datasets/squat/
  videos/<query>/<youtube_id>.webm              # downloaded
  videos/<query>/<youtube_id>_squat_only.mp4    # trimmed
  poses/<query>/<youtube_id>.npz                # one PoseSequence per video
  poses/manifest.json                           # index of the extraction
```

## Steps

Commands run from the repository root.

**1. Download** (on the host, see `tools/squat_downloader/README.md`):

```bash
python3 tools/squat_downloader/download_squats.py -o server/data/datasets/squat/videos
```

**2. Trim** each downloaded video (on the host, see `tools/crop_squats_README.md`):

```bash
find server/data/datasets/squat/videos -type f ! -name '*_squat_only.mp4' \
  -exec python3 tools/crop_squat_video.py {} \;
```

**3. Extract the poses** inside the AI service container (Python 3.11 with
MediaPipe 0.10.9; this version does not install on Python 3.12):

```bash
# Container already running (docker ps): paths are relative to /app
docker exec liftup-ai-service python -m app.ml.pose.batch data/datasets/squat/videos 2>/dev/null

# Otherwise, a one-off container from server/docker-compose.yml
docker compose -f server/docker-compose.yml run --rm ml-service \
  python -m app.ml.pose.batch data/datasets/squat/videos 2>/dev/null
```

`2>/dev/null` hides MediaPipe's `gl_context` errors: the container has no GPU
and MediaPipe falls back to the CPU. The script's own output (progress and
summary) goes to stdout.

| Option | Default | |
|---|---|---|
| `--output-dir` | `<videos_dir>/../poses` | Where to write the `.npz` files and the manifest |
| `--min-detection` | `0.8` | Share of frames with a person below which a video is flagged `low_detection` |
| `--model-complexity` | `1` | MediaPipe model (0, 1 or 2) |
| `--exercise` | `squat` | Exercise recorded in the manifest |
| `--force` | off | Extract again the videos already extracted |

Every video under the folder is extracted (`.mp4`, `.webm`, `.mkv`, `.mov`,
`.avi`, `.m4v`, in subfolders too), whatever its name. When a trimmed clip
(`abc123_squat_only.mp4`) sits next to its original (`abc123.webm`), only the
trimmed clip is used, under the id `<query>/abc123`, so the same video is never
in the dataset twice. Untrimmed videos can be extracted as they are.

Running the command again only extracts what is new:
- videos already extracted are skipped, unless the file changed or was
  replaced by its trimmed clip;
- failed videos are retried;
- if `--model-complexity` or the MediaPipe version changes, every video is
  extracted again, so the dataset never mixes models.

One broken video does not stop the run. The manifest is saved after each
video, so an interrupted run keeps its progress. The exit code is `1` when at
least one video failed.

## Manifest

```json
{
  "version": 1,
  "exercise": "squat",
  "videos_dir": "data/datasets/squat/videos",
  "extractor": {"name": "mediapipe", "mediapipe_version": "0.10.9", "model_complexity": 1},
  "updated_at": "2026-11-10T11:37:42+00:00",
  "recordings": [
    {
      "id": "bad_squat_form_exercise/abc123",
      "video": "bad_squat_form_exercise/abc123_squat_only.mp4",
      "query": "bad_squat_form_exercise",
      "youtube_id": "abc123",
      "status": "ok",
      "poses": "bad_squat_form_exercise/abc123.npz",
      "fps": 29.97,
      "frames": 812,
      "duration_s": 27.094,
      "width": 1280,
      "height": 720,
      "detection_rate": 0.9741,
      "video_size": 5234112,
      "error": null,
      "extracted_at": "2026-11-10T11:37:40+00:00"
    }
  ]
}
```

| `status` | Meaning |
|---|---|
| `ok` | Person found in at least `--min-detection` of the frames |
| `low_detection` | Poses saved, but the person is often missing: check the video before using it |
| `error` | Extraction failed, see `error`; no `.npz` |

`query` is the downloader's folder, i.e. the search that found the video
(`bad_squat_form_exercise`, `proper_squat_form_exercise`…). The downloader does
not record a good/bad label: the query is only a hint for labelling (#80).

## Using the poses

```python
from app.ml.pose.batch import iter_sequences
from app.ml.training.dataset import LabelledRecording

for entry, sequence in iter_sequences("data/datasets/squat/poses"):  # status "ok" only
    LabelledRecording(
        sequence=sequence,               # PoseSequence: (frames, 33, 4) + fps + metadata
        subject_id=entry.youtube_id,     # one video ≈ one person, for subject-grouped training
        rep_labels=[...],                # from labelling (#80)
        recording_id=entry.id,
    )
```

A single file loads with `PoseSequence.load(path)`. The `.npz` holds
`landmarks` (float32, frames × 33 landmarks × x/y/z/visibility), `fps` and
`metadata` (JSON: source, width, height, MediaPipe version, model complexity).
Frames where nobody was detected are all zeros.

## Caveat for normalization (#79)

MediaPipe gives `x` as a fraction of the frame width and `y` as a fraction of
its height. On a 16:9 video, one unit of `x` is 1.78 times longer than one unit
of `y`, so angles computed on raw coordinates are skewed. The current
`normalize()` does not correct this; `width` and `height` are stored in the
metadata and the manifest so that it can (e.g. multiply `x` by `width / height`
before computing angles).
