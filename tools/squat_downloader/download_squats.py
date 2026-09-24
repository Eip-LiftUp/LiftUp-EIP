#!/usr/bin/env python3
"""
Download squat videos from YouTube using yt-dlp.

This script performs searches on YouTube (via yt-dlp's `ytsearch`) and downloads
the top N results for each query. It supports simple filtering by duration and
keeps a download archive to avoid duplicates.

Notes:
- This only searches and downloads video files. No trimming, labeling or
  re-formatting is performed.
- Use queries such as "proper squat form", "bad squat form", "squat mistake",
  etc. to collect both good and bad examples.
"""

from __future__ import annotations

import argparse
import os
import re
from typing import List, Optional, Tuple

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

try:
    from yt_dlp import YoutubeDL
except Exception:
    print("ERROR: yt-dlp is required. Install with: pip install -r requirements.txt")
    raise


def build_queries(good: int, bad: int) -> List[tuple[str, int, str]]:
    # Default queries. Users can also pass custom queries via --queries
    good_queries = [
        "proper squat form",
        "how to squat correctly",
        "perfect squat technique",
        "squat demonstration",
    ]
    bad_queries = [
        "bad squat form",
        "squat mistakes",
        "wrong squat technique",
        "knees caving squat",
    ]

    qlist: List[tuple[str, int, str]] = []
    for q in good_queries:
        qlist.append((q + " exercise", good, 'good'))
    for q in bad_queries:
        qlist.append((q + " exercise", bad, 'bad'))
    return qlist


def download_for_query(ydl: YoutubeDL, query: str, per_query: int, min_dur: Optional[int], max_dur: Optional[int]):
    search_str = f"ytsearch{per_query}:{query}"
    print(f"Searching: {query} -> retrieving up to {per_query} results")

    try:
        info = ydl.extract_info(search_str, download=False)
    except Exception as e:
        print(f"Search failed for '{query}': {e}")
        return

    entries = info.get('entries') or []
    urls_to_download: List[str] = []
    for entry in entries:
        if not entry:
            continue
        duration = entry.get('duration')
        if min_dur is not None and duration is not None and duration < min_dur:
            print(f" Skipping {entry.get('id')} (too short: {duration}s)")
            continue
        if max_dur is not None and duration is not None and duration > max_dur:
            print(f" Skipping {entry.get('id')} (too long: {duration}s)")
            continue
        url = entry.get('webpage_url') or entry.get('url')
        if url:
            urls_to_download.append(url)

    if not urls_to_download:
        print(f" No candidate videos for query: {query}")
        return

    for u in urls_to_download:
        try:
            print(f" Downloading: {u}")
            ydl.download([u])
        except Exception as e:
            print(f"  Failed to download {u}: {e}")


def main():
    parser = argparse.ArgumentParser(description="Search and download squat videos using yt-dlp")
    parser.add_argument('--output-dir', '-o', default='squat_videos', help='Directory to save videos')
    parser.add_argument('--per-query', '-n', type=int, default=5, help='Number of results per query to consider')
    parser.add_argument('--good-count', type=int, default=3, help='Multiplier for good-form queries')
    parser.add_argument('--bad-count', type=int, default=3, help='Multiplier for bad-form queries')
    parser.add_argument('--queries', '-q', nargs='*', help='Custom search queries to run (overrides built-in queries if provided)')
    parser.add_argument('--min-duration', type=int, help='Minimum video duration in seconds to download')
    parser.add_argument('--max-duration', type=int, help='Maximum video duration in seconds to download')
    parser.add_argument('--archive', default=None, help='Download archive file to avoid duplicates (default: tools/squat_downloader/squat_downloads_archive.txt)')
    parser.add_argument('--quiet', action='store_true', help='Suppress verbose output from yt-dlp')
    parser.add_argument('--separate', action=argparse.BooleanOptionalAction, default=True, help='Separate downloads into `good`/`bad` subfolders (can use --no-separate to disable)')
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    archive_path = args.archive or os.path.join(SCRIPT_DIR, 'squat_downloads_archive.txt')

    # Build query list with labels. Custom queries can be prefixed with "good:" or "bad:"
    if args.queries:
        query_list: List[Tuple[str, int, str]] = []
        for q in args.queries:
            if ':' in q:
                prefix, rest = q.split(':', 1)
                label = prefix.strip().lower()
                if label in ('good', 'bad'):
                    query_list.append((rest.strip(), args.per_query, label))
                else:
                    query_list.append((q, args.per_query, 'custom'))
            else:
                query_list.append((q, args.per_query, 'custom'))
    else:
        query_list = build_queries(args.good_count, args.bad_count)

    def _sanitize_folder(name: str) -> str:
        s = name.lower()
        s = re.sub(r"[^a-z0-9]+", "_", s)
        s = re.sub(r"_+", "_", s)
        s = s.strip("_")
        return s[:120] or "query"

    for q, perq, label in query_list:
        # Determine destination directory for this query. When `--separate` is set,
        # create a folder per query using a sanitized version of the query text.
        if args.separate:
            folder_name = _sanitize_folder(q)
            dest_dir = os.path.join(args.output_dir, folder_name)
        else:
            dest_dir = args.output_dir
        os.makedirs(dest_dir, exist_ok=True)

        ydl_opts = {
            # Request video-only to avoid downloading audio stream
            'format': 'bestvideo/best',
            'outtmpl': os.path.join(dest_dir, '%(id)s.%(ext)s'),
            'noplaylist': True,
            'ignoreerrors': True,
            'merge_output_format': 'mp4',
            'download_archive': archive_path,
        }
        if args.quiet:
            ydl_opts['quiet'] = True

        with YoutubeDL(ydl_opts) as ydl:
            download_for_query(ydl, q, perq, args.min_duration, args.max_duration)


if __name__ == '__main__':
    main()
