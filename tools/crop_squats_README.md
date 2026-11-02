# Crop squat video

This utility keeps only the parts of a video where a person is doing a squat-like movement.

It uses a lightweight OpenCV motion detector rather than a pose-tracking model: it compares successive frames, isolates moving regions, and looks for the vertical motion and body-shape change typical of squat repetitions. The result is a heuristic trim that works well for short, front-facing recordings and does not depend on a specific MediaPipe API version.

## What it does

- Reads an input video
- Downsizes large frames to keep processing fast
- Compares consecutive frames to detect motion
- Finds the largest moving foreground region
- Scores the region for squat-like vertical motion
- Smooths the motion scores and merges nearby detections
- Adds a small padding before/after each segment
- Writes a new trimmed video containing only the detected squat windows

## Requirements

Install the video/vision dependencies in the environment you use to run this script.

```bash
python -m pip install opencv-python numpy
```

If your project already has a Python environment for ML/video work, use that instead of the system Python.

## Usage

From the repository root:

```bash
python tools/crop_squat_video.py path/to/video.mp4
```

Output:

```text
path/to/video_squat_only.mp4
```

### Custom output name

```bash
python tools/crop_squat_video.py path/to/video.mp4 --output output.mp4
```

### Adjust detection sensitivity

```bash
python tools/crop_squat_video.py path/to/video.mp4 --threshold 0.35
```

Lower values keep more frames; higher values are stricter.

### Adjust padding and segment length

```bash
python tools/crop_squat_video.py path/to/video.mp4 \
  --padding-seconds 1.0 \
  --min-segment-seconds 1.5 \
  --max-gap-seconds 0.5
```

### Notes

- The output is a trimmed MP4 video; it does not preserve audio.
- This is a heuristic detector and works best when the person is clearly visible and mostly centered in the frame.
- If the script finds nothing, try lowering `--threshold` or using a clearer squat video.
- The detector is intentionally lightweight: it prefers robustness over a heavy pose model and is easier to run in a normal project environment.

## Typical workflow

```bash
python tools/crop_squat_video.py squat_input.mp4 --output squat_trimmed.mp4
```

Then review the trimmed video and adjust the threshold if needed.
