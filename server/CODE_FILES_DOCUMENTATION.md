# Documentation des fichiers de code (server)

## Portee
Ce document couvre les fichiers de code du dossier server.

Inclus :
- backend Python FastAPI (app),
- module scraping et pipeline data,
- scripts d'exemple et de test,
- tests unitaires,
- fichiers techniques utiles au code (Docker, requirements, script de demarrage, config JSON exemple).

Exclus :
- caches Python (__pycache__, etc.).

## Arborescence documentee

### 1) Entree application et configuration

- app/main.py
  - Point d'entree FastAPI.
  - Enregistre middlewares CORS, routes API et handlers d'erreur globaux.

- app/core/config.py
  - Parametrage applicatif via Settings (pydantic-settings).

- app/__init__.py
  - Initialisation package app.

- app/core/__init__.py
  - Initialisation package core.

### 2) API HTTP (endpoints)

- app/api/__init__.py
  - Initialisation package API.

- app/api/endpoints/__init__.py
  - Initialisation package endpoints.

- app/api/endpoints/health.py
  - Endpoints de sante applicative (basique et detaillee).

- app/api/endpoints/analysis.py
  - Endpoints d'analyse de form et feedback temps reel.
  - Expose aussi la recuperation des exercices supportes et guidelines.

- app/api/endpoints/pose.py
  - Endpoints estimation de pose image/video et metadonnees keypoints.

- app/api/endpoints/video.py
  - Endpoints analyse video complete (fichier/url), sante du service video et recuperation des videos annotees.

### 3) Modeles de donnees

- app/models/__init__.py
  - Initialisation package modeles.

- app/models/schemas.py
  - Schemas Pydantic (requetes/reponses API).
  - Types principaux : CommentType, KeyPoint, PoseResponse, Comment, FormAnalysisRequest, FormAnalysisResponse, ExerciseGuidelines.

### 4) Services metier IA/vision

- app/services/__init__.py
  - Initialisation package services.

- app/services/form_analyzer.py
  - Analyse de forme par exercice + generation de commentaires.
  - Contient aussi des fonctions utilitaires de calcul d'angle/analyse squat.

- app/services/pose_estimator.py
  - Estimation de pose (torchvision/mediapipe selon implementation).

- app/services/pose_analyzer.py
  - Analyse video de pose (logique riche de scoring/commentaires).
  - Expose factory get_pose_analyzer().

- app/services/i3d_analyzer.py
  - Module modele I3D (blocs reseau + pipeline analyse video).

### 5) Module scraping et data pipeline

- app/scraping/__init__.py
  - Exports principaux du module scraping (VideoScraper, ScraperConfig).

- app/scraping/config.py
  - Configuration scraping (sources, contraintes, validation).
  - Types : VideoSourceConfig, ScraperConfig.

- app/scraping/video_scraper.py
  - Telechargement/filtrage videos (yt_dlp), extraction metadata, preparation assets.
  - Types : VideoMetadata, VideoScraper.

- app/scraping/data_pipeline.py
  - Construction datasets et dataloaders (PyTorch) a partir des videos/frame sets.
  - Types : VideoFrameDataset, VideoDataset, DataPipeline.

- app/scraping/cli.py
  - CLI de scraping (init config, scraping, stats, split dataset, etc.).

### 6) Utils

- app/utils/__init__.py
  - Initialisation package utils.

### 7) Tests et scripts de validation

- tests/__init__.py
  - Initialisation package tests.

- tests/test_form_analyzer.py
  - Tests du service form_analyzer.

- tests/test_pose_estimator.py
  - Tests du service pose_estimator.

- tests/test_scraping_config.py
  - Tests validation/config du module scraping.

- tests/test_video_scraper.py
  - Tests de VideoScraper et VideoMetadata.

- tests/test_data_pipeline.py
  - Tests datasets/pipeline et creation dataloaders.

- test_i3d.py
  - Script de test integratif manuel des endpoints I3D/video.

### 8) Exemples

- examples/scraping_examples.py
  - Exemples d'usage scraping + data pipeline + integration entrainement.

### 9) Fichiers techniques lies au code

- Dockerfile
  - Build conteneur de l'application server.

- docker-compose.yml
  - Orchestration locale des services server.

- start.sh
  - Script de demarrage pratique.

- requirements.txt
  - Dependances runtime Python.

- requirements-dev.txt
  - Dependances developpement/test.

- scraper_config.json.example
  - Exemple de configuration pour le module scraping.

- README.md
  - Guide principal du module server.

- SCRAPING_TOOL.md
  - Documentation fonctionnelle du scraper.

- PYTORCH_SCRAPING_SETUP.md
  - Guide setup environnement PyTorch/scraping.

- SETUP_SUMMARY.md
  - Resume setup projet server.

## Notes de maintenance

- Les endpoints FastAPI doivent rester alignes avec les schemas de app/models/schemas.py.
- Les services IA (pose/form/I3D) ont des dependances lourdes ; verifier compatibilite des versions dans requirements avant upgrade.
- Le module scraping partage des modeles de config avec la CLI et les tests ; toute evolution de schema doit etre refletee dans tests/test_scraping_config.py.
