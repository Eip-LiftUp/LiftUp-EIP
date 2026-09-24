Squat video downloader
======================

This small tool searches YouTube for squat exercise videos and downloads them
for later processing. It purposefully does not trim, label, or reformat videos
Usage
-----

Install dependencies:

```bash
python3 -m pip install -r tools/squat_downloader/requirements.txt
```

Run the downloader (saves to `squat_videos` by default):

```bash
python3 tools/squat_downloader/download_squats.py --per-query 5
```

To provide custom search queries:

```bash
python3 tools/squat_downloader/download_squats.py -q "squat tutorial" "bad squat form"
```

Per-query folders
-----------------

When run with `--separate` (default), the script creates one sanitized subfolder
per query under the output directory. For example, querying `"bad lean"` will
save videos into `squat_videos/bad_lean/`.

You can also prefix custom queries with `good:` or `bad:` to add a label, e.g.
`good:squat tutorial` or `bad:wrong squat form`. Prefixes are not required for
separate folders — the folder name is generated from the query text itself.

Notes
-----
- This uses `yt-dlp` and downloads video-only streams (no audio) to save space.
- A download archive `squat_downloads_archive.txt` is used to avoid duplicate
  downloads.
- Make sure you respect the target site's terms of service and copyright when
  collecting data. Consider preferring Creative Commons content if needed.
