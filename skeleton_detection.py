"""
Skeleton Detection with MediaPipe + OpenCV
==========================================
Détecte 33 keypoints du corps humain via webcam,
visualise les articulations, et exporte les coordonnées en CSV.

Compatible avec MediaPipe 0.10.13+ (nouvelle API Tasks Vision)

Installation :
    pip install mediapipe opencv-python

Usage :
    python skeleton_detection.py
    python skeleton_detection.py --source 0          # webcam (défaut)
    python skeleton_detection.py --source video.mp4  # fichier vidéo
    python skeleton_detection.py --export            # active l'export CSV
    python skeleton_detection.py --no-display        # sans fenêtre (headless)
    python skeleton_detection.py --labels            # affiche les noms
"""

import cv2
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision
from mediapipe.tasks.python.components.containers import landmark as mp_landmark
import csv
import time
import argparse
import urllib.request
import os
from pathlib import Path
from datetime import datetime


# ─────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────

# Les 33 keypoints MediaPipe Pose et leur index
KEYPOINT_NAMES = {
    0:  "nose",
    1:  "left_eye_inner",    2:  "left_eye",       3:  "left_eye_outer",
    4:  "right_eye_inner",   5:  "right_eye",       6:  "right_eye_outer",
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
    "face":        (255, 200, 100),   # bleu clair
    "torso":       (100, 255, 100),   # vert
    "left_arm":    (255, 100, 100),   # bleu
    "right_arm":   (100, 100, 255),   # rouge
    "left_leg":    (255, 255, 100),   # cyan
    "right_leg":   (100, 255, 255),   # jaune
}

# Connexions entre keypoints (paires) avec leur couleur
CONNECTIONS = [
    # Visage
    (0, 1, "face"), (1, 2, "face"), (2, 3, "face"),
    (0, 4, "face"), (4, 5, "face"), (5, 6, "face"),
    (7, 9, "face"), (8, 10, "face"),
    # Torse
    (11, 12, "torso"), (11, 23, "torso"), (12, 24, "torso"), (23, 24, "torso"),
    # Bras gauche
    (11, 13, "left_arm"), (13, 15, "left_arm"),
    (15, 17, "left_arm"), (15, 19, "left_arm"), (15, 21, "left_arm"),
    # Bras droit
    (12, 14, "right_arm"), (14, 16, "right_arm"),
    (16, 18, "right_arm"), (16, 20, "right_arm"), (16, 22, "right_arm"),
    # Jambe gauche
    (23, 25, "left_leg"), (25, 27, "left_leg"),
    (27, 29, "left_leg"), (27, 31, "left_leg"),
    # Jambe droite
    (24, 26, "right_leg"), (26, 28, "right_leg"),
    (28, 30, "right_leg"), (28, 32, "right_leg"),
]

# Keypoints "importants" à afficher avec un cercle plus grand
KEY_JOINTS = {11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28}


# ─────────────────────────────────────────────
# Fonctions principales
# ─────────────────────────────────────────────

def landmarks_to_list(pose_landmarks):
    """
    Convertit les landmarks MediaPipe Tasks en liste simple d'objets
    avec attributs x, y, z, visibility pour compatibilité avec le reste du code.
    """
    class LM:
        def __init__(self, x, y, z, visibility):
            self.x = x
            self.y = y
            self.z = z
            self.visibility = visibility

    return [LM(lm.x, lm.y, lm.z, lm.visibility) for lm in pose_landmarks]


def draw_skeleton(frame, landmarks, show_labels=False):
    """Dessine le squelette sur le frame."""
    h, w = frame.shape[:2]

    # 1. Dessiner les connexions (os)
    for (start_idx, end_idx, zone) in CONNECTIONS:
        start = landmarks[start_idx]
        end   = landmarks[end_idx]

        # Ignorer les points peu visibles
        if start.visibility < 0.5 or end.visibility < 0.5:
            continue

        x1, y1 = int(start.x * w), int(start.y * h)
        x2, y2 = int(end.x * w),   int(end.y * h)
        color = COLORS[zone]

        cv2.line(frame, (x1, y1), (x2, y2), color, 2, cv2.LINE_AA)

    # 2. Dessiner les keypoints (articulations)
    for idx, lm in enumerate(landmarks):
        if lm.visibility < 0.5:
            continue

        x, y = int(lm.x * w), int(lm.y * h)

        radius = 6 if idx in KEY_JOINTS else 3
        color  = (255, 255, 255)
        border = (50, 50, 50)

        cv2.circle(frame, (x, y), radius + 1, border, -1)
        cv2.circle(frame, (x, y), radius,     color,  -1)

        if show_labels and idx in KEY_JOINTS:
            name = KEYPOINT_NAMES[idx].replace("_", " ")
            cv2.putText(frame, name, (x + 8, y - 4),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.35, (200, 200, 200), 1)

    return frame


