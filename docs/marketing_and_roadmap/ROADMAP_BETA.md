# Roadmap de bêta-test — LiftUp

> **Dates proposées à valider avec l'équipe et la disponibilité technique.**  
> Version : 1.0 — 19 octobre 2026.

## 1. Objectif

Organiser une bêta avec des dates, des responsables, des livrables et des critères de sortie. La bêta doit vérifier des parcours réels, recueillir des retours structurés et transformer les problèmes les plus importants en corrections planifiées.

## 2. Les trois dates de référence

| Jalon | Date proposée | Résultat attendu |
|---|---|---|
| **X — Début de la bêta** | **16 novembre 2026** | Version testable distribuée aux participants, consignes et canal de support prêts |
| **Y — Restitution de la bêta** | **7 décembre 2026** | Présentation du bilan, des indicateurs, des bugs, des retours utilisateurs et des décisions |
| **Z — Fin de la première vague de corrections** | **8 janvier 2027** | Corrections prioritaires intégrées et vérifiées, avec liste explicite des éléments reportés |

La date Z désigne la fin visée de la première vague de corrections, pas une promesse que toutes les suggestions seront intégrées. Les demandes seront triées selon leur impact, leur coût, leur risque et leur cohérence avec le périmètre du projet.

## 3. Planning détaillé

| Période | Phase | Actions | Livrable / critère de sortie |
|---|---|---|---|
| 19–23 oct. 2026 | Cadrage | Valider le périmètre, les responsables, les critères de succès et les dates | Périmètre bêta validé |
| 26–30 oct. | Préparation technique | Vérifier les parcours, les environnements, la création de compte, la persistance et le support | Checklist de lancement remplie ; aucun bug bloquant connu non traité |
| 26 oct.–13 nov. | Recrutement et communication | Publier le calendrier éditorial, ouvrir le formulaire, sélectionner les participants | 10–15 candidatures qualifiées visées ; participants confirmés |
| 2–13 nov. | Préparation testeurs | Envoyer les consignes, vérifier la compatibilité des appareils, préparer questionnaires et canal de support | Participants informés et tâches de test comprises |
| **16 nov.–6 déc.** | **Exécution de la bêta** | Faire réaliser les scénarios, collecter bugs, observations et questionnaires | Données de test et retours centralisés |
| 16–20 nov. | Vague 1 : démarrage | Vérifier installation, inscription, connexion et premier parcours | Blocages d'accès identifiés rapidement |
| 23–27 nov. | Vague 2 : usage | Tester les séances, exercices, sauvegarde et récupération des données | Taux de réussite par scénario |
| 30 nov.–4 déc. | Vague 3 : clôture | Tester les parcours restants, relancer les participants et recueillir les retours finaux | Questionnaire de sortie et liste consolidée |
| **7 déc.** | **Y — Restitution** | Présenter chiffres, problèmes, retours, limites, priorités et décisions | Rapport de restitution et backlog trié |
| 8–11 déc. | Priorisation | Classer les retours : bloquant, majeur, normal, amélioration | Tickets assignés avec critères d'acceptation |
| 14 déc.–8 janv. 2027 | Corrections | Corriger les problèmes prioritaires, ajouter les améliorations retenues et tester les régressions | Version corrigée et notes de version |
| **8 janv. 2027** | **Z — Bilan des corrections** | Vérifier les corrections et communiquer ce qui est livré ou reporté | Bilan de la vague 1 et roadmap suivante |

Prévoir une pause de fin d'année dans la planification de l'équipe. Si la disponibilité réelle ne permet pas de tenir ces jalons, la date Z doit être déplacée avant le lancement plutôt que de réduire les tests de sécurité ou de qualité.

## 4. Périmètre de test proposé

Prioriser les parcours indispensables au MVP :

1. Installer et lancer l'application sur un appareil compatible.
2. Créer un compte et se connecter.
3. Consulter et modifier les informations de profil prévues.
4. Créer ou consulter un programme / une séance, selon les fonctionnalités réellement disponibles dans la version distribuée.
5. Ajouter des exercices, saisir les séries et répétitions, puis sauvegarder.
6. Quitter et relancer l'application, puis vérifier que les données sont toujours présentes.
7. Si l'analyse vidéo est incluse dans la version bêta, envoyer une vidéo compatible et vérifier que l'application présente un résultat explicable, ou un message d'erreur compréhensible.
8. Signaler un bug et remplir le questionnaire de fin.

Ne pas inclure une fonctionnalité dans le protocole si elle n'est pas réellement disponible dans la version candidate. Si la génération de programmes personnalisés ou l'analyse IA n'est pas assez fiable, la documenter comme expérimentale ou l'exclure du périmètre de validation.

