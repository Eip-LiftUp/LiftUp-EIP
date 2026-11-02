# Écran "Générer un programme" — Plan d'implémentation Flutter

**Issue :** #90 — Écran Flutter "Générer un programme" branché sur l'API réelle
**Statut :** implémenté sur service mock (branche `gabriel/front-redesign`) —
reste à basculer sur `RealProgramApiService` quand l'endpoint backend existera

> Implémentation : `lib/features/program_generation/` (écran, modèles, service
> mock + réel). Bascule mock → réel : une ligne dans `programApiServiceProvider`.
>
> Décisions prises sur les points ouverts du §6 :
> - "Démarrer ce programme" crée les séances de la première semaine dans le
>   planning via les endpoints CRUD existants, et mémorise le programme actif
>   sur l'appareil pour la carte "Phase en cours" de l'accueil.
> - Fixture du mock : programme de la maquette Figma traduit, dimensionné
>   selon la fréquence d'activité du profil (3 à 6 séances).
**Dépend de :** #69 (contrat d'API, voir [API_CONTRACT.md](./API_CONTRACT.md)), #65
(squelette backend), et l'implémentation réelle du backend + moteur ML (M2, pas
encore ticketée)

---

## 1. Le blocage, et comment le contourner

`GET /users/:user_id/workouts/program` n'existe pas encore côté backend — ni même
son squelette (#65). On ne va pas attendre : l'écran se construit contre un
**mock respectant le contrat du §4 de l'API_CONTRACT**, et on bascule sur le vrai
appel HTTP dès que le backend est prêt. Le contrat étant déjà figé (ou en cours
de validation), le mock et le vrai appel renvoient exactement la même forme — le
swap ne touche qu'une ligne (l'implémentation du provider, pas les widgets).

---

## 2. Où ça vit dans l'app

Point d'entrée : l'état vide actuel de `program_page.dart`
(`_buildEmptyView()`, ligne ~293) affiche déjà "Aucun entraînement" avec un
bouton d'action. On y ajoute un second bouton : **"Générer un programme"**,
secondaire visuellement (outline) par rapport au bouton existant "Créer un
entraînement" (plein).

Le flux ouvre une nouvelle page `GenerateProgramPage`
(`lib/features/program/presentation/pages/generate_program_page.dart`) plutôt
que d'surcharger `program_page.dart`, qui est déjà volumineux (2700+ lignes).

---

## 3. État et données

Nouveau provider Riverpod, même pattern que `apiWorkoutProvider` déjà utilisé
dans `program_page.dart` :

```dart
// lib/core/providers/program_generation_provider.dart

sealed class ProgramGenerationState {}
class ProgramGenerationIdle extends ProgramGenerationState {}
class ProgramGenerationLoading extends ProgramGenerationState {}
class ProgramGenerationSuccess extends ProgramGenerationState {
  final List<Workout> workouts;   // réutilise le modèle Workout existant
  final bool fromCache;
}
class ProgramGenerationError extends ProgramGenerationState {
  final String message;
  final bool isTimeout;
}
```

Aucun nouveau modèle de données : `Workout` / `Exercise`
(`lib/core/models/workout.dart`) existent déjà et correspondent exactement à la
forme du §4 de l'API_CONTRACT — c'est tout l'intérêt d'avoir réutilisé ce format
côté backend plutôt que d'en inventer un nouveau.

---

## 4. Service API — mock d'abord, vrai appel ensuite

```dart
// lib/core/services/program_api_service.dart

abstract class ProgramApiService {
  Future<GeneratedProgram> generateProgram(String userId);
}

/// Utilisé tant que le backend n'a pas d'endpoint réel.
/// Retourne une réponse conforme au contrat §4, avec un délai simulé
/// pour tester les états de chargement sans dépendre du réseau.
class MockProgramApiService implements ProgramApiService {
  @override
  Future<GeneratedProgram> generateProgram(String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    return GeneratedProgram.fromJson(_fixtureJson);
  }
}

/// À activer une fois GET /users/:id/workouts/program disponible.
class RealProgramApiService implements ProgramApiService {
  @override
  Future<GeneratedProgram> generateProgram(String userId) async {
    final response = await ApiClient.instance.get('/users/$userId/workouts/program');
    return GeneratedProgram.fromJson(response.data);
  }
}
```

Le choix mock/réel se fait à un seul endroit (le provider), pas dispersé dans
les widgets :

```dart
final programApiServiceProvider = Provider<ProgramApiService>((ref) {
  return MockProgramApiService(); // -> RealProgramApiService() quand #65/#69 seront livrés
});
```

---

## 5. États de l'écran

On dispose d'une maquette codée (prototype React/Vite reçu de l'équipe design,
`figma/LiftUp app UI design/src/app/screens/ProgramGenerateScreen.tsx`, route
`/program/generate`) qui fixe précisément le comportement attendu — on la suit
plutôt que d'improviser 4 états génériques :