def extract_keypoints(landmarks, frame_index, timestamp):
    """Extrait les coordonnées de tous les keypoints pour l'export CSV."""
    rows = []
    for idx, lm in enumerate(landmarks):
        rows.append({
            "frame":         frame_index,
            "timestamp":     round(timestamp, 4),
            "keypoint_id":   idx,
            "keypoint_name": KEYPOINT_NAMES[idx],
            "x":             round(lm.x, 6),
            "y":             round(lm.y, 6),
            "z":             round(lm.z, 6),
            "visibility":    round(lm.visibility, 4),
        })
    return rows


def draw_ui(frame, fps, frame_count, person_detected, export_enabled, export_path=None):
    """Affiche les infos de debug en overlay — texte lisible à 1280x720."""
    h, w = frame.shape[:2]

    # Fond semi-transparent
    overlay = frame.copy()
    cv2.rectangle(overlay, (0, 0), (380, 140), (20, 20, 20), -1)
    cv2.addWeighted(overlay, 0.65, frame, 0.35, 0, frame)

    status_color = (80, 220, 80) if person_detected else (80, 80, 220)
    status_text  = "✓ PERSONNE DETECTEE" if person_detected else "✗ AUCUNE PERSONNE"

    font       = cv2.FONT_HERSHEY_SIMPLEX
    font_big   = 0.75
    font_small = 0.52

    cv2.putText(frame, f"FPS    : {fps:.1f}",        (14, 32),  font, font_big,   (255, 255, 255), 2)
    cv2.putText(frame, f"Frame  : {frame_count}",    (14, 66),  font, font_big,   (255, 255, 255), 2)
    cv2.putText(frame, status_text,                  (14, 100), font, font_small, status_color,    2)

    if export_enabled and export_path:
        fname = Path(export_path).name
        cv2.putText(frame, f"CSV : {fname}", (14, 128), font, font_small, (80, 220, 220), 2)

    # Barre raccourcis en bas
    bar_y = h - 14
    cv2.rectangle(frame, (0, h - 36), (w, h), (20, 20, 20), -1)
    cv2.putText(frame, "Q : quitter    L : labels on/off    E : export CSV",
                (10, bar_y), font, font_small, (200, 200, 200), 1)

    return frame


# ─────────────────────────────────────────────
# Boucle principale
# ─────────────────────────────────────────────

def download_model(model_path="pose_landmarker_full.task"):
    """Télécharge le modèle MediaPipe si absent."""
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


