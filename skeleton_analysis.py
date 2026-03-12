#!/usr/bin/env python3
"""
Skeleton Detection with MediaPipe + OpenCV
==========================================
Analyse une vidéo, détecte le squelette sur chaque frame,
et exporte automatiquement les coordonnées en CSV.

Cas d'usage : coach IA — corriger les mouvements d'un exercice
en analysant les keypoints frame par frame.

Compatible avec MediaPipe 0.10.13+ (nouvelle API Tasks Vision)

Installation :
    pip install -r requirements.txt

Usage :
    # Analyser une vidéo → CSV généré automatiquement
    python skeleton_detection.py --video squat.mp4

    # Idem mais sans fenêtre de visualisation (plus rapide)
    python skeleton_detection.py --video squat.mp4 --no-display

    # Nommer le CSV de sortie
    python skeleton_detection.py --video squat.mp4 --output mon_squat.csv

    # Tester en live avec la webcam (optionnel)
    python skeleton_detection.py --webcam
"""

import cv2
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision
import csv
import time
import argparse
import urllib.request
import os
import sys
from pathlib import Path
from datetime import datetime


# ─────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────

KEYPOINT_NAMES = {
    0:  "nose",
    1:  "left_eye_inner",    2:  "left_eye",          3:  "left_eye_outer",
    4:  "right_eye_inner",   5:  "right_eye",          6:  "right_eye_outer",
    7:  "left_ear",          8:  "right_ear",
    9:  "mouth_left",        10: "mouth_right",
    11: "left_shoulder",     12: "right_shoulder",
    13: "left_elbow",        14: "right_elbow",
    15: "left_wrist",        16: "right_wrist",
    17: "left_pinky",        18: "right_pinky",
    19: "left_index",        20: "right_index",
    21: "left_thumb",        22: "right_thumb",
    23: "left_hip",          24: "right_hip",
    25: "left_knee",         26: "right_knee",
    27: "left_ankle",        28: "right_ankle",
    29: "left_heel",         30: "right_heel",
    31: "left_foot_index",   32: "right_foot_index",
}

# Couleurs par zone du corps (BGR)
COLORS = {
    "face":      (255, 200, 100),
    "torso":     (100, 255, 100),
    "left_arm":  (255, 150,  50),
    "right_arm": ( 50, 150, 255),
    "left_leg":  (255, 255, 100),
    "right_leg": (100, 255, 255),
}

CONNECTIONS = [
    (0, 1, "face"),   (1, 2, "face"),   (2, 3, "face"),
    (0, 4, "face"),   (4, 5, "face"),   (5, 6, "face"),
    (7, 9, "face"),   (8, 10, "face"),
    (11, 12, "torso"), (11, 23, "torso"), (12, 24, "torso"), (23, 24, "torso"),
    (11, 13, "left_arm"),  (13, 15, "left_arm"),
    (15, 17, "left_arm"),  (15, 19, "left_arm"),  (15, 21, "left_arm"),
    (12, 14, "right_arm"), (14, 16, "right_arm"),
    (16, 18, "right_arm"), (16, 20, "right_arm"), (16, 22, "right_arm"),
    (23, 25, "left_leg"),  (25, 27, "left_leg"),
    (27, 29, "left_leg"),  (27, 31, "left_leg"),
    (24, 26, "right_leg"), (26, 28, "right_leg"),
    (28, 30, "right_leg"), (28, 32, "right_leg"),
]

KEY_JOINTS  = {11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28}
WINDOW_NAME = "Skeleton Detection — MediaPipe"
DISPLAY_W   = 1280
DISPLAY_H   = 720
CSV_FIELDS  = ["frame", "timestamp_sec", "keypoint_id", "keypoint_name",
               "x", "y", "z", "visibility"]


# ─────────────────────────────────────────────
# Utilitaires
# ─────────────────────────────────────────────

def download_model(model_path="pose_landmarker_full.task"):
    if os.path.exists(model_path):
        return model_path
    url = (
        "https://storage.googleapis.com/mediapipe-models/"
        "pose_landmarker/pose_landmarker_full/float16/latest/"
        "pose_landmarker_full.task"
    )
    print(f"[INFO] Téléchargement du modèle → {model_path} ...")
    urllib.request.urlretrieve(url, model_path)
    print("[INFO] Modèle téléchargé ✓")
    return model_path


class LM:
    __slots__ = ("x", "y", "z", "visibility")
    def __init__(self, x, y, z, visibility):
        self.x, self.y, self.z, self.visibility = x, y, z, visibility

def landmarks_to_list(pose_landmarks):
    return [LM(lm.x, lm.y, lm.z, lm.visibility) for lm in pose_landmarks]

def format_duration(seconds):
    m, s = divmod(int(seconds), 60)
    return f"{m:02d}:{s:02d}"

def make_landmarker():
    base_options = mp_python.BaseOptions(model_asset_path=download_model())
    options = mp_vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=mp_vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=0.5,
        min_pose_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )
    return mp_vision.PoseLandmarker.create_from_options(options)


