# skeleton_detection

Analyse une vidéo d'exercice, détecte le squelette frame par frame avec **MediaPipe**, et exporte les coordonnées des 33 articulations dans un fichier **CSV**.

Conçu pour alimenter un coach IA capable de corriger les mouvements sportifs.

---

## Installation

```bash
pip install -r requirements.txt
```

---

## Usage

```bash
python skeleton_detection.py --video <fichier> [options]
```

### Paramètres

| Paramètre | Description | Défaut |
|---|---|---|
| `--video FICHIER` | Chemin vers la vidéo à analyser (mp4, avi, mov...) | **obligatoire** |
| `--output FICHIER.csv` | Nom du fichier CSV de sortie | `nom_video_keypoints.csv` |
| `--no-display` | Désactive la fenêtre de visualisation (plus rapide) | `false` |
| `--labels` | Affiche les noms des articulations sur la vidéo | `false` |

### Exemples

```bash
# Analyse basique — CSV généré automatiquement
python skeleton_detection.py --video squat.mp4

# Nommer le CSV de sortie
python skeleton_detection.py --video squat.mp4 --output squat_rep1.csv

# Traitement headless, sans fenêtre (plus rapide, idéal en prod)
python skeleton_detection.py --video squat.mp4 --no-display

# Afficher les noms des articulations sur la vidéo
python skeleton_detection.py --video squat.mp4 --labels
```

### Raccourcis clavier (fenêtre de visualisation)

| Touche | Action |
|---|---|
| `Q` | Quitter |
| `ESPACE` | Pause / Reprendre |
| `L` | Afficher / Masquer les labels des articulations |

---

## Format du CSV de sortie

Chaque frame détectée génère **33 lignes** (une par keypoint).

| Colonne | Description |
|---|---|
| `frame` | Numéro de la frame dans la vidéo |
| `timestamp_sec` | Temps en secondes dans la vidéo |
| `keypoint_id` | Index du keypoint (0 à 32) |
| `keypoint_name` | Nom de l'articulation (ex: `left_elbow`) |
| `x` | Position horizontale normalisée [0, 1] |
| `y` | Position verticale normalisée [0, 1] |
| `z` | Profondeur relative (approximative) |
| `visibility` | Confiance de détection [0, 1] |

### Exemple de lignes

```
frame,timestamp_sec,keypoint_id,keypoint_name,x,y,z,visibility
1,0.0,11,left_shoulder,0.645245,0.459048,-0.249523,0.9998
1,0.0,13,left_elbow,0.64426,0.610855,-0.165332,0.9261
1,0.0,15,left_wrist,0.652856,0.738735,-0.201907,0.973
```

### Les 33 keypoints MediaPipe

```
 0  nose                16  right_wrist
 1  left_eye_inner      17  left_pinky
 2  left_eye            18  right_pinky
 3  left_eye_outer      19  left_index
 4  right_eye_inner     20  right_index
 5  right_eye           21  left_thumb
 6  right_eye_outer     22  right_thumb
 7  left_ear            23  left_hip
 8  right_ear           24  right_hip
 9  mouth_left          25  left_knee
10  mouth_right         26  right_knee
11  left_shoulder       27  left_ankle
12  right_shoulder      28  right_ankle
13  left_elbow          29  left_heel
14  right_elbow         30  right_heel
15  left_wrist          31  left_foot_index
                        32  right_foot_index
```

---

## Dépendances

```
mediapipe >= 0.10.13
opencv-python >= 4.8.0
numpy >= 2.0.0
```

> Le modèle MediaPipe (`pose_landmarker_full.task`, ~10 Mo) est téléchargé automatiquement au premier lancement.