# Synchronisation hors ligne → en ligne (application Flutter)

**Issue :** #92 — Synchronisation hors ligne → en ligne avec file locale,
nouvel essai, résolution de conflits, testée
**Date :** 2 novembre 2026
**Statut :** implémenté côté Flutter, sans changement backend nécessaire ;
trois améliorations backend proposées au §7

> Cette issue (octobre 2026) remplace, pour les séances, la décision
> « Cloud-Centric » notée dans `CHANGELOG.md` (février 2026). La priorité est
> l'usage sur mobile, sans réseau, à la salle.

---

## 1. Ce qui marche sans réseau

| Fonction | Hors ligne |
|---|---|
| Ouvrir l'app déjà connecté | ✅ la session est gardée sur l'appareil |
| Voir ses séances, le planning, les progrès | ✅ copie locale |
| Voir son profil | ✅ dernier profil reçu |
| Créer / modifier / supprimer une séance ou un exercice, saisir ses séries, démarrer / terminer une séance | ✅ en attente, envoyé au retour du réseau |
| Exporter ses données | ✅ depuis la copie locale |
| Connexion, inscription, modification du profil, suppression du compte | ❌ message « Tu es hors ligne » |
| Génération de programme, analyse vidéo | ❌ message « Tu es hors ligne » |

Sur le web, l'app ne peut pas *s'ouvrir* sans réseau (pas de service worker) :
le hors ligne y couvre les coupures pendant l'utilisation.

## 2. Principe

```
copie serveur (dernière connue)  +  file d'opérations en attente  =  ce que l'écran affiche
```

- Chaque action de l'utilisateur est **appliquée tout de suite à l'écran**
  et **ajoutée à une file** sauvegardée sur l'appareil.
- La file est envoyée **dans l'ordre** dès que possible ; chaque réponse du
  serveur met à jour la copie serveur et retire l'opération de la file.
- Une action n'attend jamais le réseau : seule la lecture de la copie locale
  au démarrage la précède.

Les pages n'ont pas changé : `ApiWorkoutNotifier` garde les mêmes méthodes
(`createWorkout`, `updateExercise`…), qui répondent maintenant sans attendre
le réseau.

| Fichier (`client/app/lib/`) | Rôle |
|---|---|
| `core/sync/pending_operation.dart` | Une opération en attente (type, cible, champs, essais, refus) |
| `core/sync/local_workouts.dart` | Applique la file à la copie serveur (affichage) |
| `core/sync/workout_store.dart` | Sauvegarde sur l'appareil (SharedPreferences) |
| `core/sync/workout_repository.dart` | Fusion, envoi, conflits, doublons |
| `core/providers/workout_provider.dart` | Branchement Riverpod, déclencheurs, nouveaux essais |
| `core/providers/connectivity_provider.dart` | État du réseau (`connectivity_plus`) |
| `core/widgets/sync_status.dart` | Bandeau au-dessus des onglets, carte « Synchronisation » du profil |

### Stockage sur l'appareil

