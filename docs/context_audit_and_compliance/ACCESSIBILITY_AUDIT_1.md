# Audit d'accessibilité n°1 — Application Flutter

**Issue :** #93 — Première passe d'accessibilité sur les écrans clés
**Date :** 2 novembre 2026
**Référentiel :** WCAG 2.1 niveau AA / RGAA 4.1, objectif Phase 1 de
[ACCESSIBILITY_STRATEGY.md](./ACCESSIBILITY_STRATEGY.md) (niveau A + AA partiel)
**Statut :** non-conformités détectées corrigées ; test sur appareil réel
(TalkBack / VoiceOver) restant à faire

---

## 1. Périmètre

| Parcours | Écrans |
|---|---|
| Accès | Bienvenue, connexion, inscription |
| Premier lancement | Questionnaire de profil (3 étapes) |
| Onglets | Accueil, Entraînement, Progrès, Profil |
| Entraînement | Feuille de détail, séance en cours, éditeur de séries, création / modification de séance |
| Suivi | Planning (calendrier du mois) |
| Profil | Informations personnelles, profil d'entraînement, suppression de compte |
| IA | Génération de programme (récap, chargement, résultat), sélection / enregistrement / envoi de vidéo, résultats d'analyse |

Plateformes visées : Android, iOS et web (même code Flutter).

## 2. Méthode

1. **Tests automatiques** (`flutter test --tags accessibility`, 94 tests),
   lancés sur chaque écran et chaque feuille / dialogue :
   - règles d'accessibilité de Flutter : zone tactile ≥ 44 × 44, contrôles
     nommés, contraste du texte affiché ≥ 4,5:1 ;
   - texte agrandi à 200 % sur un écran de 320 px de large, sans débordement ;
   - contraste de chaque paire de couleurs du thème ;
   - comportements précis : titres, nom des champs, calendrier activable,
     parcours au clavier, animations réduites, langue.