# ─────────────────────────────────────────────
# Dessin
# ─────────────────────────────────────────────

def draw_skeleton(frame, landmarks, show_labels=False):
    h, w = frame.shape[:2]
    for (si, ei, zone) in CONNECTIONS:
        s, e = landmarks[si], landmarks[ei]
        if s.visibility < 0.5 or e.visibility < 0.5:
            continue
        cv2.line(frame,
                 (int(s.x * w), int(s.y * h)),
                 (int(e.x * w), int(e.y * h)),
                 COLORS[zone], 2, cv2.LINE_AA)
    for idx, lm in enumerate(landmarks):
        if lm.visibility < 0.5:
            continue
        x, y   = int(lm.x * w), int(lm.y * h)
        radius = 6 if idx in KEY_JOINTS else 3
        cv2.circle(frame, (x, y), radius + 1, (40, 40, 40), -1)
        cv2.circle(frame, (x, y), radius, (255, 255, 255), -1)
        if show_labels and idx in KEY_JOINTS:
            cv2.putText(frame, KEYPOINT_NAMES[idx].replace("_", " "),
                        (x + 8, y - 4), cv2.FONT_HERSHEY_SIMPLEX,
                        0.38, (220, 220, 220), 1)
    return frame


def draw_ui_video(frame, current_frame, total_frames, fps_proc,
                  person_detected, output_csv, elapsed):
    h, w     = frame.shape[:2]
    font     = cv2.FONT_HERSHEY_SIMPLEX
    progress = current_frame / total_frames if total_frames > 0 else 0
    eta      = ((elapsed / current_frame) * (total_frames - current_frame)
                if current_frame > 0 else 0)

    overlay = frame.copy()
    cv2.rectangle(overlay, (0, 0), (w, 150), (15, 15, 15), -1)
    cv2.addWeighted(overlay, 0.7, frame, 0.3, 0, frame)

    sc = (80, 220, 80) if person_detected else (80, 80, 220)
    st = "SQUELETTE DETECTE" if person_detected else "AUCUNE PERSONNE"

    cv2.putText(frame, f"Frame : {current_frame} / {total_frames}", (14,  30), font, 0.7, (255,255,255), 2)
    cv2.putText(frame, f"Traitement : {fps_proc:.1f} fps",          (14,  60), font, 0.7, (255,255,255), 2)
    cv2.putText(frame, st,                                           (14,  90), font, 0.6, sc, 2)
    cv2.putText(frame, f"CSV → {Path(output_csv).name}",            (14, 118), font, 0.5, (80,220,220), 1)
    cv2.putText(frame, f"ETA : {format_duration(eta)}",             (14, 140), font, 0.5, (180,180,180), 1)

    # Barre de progression
    cv2.rectangle(frame, (0, 152), (w, 162), (50, 50, 50), -1)
    cv2.rectangle(frame, (0, 152), (int(w * progress), 162), (80, 200, 80), -1)

    # Barre raccourcis bas
    cv2.rectangle(frame, (0, h - 36), (w, h), (15, 15, 15), -1)
    cv2.putText(frame, "Q : quitter    L : labels    ESPACE : pause",
                (10, h - 12), font, 0.5, (200, 200, 200), 1)
    return frame




# ─────────────────────────────────────────────
# Export CSV
# ─────────────────────────────────────────────

def extract_keypoints(landmarks, frame_index, timestamp_sec):
    return [{
        "frame":         frame_index,
        "timestamp_sec": round(timestamp_sec, 4),
        "keypoint_id":   idx,
        "keypoint_name": KEYPOINT_NAMES[idx],
        "x":             round(lm.x, 6),
        "y":             round(lm.y, 6),
        "z":             round(lm.z, 6),
        "visibility":    round(lm.visibility, 4),
    } for idx, lm in enumerate(landmarks)]


# ─────────────────────────────────────────────
# Mode analyse vidéo (principal)
# ─────────────────────────────────────────────