def run(source=0, export=False, no_display=False, show_labels=False):
    # ── Téléchargement du modèle ──
    model_path = download_model()

    # ── Init MediaPipe PoseLandmarker (nouvelle API 0.10+) ──
    base_options = mp_python.BaseOptions(model_asset_path=model_path)
    options = mp_vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=mp_vision.RunningMode.VIDEO,   # flux vidéo temps réel
        num_poses=1,
        min_pose_detection_confidence=0.5,
        min_pose_presence_confidence=0.5,
        min_tracking_confidence=0.5,
    )
    landmarker = mp_vision.PoseLandmarker.create_from_options(options)

    # ── Init capture vidéo ──
    try:
        src = int(source)
    except ValueError:
        src = source

    cap = cv2.VideoCapture(src)
    if not cap.isOpened():
        raise RuntimeError(f"Impossible d'ouvrir la source : {source}")

    # ── Fichier CSV d'export ──
    export_path = None
    csv_writer  = None
    csv_file    = None
    all_rows    = []

    def open_csv():
        nonlocal export_path, csv_writer, csv_file
        ts          = datetime.now().strftime("%Y%m%d_%H%M%S")
        export_path = f"keypoints_{ts}.csv"
        csv_file    = open(export_path, "w", newline="")
        fieldnames  = ["frame", "timestamp", "keypoint_id", "keypoint_name",
                       "x", "y", "z", "visibility"]
        csv_writer  = csv.DictWriter(csv_file, fieldnames=fieldnames)
        csv_writer.writeheader()
        print(f"[INFO] Export CSV activé → {export_path}")

    if export:
        open_csv()

    # ── Compteurs ──
    frame_count     = 0
    fps             = 0.0
    fps_timer       = time.time()
    fps_frames      = 0
    person_detected = False

    # ── Créer la fenêtre redimensionnable une seule fois ──
    WINDOW_NAME = "Skeleton Detection — MediaPipe"
    DISPLAY_W, DISPLAY_H = 1280, 720   # taille d'affichage souhaitée

    if not no_display:
        cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(WINDOW_NAME, DISPLAY_W, DISPLAY_H)

    print("[INFO] Démarrage — appuyez sur Q pour quitter, ou fermez la fenêtre")

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("[INFO] Fin du flux vidéo")
                break

            # ── Détecter si la fenêtre a été fermée (croix) ──
            if not no_display:
                if cv2.getWindowProperty(WINDOW_NAME, cv2.WND_PROP_VISIBLE) < 1:
                    print("[INFO] Fenêtre fermée — arrêt du programme")
                    break

            frame_count += 1
            fps_frames  += 1

            # Timestamp en millisecondes (requis par la nouvelle API)
            timestamp_ms = int(cap.get(cv2.CAP_PROP_POS_MSEC))
            if timestamp_ms == 0:
                timestamp_ms = int(frame_count * (1000 / 30))  # fallback 30fps

            # Calcul FPS
            if fps_frames >= 30:
                fps        = fps_frames / (time.time() - fps_timer)
                fps_timer  = time.time()
                fps_frames = 0

            # ── Détection MediaPipe ──
            rgb        = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image   = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            result     = landmarker.detect_for_video(mp_image, timestamp_ms)

            person_detected = len(result.pose_landmarks) > 0

            if person_detected:
                landmarks = landmarks_to_list(result.pose_landmarks[0])

                if not no_display:
                    frame = draw_skeleton(frame, landmarks, show_labels)

                if export and csv_writer:
                    rows = extract_keypoints(landmarks, frame_count, timestamp_ms / 1000)
                    csv_writer.writerows(rows)
                    all_rows.extend(rows)

            # ── Overlay UI + affichage ──
            if not no_display:
                frame = draw_ui(frame, fps, frame_count, person_detected,
                                export, export_path)

                # Redimensionner le frame pour l'affichage (sans toucher à la détection)
                display_frame = cv2.resize(frame, (DISPLAY_W, DISPLAY_H))
                cv2.imshow(WINDOW_NAME, display_frame)

                key = cv2.waitKey(1) & 0xFF
                if key == ord("q"):
                    break
                elif key == ord("l"):
                    show_labels = not show_labels
                elif key == ord("e") and not export:
                    export = True
                    open_csv()

    finally:
        cap.release()
        if not no_display:
            cv2.destroyAllWindows()
        if csv_file:
            csv_file.close()
        landmarker.close()

    print(f"\n[DONE] {frame_count} frames traitées")
    if export and export_path:
        print(f"[DONE] Keypoints exportés → {export_path}")
        n = len(all_rows) // 33 if all_rows else 0
        print(f"       ({len(all_rows)} lignes, {n} frames avec personne détectée)")

    return all_rows


# ─────────────────────────────────────────────
# Point d'entrée
# ─────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Détection de squelette MediaPipe")
    parser.add_argument("--source",     default="0",
                        help="Index webcam (0,1,...) ou chemin vers une vidéo")
    parser.add_argument("--export",     action="store_true",
                        help="Exporter les keypoints en CSV")
    parser.add_argument("--no-display", action="store_true",
                        help="Désactiver la fenêtre (mode headless)")
    parser.add_argument("--labels",     action="store_true",
                        help="Afficher les noms des articulations")
    args = parser.parse_args()

    run(
        source=args.source,
        export=args.export,
        no_display=args.no_display,
        show_labels=args.labels,
    )