| Clé | Contenu |
|---|---|
| `workouts.<userId>` | Copie serveur des séances (même JSON que l'API) |
| `sync.<userId>` | File d'opérations en attente |
| `sync.<userId>.at` | Date de la dernière synchronisation réussie |
| `profile.<userId>` | Dernier profil reçu |
| `auth.session` | Session : id, email, pseudo, onboarding terminé. **Pas le jeton** : aucun appel API ne l'utilise aujourd'hui |

Une entrée illisible est ignorée au lieu de bloquer l'app. La copie serveur
est réécrite une fois par synchronisation, pas après chaque opération. Si
l'app est tuée en cours d'envoi, les opérations déjà parties sont renvoyées
sans risque :
- les modifications et suppressions donnent le même résultat une 2ᵉ fois ;
- les créations sont retrouvées sur le serveur au lieu d'être recréées (§6).

### Identifiants temporaires

Une séance ou un exercice créé hors ligne reçoit un id `local-…`. Quand le
serveur répond, l'id serveur le remplace partout : opérations suivantes de la
file, écran, séance en cours.

### Moins de requêtes

- Plusieurs modifications d'une même séance ou d'un même exercice → **une seule**
  requête PATCH, avec les champs fusionnés.
- Créé puis supprimé avant l'envoi → **rien** n'est envoyé.
- Supprimé → les modifications en attente sur cet élément (et sur les
  exercices d'une séance supprimée) sont abandonnées.

## 3. Quand la file est envoyée

| Déclencheur | Envoi de la file | Rechargement complet des séances |
|---|---|---|
| Démarrage, retour du réseau, retour au premier plan, « Synchroniser maintenant », tirer pour rafraîchir | ✅ | ✅ |
| Après chaque action | ✅ | ❌ (les réponses du serveur suffisent) |
| Après un échec : 2 s, 4 s, 8 s… jusqu'à 5 min | ✅ | ✅ |

Une seule synchronisation tourne à la fois : les actions faites pendant
qu'elle tourne la relancent une fois à la fin, au lieu d'en lancer une par
action. Un échec compte une seule fois dans le délai avant le prochain essai.
Rien n'est envoyé pour un compte qui n'est plus connecté sur l'appareil.

## 4. Erreurs

| Réponse | Traitement |
|---|---|
| Pas de réseau, délai dépassé, réponse illisible (portail Wi-Fi), 5xx, 401, 403, 408, 429 | L'opération reste en tête de file ; nouvel essai plus tard |
| 404 | L'élément a été supprimé ailleurs (voir §5) |
| Autre 4xx (400, 409, 422…) | Opération **refusée** : mise de côté, les suivantes partent quand même |

Une opération refusée reste visible dans Profil › Synchronisation, avec deux
choix : « Réessayer » ou « Abandonner » (la version du serveur est gardée).
Les opérations qui dépendent d'une création refusée sont refusées aussi.

## 5. Conflits

Le backend n'a ni numéro de version ni ETag. Règles retenues :

1. **La modification faite sur l'appareil gagne**, champ par champ. Seuls les
   champs modifiés sont envoyés, et le backend garde ceux qu'il ne reçoit pas
   (`COALESCE`). Une modification faite ailleurs sur un *autre* champ est donc
   conservée.
2. **La suppression gagne**, d'un côté comme de l'autre :
   - séance supprimée sur l'appareil → supprimée sur le serveur, même si elle
     avait été modifiée ailleurs ;
   - séance supprimée ailleurs → les changements hors ligne sur cette séance
     sont abandonnés.
3. L'utilisateur est prévenu par un message, par exemple « « Jambes » avait
   aussi été modifiée ailleurs : ta version a été gardée ».

Pour détecter qu'une séance a changé ailleurs, l'app compare le `updatedAt`
du serveur avec celui sur lequel la modification a été faite :
- **Coût :** une requête GET en plus, seulement pour une modification restée
  en attente (plus d'une minute, ou après un échec). Une modification envoyée
  tout de suite n'a pas pu croiser celle d'un autre appareil.
- **Pas de faux conflit :** après chaque envoi réussi, les modifications
  suivantes de la même séance se basent sur la version renvoyée. Un 2ᵉ
  changement fait pendant l'envoi du 1ᵉʳ n'est donc pas pris pour un conflit.
- **Exercices :** ils n'ont pas de `updatedAt`, leurs conflits ne sont pas
  signalés (la règle 1 s'applique quand même).

## 6. Doublons

Si le serveur crée la séance mais que la réponse se perd (coupure au mauvais
moment), un nouvel essai pourrait la créer deux fois. Avant de renvoyer une
création déjà tentée, l'app relit la liste du serveur : si une séance de même
nom, même date et créée après l'opération existe, elle la reprend au lieu de
la recréer. Même principe pour les exercices (même nom, même position).

## 7. Améliorations proposées au backend

Rien n'est bloquant. Ces ajouts rendraient la synchronisation plus sûre et
plus économe :

1. **En-tête `Idempotency-Key`** sur les `POST` (séances, exercices) : le
   serveur renvoie la même ressource si la clé a déjà été vue. Cela remplace
   la détection du §6, qui reste une heuristique.
2. **`If-Unmodified-Since`** (ou un champ `version`) sur les `PATCH`, avec une
   réponse `409` : l'app saurait qu'il y a conflit sans faire de GET avant.
3. **`updatedAt` sur les exercices**, pour signaler aussi leurs conflits.

## 8. Limites connues

- Après déconnexion, la copie locale, le profil et les modifications non
  envoyées restent sur l'appareil, sans plus être synchronisés. Ils
  repartent à la prochaine connexion du même compte. À revoir si l'app doit
  tout effacer à la déconnexion (appareil partagé). La suppression du compte,
  elle, efface tout ce que l'app garde pour ce compte.
- Le stockage utilise SharedPreferences : adapté à quelques centaines de
  séances. Au-delà, il faudra passer à une base locale (Drift, Isar…).
- Si le backend exige un jour le jeton d'authentification, il devra être
  stocké dans le stockage sécurisé du système (`flutter_secure_storage`),
  pas dans SharedPreferences.

## 9. Tests

```bash
cd client/app
flutter test test/sync
```

| Fichier | Contenu |
|---|---|
| `test/sync/workout_repository_test.dart` | 18 scénarios avec un faux serveur : hors ligne → en ligne, redémarrage, fusion, conflits, faux conflits, suppressions, refus, réponse perdue ou illisible, erreurs serveur, délais |
| `test/sync/workout_notifier_test.dart` | Une action n'attend pas le serveur, un échec compte une fois, plus de synchro après déconnexion |
| `test/sync/offline_app_test.dart` | L'app complète : bandeau hors ligne, envoi au retour du réseau, carte du profil et « Réessayer », message des actions en ligne, session restaurée |
| `test/sync/workout_api_service_test.dart` | Une page de portail Wi-Fi est une erreur à réessayer, pas un plantage |
| `test/sync/local_data_test.dart` | Suppression du compte, profil hors ligne |
| `test/sync/fake_server.dart` | Faux backend en mémoire (coupure, lenteur, refus, réponse perdue ou illisible, modification par un autre appareil) |

Vérifié aussi sur le build web contre le backend local : une séance créée
réseau coupé apparaît tout de suite, le bandeau indique « 1 modification en
attente », la séance arrive en base une seule fois au retour du réseau, et
l'app rouverte va directement à l'accueil.