def run_video(video_path, output_csv, no_display=False, show_labels=False):
    """
    Analyse un fichier vidéo frame par frame.
    Exporte TOUTES les coordonnées de squelette dans un CSV automatiquement.
    """
    if not os.path.exists(video_path):
        print(f"[ERREUR] Fichier vidéo introuvable : {video_path}")
        sys.exit(1)

    landmarker   = make_landmarker()
    cap          = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    video_fps    = cap.get(cv2.CAP_PROP_FPS) or 30.0

    print(f"\n{'='*50}")
    print(f"  Vidéo        : {video_path}")
    print(f"  Total frames : {total_frames}")
    print(f"  FPS vidéo    : {video_fps:.1f}")
    print(f"  CSV output   : {output_csv}")
    print(f"{'='*50}\n")

    if not no_display:
        cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(WINDOW_NAME, DISPLAY_W, DISPLAY_H)

    csv_file   = open(output_csv, "w", newline="", encoding="utf-8")
    csv_writer = csv.DictWriter(csv_file, fieldnames=CSV_FIELDS)
    csv_writer.writeheader()

    frame_count     = 0
    detected_frames = 0
    fps_proc        = 0.0
    fps_timer       = time.time()
    fps_frames      = 0
    start_time      = time.time()
    paused          = False

    print("[INFO] Analyse en cours — Q pour quitter, ESPACE pour pause/reprendre\n")

    try:
        while True:
            # Gestion pause
            if paused and not no_display:
                key = cv2.waitKey(100) & 0xFF
                if key == ord("q"):
                    break
                elif key == ord(" "):
                    paused = False
                    print("[INFO] Reprise")
                continue

            ret, frame = cap.read()
            if not ret:
                print("\n[INFO] Vidéo terminée ✓")
                break

            if not no_display:
                if cv2.getWindowProperty(WINDOW_NAME, cv2.WND_PROP_VISIBLE) < 1:
                    break

            frame_count += 1
            fps_frames  += 1
            elapsed      = time.time() - start_time

            timestamp_ms  = int(cap.get(cv2.CAP_PROP_POS_MSEC))
            timestamp_sec = timestamp_ms / 1000.0

            if fps_frames >= 15:
                fps_proc   = fps_frames / (time.time() - fps_timer)
                fps_timer  = time.time()
                fps_frames = 0

            # ── Détection ──
            rgb      = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            result   = landmarker.detect_for_video(mp_image, timestamp_ms)

            person_detected = len(result.pose_landmarks) > 0

            if person_detected:
                detected_frames += 1
                landmarks = landmarks_to_list(result.pose_landmarks[0])
                # Export CSV automatique à chaque frame détectée
                csv_writer.writerows(
                    extract_keypoints(landmarks, frame_count, timestamp_sec)
                )
                if not no_display:
                    frame = draw_skeleton(frame, landmarks, show_labels)

            # ── Affichage ──
            if not no_display:
                frame = draw_ui_video(frame, frame_count, total_frames,
                                      fps_proc, person_detected, output_csv, elapsed)
                cv2.imshow(WINDOW_NAME, cv2.resize(frame, (DISPLAY_W, DISPLAY_H)))

                key = cv2.waitKey(1) & 0xFF
                if key == ord("q"):
                    break
                elif key == ord("l"):
                    show_labels = not show_labels
                elif key == ord(" "):
                    paused = True
                    print("[INFO] Pause")
            else:
                # Progression dans le terminal (mode headless)
                if frame_count % 30 == 0 or frame_count == total_frames:
                    pct = frame_count / total_frames * 100
                    bar = "█" * int(pct / 2) + "░" * (50 - int(pct / 2))
                    print(f"\r  [{bar}] {pct:5.1f}%  ({frame_count}/{total_frames})",
                          end="", flush=True)

    finally:
        cap.release()
        csv_file.close()
        landmarker.close()
        if not no_display:
            cv2.destroyAllWindows()

    total_time = time.time() - start_time
    pct_det    = detected_frames / frame_count * 100 if frame_count else 0

    print(f"\n\n{'='*50}")
    print(f"  Analyse terminée !")
    print(f"{'='*50}")
    print(f"  Frames totales    : {frame_count}")
    print(f"  Frames détectées  : {detected_frames}  ({pct_det:.1f}%)")
    print(f"  Durée traitement  : {format_duration(total_time)}")
    print(f"  CSV généré        : {output_csv}")
    print(f"  Lignes CSV        : {detected_frames * 33}  (33 keypoints × {detected_frames} frames)")
    print(f"{'='*50}\n")


# ─────────────────────────────────────────────
# Point d'entrée
# ─────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Analyse vidéo + détection squelette → CSV",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog="""
Exemples :
  python skeleton_detection.py --video squat.mp4
  python skeleton_detection.py --video squat.mp4 --output squat_keypoints.csv
  python skeleton_detection.py --video squat.mp4 --no-display
  python skeleton_detection.py --video squat.mp4 --labels
        """
    )

    parser.add_argument("--video",      metavar="FICHIER", required=True,
                        help="Chemin vers la vidéo à analyser (mp4, avi, mov...)")
    parser.add_argument("--output",     metavar="FICHIER.csv", default=None,
                        help="Nom du CSV de sortie (défaut : nom_video_keypoints.csv)")
    parser.add_argument("--no-display", action="store_true",
                        help="Pas de fenêtre — traitement headless (plus rapide)")
    parser.add_argument("--labels",     action="store_true",
                        help="Afficher les noms des articulations sur la vidéo")

    args = parser.parse_args()

    if args.output is None:
        args.output = f"{Path(args.video).stem}_keypoints.csv"

    run_video(
        video_path  = args.video,
        output_csv  = args.output,
        no_display  = args.no_display,
        show_labels = args.labels,
    )