2. **Lecture de l'arbre d'accessibilité** (ce que reçoit le lecteur d'écran)
   écran par écran, pour repérer ce que les règles automatiques ne voient pas.
3. **Vérification sur le build web** dans Chrome : langue de la page, titre
   d'onglet, arbre d'accessibilité présent au chargement, ouverture des
   sélecteurs au clavier.

## 3. Non-conformités relevées et corrigées

| # | Problème constaté | Écrans | WCAG | RGAA | Correction |
|---|---|---|---|---|---|
| 1 | Les jours du calendrier et de la timeline ne pouvaient pas être activés au lecteur d'écran | Planning, Progrès | 2.1.1, 4.1.2 | 7.1, 7.3 | Action d'activation déclarée sur chaque jour |
| 2 | Les champs étaient annoncés par leur exemple (« vous@exemple.com ») au lieu de leur libellé | Tous les formulaires | 1.3.1, 4.1.2 | 11.1, 11.2 | Le libellé visible nomme le champ |
| 3 | Champs « poids » et « répétitions » de l'éditeur de séries sans aucun nom | Éditeur de séries | 4.1.2 | 11.1 | « Série 2, répétitions », etc. |
| 4 | Champ date en lecture seule : impossible à ouvrir au clavier et au lecteur d'écran web | Profil, création de séance | 2.1.1 | 7.3 | Converti en bouton avec l'apparence d'un champ (Entrée / Espace ouvrent le calendrier) |
| 5 | Case « J'accepte les conditions » sans nom | Inscription | 4.1.2 | 11.1 | La case porte sa phrase |
| 6 | Aucun titre marqué comme tel ; titre de section fusionné avec le lien voisin | Tous | 1.3.1, 2.4.6 | 9.1 | Titres de page et de section déclarés ; liens séparés |
| 7 | Cartes de choix sans rôle de bouton radio | Questionnaire de profil | 4.1.2 | 7.1 | Rôle radio + état coché |
| 8 | Zones tactiles < 44 px (puces, liens, menus « ⋮ », petits boutons, champs de séries) | Progrès, Entraînement, dialogues | 2.5.5 * | — | Zone tactile élargie à 44 px sans changer le visuel |
| 9 | Texte blanc sur rouge à 3:1 | Bouton « Supprimer », enregistrement vidéo | 1.4.3 | 3.2 | Texte sombre (5,8:1) |
| 10 | Bordure des champs à 1,5:1 sur le fond | Tous les formulaires | 1.4.11 | 3.3 | Nouvelle couleur `borderStrong` (3,7:1) |
| 11 | Libellé « TEMPS ÉCOULÉ » à 3,97:1 | Séance en cours | 1.4.3 | 3.2 | Opacité retirée |
| 12 | Débordements à 200 % : barre d'onglets, calendrier, carte IA, feuilles de séance et de séries, menu déroulant, score d'analyse | Accueil, Planning, Entraînement, Profil, Résultats | 1.4.4, 1.4.10 | 10.4, 10.11 | Hauteurs minimales au lieu de fixes, retours à la ligne, contenus défilants |
| 13 | Titres de page réduits par `FittedBox` quand le texte est agrandi | Toutes les pages avec barre de titre | 1.4.4 | 10.4 | La barre grandit avec le texte, puis le titre passe sur deux lignes |
| 14 | Textes système en anglais (« Show menu », sélecteur de date, infobulles) | Toute l'application | 3.1.1, 3.1.2 | 8.3, 8.7 | Localisation française de Flutter (`flutter_localizations`) |
| 15 | Page web sans langue ni titre propre à chaque écran | Web | 3.1.1, 2.4.2 | 8.3, 8.5, 8.6 | `lang="fr"` ; titre « Écran · LiftUp » mis à jour à chaque navigation |
| 16 | Arbre d'accessibilité web créé seulement après un clic sur un bouton caché | Web | 4.1.2 | 7.1 | Activé dès le démarrage |
| 17 | Commandes de la caméra sans nom (fermer, flash, changer de caméra, enregistrer) | Enregistrement vidéo | 1.1.1, 4.1.2 | 1.1, 7.1 | Infobulles et libellés |
| 18 | Étape du questionnaire annoncée deux fois, et pas annoncée au changement | Questionnaire | 4.1.3 | 7.5 | Une seule annonce, en zone dynamique |
| 19 | Message de chargement de la génération lu toutes les 0,85 s | Génération | 4.1.3 | 7.5 | Seule la phrase principale est annoncée |
| 20 | Valeurs abrégées mal lues (« 0 j », « 0/2 », « 27,4 k », « 3 × 8 • 80 kg », « 72/100 ») | Accueil, Progrès, Entraînement, Résultats | 1.3.1 | — | Formulation lue en clair (« 3 séries de 8 répétitions, 80 kg ») |
| 21 | Compteurs +/− lus comme deux boutons « Moins » / « Plus » sans contexte | Création de séance | 4.1.2 | 7.1 | Contrôle ajustable unique (glisser haut / bas) |
| 22 | Animations en boucle (squelettes, icône de génération, transitions) malgré « réduire les animations » | Chargements, navigation | 2.3.3 ** | 13.8 | Animations coupées quand le système le demande |
| 23 | Focus clavier peu visible sur les surfaces sombres | Web, clavier | 2.4.7 | 10.7 | Surbrillance cyan sur tous les éléments focusables |
| 24 | Autorisation caméra iOS rédigée en anglais | iOS | 3.1.1 | 8.3 | Texte en français |

\* 2.5.5 est un critère AAA ; la règle des 44 px vient de la stratégie du projet.
\*\* 2.3.3 est un critère AAA, traité car l'application est très animée.

## 4. Bilan par écran

✅ conforme sur les points testés · ⏳ à confirmer sur appareil

| Écran | Nom / rôle | Clavier | Contraste | Texte 200 % | Zones tactiles |
|---|---|---|---|---|---|
| Bienvenue, connexion, inscription | ✅ | ✅ | ✅ | ✅ | ✅ |
| Questionnaire de profil | ✅ | ✅ | ✅ | ✅ | ✅ |
| Accueil | ✅ | ⏳ | ✅ | ✅ | ✅ |
| Entraînement + feuilles | ✅ | ⏳ | ✅ | ✅ | ✅ |
| Planning | ✅ | ⏳ | ✅ | ✅ | ✅ |
| Progrès | ✅ | ⏳ | ✅ | ✅ | ✅ |
| Profil + dialogues | ✅ | ⏳ | ✅ | ✅ | ✅ |
| Génération de programme | ✅ | ⏳ | ✅ | ✅ | ✅ |
| Vidéo (sélection, envoi, résultats) | ✅ | ⏳ | ✅ | ✅ | ✅ |
| Enregistrement vidéo (caméra) | ✅ | ⏳ | ✅ | ⏳ | ⏳ |

Le parcours clavier complet n'est testé automatiquement que sur la connexion
et le questionnaire. L'écran caméra n'est pas couvert par les tests
automatiques, car il exige une vraie caméra.

## 5. Ce qui reste à faire

**Avant de clore la Phase 1**
- Passer la checklist du §6 avec TalkBack (Android) et VoiceOver (iOS) sur un
  vrai téléphone : les tests vérifient ce que l'app *déclare*, pas la façon
  dont chaque lecteur d'écran le restitue.
- « Conditions d'utilisation » et « politique de confidentialité » ont
  l'aspect de liens mais ne mènent nulle part : il faut créer les pages ou
  retirer le style de lien.

**Phase 2**
- Ordre de lecture et focus après l'ouverture / fermeture des feuilles,
  vérifié sur appareil.
- Libellés de la barre d'onglets : à 200 % ils rétrécissent au lieu de
  grandir. iOS prévoit pour ce cas un affichage agrandi à l'appui long
  (Large Content Viewer).
- Mode « contraste renforcé » (7:1) prévu par la stratégie.
- Sous-titres / transcription si des vidéos de démonstration avec son sont
  ajoutées.

**Corrections à apporter aux documents**
- ACCESSIBILITY_STRATEGY.md §4.2 cite `flutter analyze --check-semantics` :
  cette option n'existe pas. Les contrôles équivalents sont dans
  `test/accessibility/`.
- `test/widget_test.dart` est le test « compteur » du modèle Flutter de départ
  et échoue sans rapport avec l'application. Il fait échouer un `flutter test`
  complet, pas `flutter test --tags accessibility`.

## 6. Checklist manuelle (TalkBack / VoiceOver)

À faire sur téléphone, lecteur d'écran activé, puis avec la taille de texte
système au maximum :

- [ ] Connexion : chaque champ est annoncé par son libellé, l'erreur
      « identifiants incorrects » est lue sans déplacer le focus.
- [ ] Questionnaire : les cartes de fréquence sont annoncées comme boutons
      radio, le changement d'étape est annoncé.
- [ ] Accueil : balayer jusqu'aux statistiques, « Série, 3 jours » est lu en
      une fois.
- [ ] Planning : double-toucher un jour sélectionne le jour et affiche ses
      séances ; « Mois suivant » change le mois annoncé.
- [ ] Entraînement : ouvrir une séance, la démarrer, ouvrir un exercice, saisir
      un poids dans « Série 1, poids en kg », enregistrer.
- [ ] Création de séance : le compteur de séries se règle en balayant vers le
      haut / bas.
- [ ] Profil : ouvrir « Informations personnelles », choisir une date au
      calendrier, enregistrer.
- [ ] Génération : « Construction de ton programme… » est annoncé une seule
      fois.
- [ ] Enregistrement vidéo : les quatre boutons de la caméra sont nommés.
- [ ] Réglage « supprimer les animations » activé : plus aucune animation en
      boucle.

## 7. Lancer les tests

```bash
cd client/app
flutter test --tags accessibility
```

| Fichier | Contenu |
|---|---|
| `test/accessibility/screens_test.dart` | Règles Flutter + texte à 200 % sur chaque écran |
| `test/accessibility/flows_test.dart` | Idem sur les feuilles, dialogues et pages vidéo |
| `test/accessibility/semantics_test.dart` | Titres, noms, rôles, clavier, zones tactiles, animations, langue |
| `test/accessibility/contrast_test.dart` | Contraste de chaque paire de couleurs du thème |
| `test/accessibility/a11y_harness.dart` | Application de test (fausses API, police réelle, utilisateur connecté) |
