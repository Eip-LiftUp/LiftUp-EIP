# Écran "Générer un programme" — Implémentation Flutter

**Issue :** #90 — Écran Flutter "Générer un programme" branché sur l'API réelle
**Statut :** écran terminé sur un service mock ; il reste à basculer sur
`RealProgramApiService` quand l'endpoint backend existera
**Dépend de :** #69 (contrat d'API, voir [API_CONTRACT.md](./API_CONTRACT.md)), #65
(squelette backend), puis l'implémentation réelle du backend et du moteur ML (M2)

---

## 1. Le blocage, et comment le contourner

`GET /users/:user_id/workouts/program` n'existe pas encore côté backend (#65).
L'écran est donc construit contre un **mock qui respecte le §4 de
l'API_CONTRACT**. Le mock et le vrai appel renvoient exactement la même forme :
la bascule tient en une ligne (§4 ci-dessous), sans toucher aux widgets.

---

## 2. Où ça vit dans l'app

| Fichier (`client/app/lib/features/program_generation/`) | Rôle |
|---|---|
| `presentation/generate_program_page.dart` | L'écran (route `/training/generate`) |
| `data/generated_program.dart` | Modèles `GeneratedProgram`, `ProgramSession`, `ProgramExercise` (forme du §4) |
| `data/program_api_service.dart` | Service abstrait, mock, appel réel, provider |
| `data/example_program.dart` | Programme servi par le mock |

Point d'entrée : onglet **Entraînement** › tuile « Générer un programme ».

---

## 3. État de l'écran

Pas de provider dédié : l'état tient dans la page (`enum _View { summary,
loading, result, error }`). Il ne sert qu'à cet écran et disparaît avec lui.

- **Profil :** lu via `userProfileProvider`, gardé sur l'appareil pour le
  hors ligne.
- **Séances :** créées via `apiWorkoutProvider`. Elles s'enregistrent sur
  l'appareil puis partent au serveur en arrière-plan (synchro hors ligne, #92).
- **Programme démarré :** mémorisé par `activeProgramProvider`, pour la carte
  « Phase en cours » de l'accueil.

---

## 4. Service API — mock d'abord, vrai appel ensuite

```dart
abstract class ProgramApiService {
  Future<GeneratedProgram> generateProgram(String userId);
}
```

- `MockProgramApiService` lit le profil (pour la fréquence d'activité),
  attend 3 s puis renvoie le programme d'exemple, dimensionné de 3 à 6 séances
  par semaine selon cette fréquence.
- `RealProgramApiService` appelle `GET /users/:user_id/workouts/program`
  (délai de 10 s). Il traduit le 422 en `profileIncomplete`, et un délai
  dépassé en `isTimeout`.

Bascule : dans `programApiServiceProvider`, remplacer
`MockProgramApiService(...)` par `RealProgramApiService()`.

---

## 5. États de l'écran

L'écran suit la maquette Figma (`ProgramGenerateScreen.tsx`, route
`/program/generate`) :

| État | Affichage |
|---|---|
| `summary` | Récap du profil (objectif, niveau, fréquence, zones à ménager, focus) et bouton « Générer mon programme ». Si taille, poids, date de naissance ou fréquence manquent : bouton désactivé, et carte « Profil incomplet » qui ouvre le questionnaire puis revient sur l'écran |
| `loading` | Icône animée, message qui alterne toutes les 850 ms, squelettes de cartes, bouton « Annuler » |
| `result` | Nom, durée, « N séances par semaine » (`sessionsPerWeek`), cartes des séances, section dépliable « Pourquoi ce programme ? », boutons « Démarrer ce programme » / « Régénérer » |
| `result` avec `fromCache: true` | Même liste, avec un bandeau : dernier programme généré, le coach IA ne répond pas |
| `error` | Message (délai dépassé, service indisponible, hors ligne) et bouton « Réessayer » |
| 422 (profil incomplet côté serveur) | Retour au récap ; le questionnaire s'ouvre par-dessus l'écran |

Les couleurs, la typographie et les icônes viennent du thème de l'app, aligné
sur le design system de la maquette lors de la refonte du front.

---

## 6. Décisions prises

- **« Démarrer ce programme » :**
  - crée les séances de la **première semaine** (le contenu de `workouts`)
    avec les endpoints CRUD existants ;
  - les séances apparaissent tout de suite dans le planning, même hors ligne ;
  - le programme est mémorisé sur l'appareil, pour suivre « Semaine X sur Y ».
- **Mock :** programme de la maquette Figma traduit, dimensionné selon la
  fréquence d'activité du profil.
- **Génération :** elle demande une connexion. Hors ligne, l'écran l'explique
  au lieu de lancer l'appel.

---

## 7. Point annexe : modifier l'onboarding

Résolu : Profil › Mes données › « Profil d'entraînement » rouvre le
questionnaire en mode édition (pré-rempli, route `/profile/training`) pour la
fréquence, les blessures, les notes médicales et le focus. Taille, poids et
date de naissance se modifient dans « Informations personnelles ». Vider les
notes médicales ou le focus est pris en compte : le formulaire envoie `''` /
`[]` au lieu d'omettre le champ.