| État (maquette) | Affichage | Notes d'implémentation |
|---|---|---|
| `summary` (état initial) | Récap du profil utilisé pour la génération (objectif, niveau, fréquence d'entraînement) dans une `Card`, puis bouton "Générer mon programme" | Les 3 infos viennent du profil déjà en base (onboarding) — pas de saisie ici |
| `loading` | Icône animée + message qui alterne toutes les ~850ms ("Analyse du profil" → "Sélection des exercices" → "Équilibrage du volume") + skeletons de cartes + bouton "Annuler" | Dans la maquette c'est un minuteur fixe (3,2s) ; côté réel, basculer sur `Success`/`Error` dès la réponse HTTP, garder l'alternance de texte tant que la requête est en cours |
| `result`, `fromCache: false` | Liste de cartes par jour (réutilise le style des cartes existantes de `program_page.dart`) + section dépliable "Pourquoi ce programme ?" + boutons bas de page "Démarrer ce programme" / "Régénérer" | `Workout`/`Exercise` existants, rien de nouveau à afficher |
| `result`, `fromCache: true` | Même liste + bandeau discret indiquant que c'est le dernier programme généré (pas de régénération possible tant que le service ne répond pas) | Correspond à l'état `Error` de la maquette : elle affiche explicitement "on a chargé ton dernier programme sauvegardé" avec un lien vers `/program` plutôt qu'un écran d'échec sec |
| `Error`, `isTimeout: true`, pas de cache | "Le service met du temps à répondre" + bouton "Réessayer" | Cas non couvert par la maquette (elle suppose qu'il y a toujours un cache) — à construire par analogie |
| `Error`, autre | Message d'erreur générique + bouton Réessayer | idem |
| Profil incomplet (422 prévu dans l'API_CONTRACT) | Redirige vers `/profile-setup` avec un message explicite | Non présent dans la maquette, à ajouter |

Point important : dans la maquette, l'erreur réseau n'est **jamais** un cul-de-sac —
elle redirige systématiquement vers le dernier programme connu. Ça confirme que le
fallback cache de l'API_CONTRACT (§5) n'est pas une option mais le comportement
attendu par le design.

### Tokens visuels (design system de la maquette)

La maquette définit un vrai design system (`figma/.../src/styles/theme.css`),
différent de ce qui existe actuellement dans `client/app/lib/config/theme.dart` :

| Rôle | Maquette | Flutter actuel |
|---|---|---|
| Fond | `#0B1020` | `#0D1B2A` |
| Primaire | `#2FB6FF` (cyan) | seed `#6366F1` (indigo) |
| Accent | `#FF8A2A` (orange) | — (absent) |
| Succès / Alerte / Erreur | `#2ED573` / `#FFB020` / `#FF4D4D` | — (à vérifier) |

**À trancher avant de coder l'écran** : on aligne le thème Flutter sur ces tokens
(impact sur toute l'app, pas que cet écran), ou on garde le thème actuel et on
traite la maquette comme une inspiration de layout seulement ? Tant que ce n'est
pas tranché, le nouvel écran peut utiliser `AppColors` tel qu'il existe
aujourd'hui pour ne pas bloquer #90 sur une décision de design globale.

---

## 6. Ce qui reste ouvert

- [ ] Le "Ajouter à mon planning" du programme généré : ça crée de vrais
      `Workout`/`Exercise` en base via les endpoints CRUD existants
      (`POST /users/:user_id/workouts`), ou le programme généré reste en lecture
      seule pour l'instant ? À trancher avant de coder cette action.
- [ ] Fixture du mock : à écrire une fois que le contrat §4 de l'API_CONTRACT est
      validé par backend/ML (pour éviter de la refaire si le contrat change).

---

## 7. Point annexe découvert pendant ce travail : l'onboarding n'est pas modifiable

> **Résolu** : Profil › Mes données › « Profil d'entraînement » rouvre le
> formulaire d'onboarding en mode édition (pré-rempli, route
> `/profile/training`). Vider les notes médicales ou le focus est pris en
> compte (le formulaire envoie `''` / `[]` au lieu d'omettre le champ).

`profile_page.dart` (`_showPersonalInfoDialog`, ligne ~169) permet déjà de
modifier poids / taille / niveau / objectifs (`fitnessGoals`). Mais les champs
posés par le formulaire d'onboarding en 3 pages (migrations `0006`/`0007`) —
fréquence d'activité, blessures, zones blessées, notes médicales, focus
d'entraînement — n'ont **aucun point d'édition** dans l'app une fois
l'onboarding terminé.

Conséquence concrète pour ce chantier : le moteur de génération (#69 §3) lit ces
champs directement en base pour construire le programme. Si l'utilisateur ne
peut pas les corriger, un profil une fois rempli au mauvais format — ou qui
change (plus de blessure, nouveau focus) — reste figé indéfiniment et biaise les
programmes générés en continu.

- [ ] À trancher : on étend `_showPersonalInfoDialog` existant (ajout de
      sections) ou on route vers `ProfileSetupPage` (le wizard d'onboarding),
      réutilisé en mode édition plutôt qu'en mode première saisie ? La seconde
      option réutilise tout le code déjà écrit (chips, formulaire) mais demande
      d'adapter `ProfileSetupPage` pour pré-remplir les champs existants.
- [ ] Hors scope strict de #90, mais à signaler à l'équipe — soit comme
      extension de #90, soit comme ticket séparé, avant que l'écran de
      génération ne s'appuie sur des profils qu'on ne peut plus corriger.
