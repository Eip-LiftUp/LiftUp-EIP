# Génération de programme — Contrat d'API

**Issue :** #69 — Poser l'architecture du futur endpoint de génération de programme
**Statut :** brouillon — à valider par backend et ML (cf. "Done quand" de l'issue)
**Scope :** M1 (spec) / M2 (implémentation réelle, cf. plan de développement)

---

## 1. Contexte

Aujourd'hui, un utilisateur crée ses entraînements à la main (`POST /users/:user_id/workouts`).
L'objectif de ce chantier (M2 du plan) est de lui proposer un programme généré
automatiquement à partir de son profil, au lieu de partir d'une page vide.

Ce document fixe le contrat entre les trois composants impliqués :

```
Flutter  --->  Backend Rust  --->  Service IA Python
 (#90)         (squelette: #65)      (moteur: pas encore ticketé, taille XL)
```

Le Rust reste le seul point d'entrée pour le client, comme c'est déjà le cas pour
l'analyse vidéo (`/ai/analyze` proxie déjà vers le service Python — voir
`back/src/handlers/analysis.rs`). On applique le même principe ici plutôt que
d'inventer un nouveau pattern.

---

## 2. Endpoint exposé au client (Flutter → Rust)

```
GET /users/:user_id/workouts/program
```

**Pourquoi ce chemin et pas `/workouts/program` tout court** (tel qu'écrit dans le
plan) : toutes les routes workouts existantes sont déjà nichées sous
`/users/:user_id/workouts/...` (`routes.rs`). Rester cohérent avec cette convention
plutôt que de créer une exception. *(Point à confirmer avec backend — c'est un choix
de design, pas une contrainte technique dure.)*

**Entrée :** aucun corps de requête. Le profil et les objectifs ne sont pas
envoyés par le client — ils sont déjà en base (voir §3), posés par le formulaire
d'onboarding. Ça évite toute divergence entre "ce que le profil dit" et "ce qu'on
envoie à la génération".

**Sortie (200 OK) :** un programme, au format décrit en §4.

**Erreurs :**
| Cas | Code | Comportement |
|---|---|---|
| Service IA indisponible ou timeout (5s, cf. plan) | 200 OK avec `fromCache: true` | fallback sur le dernier programme généré en cache (§5), s'il existe |
| Service IA indisponible, aucun cache | 503 Service Unavailable | `{ "error": "program generation unavailable", "detail": "..." }` (même forme que `ErrorResponse` dans `analysis.rs`) |
| Profil incomplet (onboarding non terminé) | 422 Unprocessable Entity | `{ "error": "profile incomplete", "missingFields": [...] }` |

---

## 3. Entrée réelle envoyée au moteur ML (Rust → Python)

Le Rust assemble cette requête à partir de la table `users` — tous ces champs
existent déjà grâce au formulaire d'onboarding (migrations `0006`/`0007`) :

```
POST http://ai-service:8000/api/v1/program/generate
```

```json
{
  "age": 25,
  "heightCm": 178,
  "weightKg": 72.5,
  "fitnessLevel": "beginner",
  "activityFrequency": "moderate",
  "hasInjuries": true,
  "injuredZones": ["Épaules"],
  "trainingFocus": ["Dos", "Jambes"],
  "fitnessGoals": "La prise de masse"
}
```

- `age` : calculé côté Rust depuis `birth_date` (pas stocké tel quel en base).
- Tous les autres champs : copie directe des colonnes `users`.
- Nommage `/api/v1/program/*` : suit la convention déjà en place pour
  `/api/v1/video/*` côté service Python.

*(Point à valider avec ML : est-ce que ces 8 champs suffisent pour une v1 du
moteur, ou faut-il en ajouter / en retirer ? Le moteur lui-même n'est pas encore
ticketé — cette liste est une proposition de point de départ, pas une contrainte.)*

---

## 4. Forme du programme généré (sortie)

Plutôt que d'inventer un nouveau format, on réutilise la forme déjà utilisée pour
les entraînements manuels (`WorkoutResponse` / `ExerciseResponse` côté Rust,
`Workout` / `Exercise` côté Flutter) — ces modèles existent déjà des deux côtés,
donc #90 n'a pas besoin d'en écrire de nouveaux.

```json
{
  "programId": "a1b2c3d4-...",
  "generatedAt": "2026-10-27T10:00:00Z",
  "fromCache": false,
  "name": "LiftUp Force & Volume",
  "weeks": 6,
  "sessionsPerWeek": 4,
  "rationale": "Ce programme privilégie les mouvements polyarticulaires…",
  "workouts": [
    {
      "name": "Jour 1 — Pectoraux & Épaules",
      "workoutDate": "2026-10-28",
      "durationMinutes": 60,
      "focus": ["Pectoraux", "Épaules"],
      "exercises": [
        {
          "exerciseName": "Développé couché",
          "sets": 4,
          "reps": 10,
          "weight": 40.0,
          "weightUnit": "kg",
          "notes": "Charge indicative, à ajuster selon le ressenti"
        }
      ]
    }
  ]
}
```

**`workouts` contient une semaine : la première du programme**, pas toutes
les semaines. `sessionsPerWeek` donne le nombre de séances par semaine sur
toute la durée (`weeks`) ; en v1 il vaut le nombre d'éléments de `workouts`.
Le client affiche « 4 séances par semaine » et suit l'avancement du programme
(« Semaine 2 sur 6 ») à partir de ces deux champs.

Chaque élément de `workouts` a la forme d'une requête de création d'entraînement
existante (`name`, `workoutDate`, `durationMinutes` + exercices au format
`CreateExerciseRequest`). Avantage concret : "Démarrer ce programme" côté
Flutter crée les séances avec les endpoints CRUD existants, sans conversion.

Champs ajoutés pour l'écran de la maquette Figma (récap du programme) :
`name`, `weeks` (durée du programme), `sessionsPerWeek`, `rationale` (texte
"Pourquoi ce programme ?", facultatif) et, par séance, `focus` (groupes
musculaires travaillés). Tous facultatifs côté client, avec des valeurs par
défaut (`sessionsPerWeek` absent = nombre d'éléments de `workouts`).

*(Point à valider avec ML : le moteur v1 pourra-t-il vraiment proposer des poids
chiffrés, ou seulement sets/reps au départ ? Si c'est juste sets/reps pour
commencer, `weight` reste `null` — le contrat le permet déjà.)*

---

## 5. Mise en cache (M2 backend : "Stockage du programme en cache")

Nouvelle table, un programme généré par utilisateur (écrasé à chaque régénération
plutôt qu'un historique, pour rester simple en v1) :

```sql
CREATE TABLE generated_programs (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    program_data  JSONB NOT NULL,
    generated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

`program_data` stocke tel quel le JSON du §4 (sans `fromCache`, recalculé à la
lecture). `UNIQUE` sur `user_id` = upsert à chaque génération réussie.

---

## 6. Ce qui reste à trancher avant implémentation

- [ ] Chemin `/users/:user_id/workouts/program` vs `/workouts/program` (backend)
- [ ] Les 8 champs du §3 suffisent-ils pour le moteur v1 ? (ML)
- [ ] Poids chiffrés dès la v1 du moteur, ou sets/reps seulement ? (ML)
- [ ] Un programme en cache par utilisateur, ou historique ? (backend)