## 5. Indicateurs de réussite proposés

Ces objectifs s'appuient sur les cibles de bêta déjà évoquées dans le projet, mais ils doivent être confirmés par l'équipe avant le lancement.

| Indicateur | Cible proposée | Méthode |
|---|---:|---|
| Bêta-testeurs actifs | 8–12 | Au moins une session de test documentée |
| Scénarios essentiels terminés | ≥ 80 % des testeurs actifs | Checklist de scénarios |
| Persistance des séries enregistrées | 100 % sur les cas testés | Comparer saisie et données relues après redémarrage |
| Temps de réponse API | < 3 s pour les requêtes ciblées, hors traitement vidéo lourd | Mesure côté client / logs horodatés |
| Disponibilité pendant la fenêtre de test | Objectif de 99 % si l'instrumentation le permet | Surveillance et calcul du temps disponible |
| Bugs bloquants ouverts à la restitution | 0 idéalement ; sinon plan et risque explicités | Backlog de bugs |
| Retours utilisateurs exploitables | ≥ 8 questionnaires complets visés | Formulaire de fin |
| Traçabilité des suggestions | 100 % des retours classés | Backlog avec statut : retenu, reporté, refusé |

Les résultats doivent être rapportés avec les nombres absolus et la méthode de calcul. Si la bêta est trop petite pour estimer la disponibilité ou les performances de manière robuste, préciser cette limite au lieu de présenter une mesure comme représentative d'une production à grande échelle.

## 6. Collecte et traitement des retours

Chaque bug ou suggestion doit contenir :
- un identifiant ;
- le scénario concerné ;
- la version et l'appareil ;
- les étapes pour reproduire ;
- le résultat attendu et le résultat observé ;
- la gravité et l'impact utilisateur ;
- une capture ou un journal si nécessaire, en retirant les données personnelles ;
- un responsable et un statut.

### Grille de priorité

| Niveau | Définition | Exemple |
|---|---|---|
| P0 — Bloquant | Empêche l'utilisation ou expose des données | Impossible de se connecter, accès non autorisé |
| P1 — Majeur | Empêche un parcours essentiel ou provoque une perte de données | Séries non sauvegardées |
| P2 — Normal | Fonctionnement dégradé avec contournement possible | Écran de résultat incomplet |
| P3 — Amélioration | Confort, ergonomie ou demande non essentielle | Ajustement visuel |

Une demande populaire n'est pas automatiquement prioritaire : l'équipe doit aussi considérer le risque, la valeur utilisateur, le coût et le périmètre du MVP.

## 7. Réunion de restitution — 7 décembre 2026

### Agenda proposé (45–60 minutes)
1. Rappel des objectifs et du périmètre.
2. Profil des participants et taux de participation.
3. Résultats chiffrés par scénario.
4. Bugs bloquants et majeurs.
5. Retours qualitatifs récurrents.
6. Limites de l'essai et résultats non concluants.
7. Décisions : corriger, reporter, approfondir ou abandonner.
8. Présentation de la feuille de route jusqu'au 8 janvier.

### Structure du compte rendu
- Résumé exécutif.
- Méthode et taille de l'échantillon.
- Résultats et indicateurs.
- Problèmes observés.
- Citations anonymisées et autorisées.
- Décisions et raisons.
- Backlog priorisé avec responsables et dates.
- Risques restant ouverts.
- Prochaine date de validation.

## 8. Critère de fin de la vague de corrections — 8 janvier 2027

La vague de corrections est considérée comme terminée lorsque :
- chaque P0/P1 identifié a été corrigé ou fait l'objet d'une décision de blocage documentée ;
- les corrections ont été vérifiées par un test reproductible ;
- les tests de régression pertinents ont été exécutés ;
- les demandes non retenues ou reportées ont une justification ;
- une version et des notes de changement sont disponibles ;
- l'équipe décide si une deuxième bêta est nécessaire.

## 9. Décisions à prendre lors de la prochaine réunion

- [ ] Valider ou déplacer les dates X, Y et Z.
- [ ] Nommer un responsable de la bêta et un responsable de la communication.
- [ ] Confirmer les plateformes et appareils pris en charge.
- [ ] Définir les fonctionnalités effectivement testables.
- [ ] Valider les critères de succès et le questionnaire.
- [ ] Choisir le canal privé de support.
- [ ] Définir les règles de confidentialité et de consentement.
- [ ] Confirmer la capacité de l'équipe à corriger les retours pendant la période prévue.
