# Stratégie d'Accessibilité (A11y) - LiftUp-EIP

**Version du Document:** 1.0  
**Dernière Mise à Jour:** 10 Février 2026  
**Objectif de Conformité:** WCAG 2.1 Niveau AA / RGAA 4.1  
**Statut:** Planification de l'Accessibilité Pré-Développement

---

## Résumé Exécutif

LiftUp s'engage à offrir une expérience de coaching de remise en forme inclusive et accessible à tous les utilisateurs, y compris les personnes en situation de handicap (PSH). Ce document décrit notre stratégie d'accessibilité, nos objectifs de conformité et nos directives d'implémentation pour s'assurer que l'application est utilisable par les personnes ayant des déficiences visuelles, motrices, auditives et cognitives.

**Engagements Clés:**
- **Conformité WCAG 2.1 Niveau AA** (norme internationale)
- **Conformité RGAA 4.1** (réglementation française pour les services numériques publics)
- **Support complet d'iOS VoiceOver** et **Android TalkBack**
- **Ratio de contraste minimum de 4.5:1** pour tout le texte
- **Cible tactile minimum de 44x44pt** pour tous les éléments interactifs
- **Support de la navigation au clavier / par contacteur**

**Impact:**
- **15% de la population mondiale** a une forme de handicap (OMS)
- **2.2 milliards de personnes** dans le monde ont une déficience visuelle
- **1.3 milliard de personnes** vivent avec un handicap significatif
- **L'accessibilité mobile** est critique pour l'indépendance en matière de fitness

---

## 1. Normes d'Accessibilité

### 1.1 Normes Internationales: WCAG 2.1

**Règles pour l'accessibilité des contenus Web (WCAG) 2.1**  
Publié par: W3C Web Accessibility Initiative (WAI)  
Version Actuelle: WCAG 2.1 (2018), WCAG 2.2 (2023)  
Statut Légal: Norme internationale, juridiquement contraignante dans l'UE sous la norme EN 301 549

**Quatre Principes Fondamentaux (POUR):**

#### 1.1.1 Perceptible
*Les informations et les composants de l'interface utilisateur doivent être présentés aux utilisateurs de manière à ce qu'ils puissent les percevoir.*

**Exigences pour LiftUp:**
- Alternatives textuelles pour les contenus non textuels (images, icônes, graphiques)
- Sous-titres et alternatives pour les médias (vidéos d'entraînement)
- Contenu présenté de différentes manières sans perte d'information
- Contraste de couleur suffisant et texte redimensionnable
- Ne pas s'appuyer uniquement sur la couleur pour transmettre une information

#### 1.1.2 Utilisable
*Les composants de l'interface utilisateur et la navigation doivent être utilisables.*

**Exigences pour LiftUp:**
- Toute fonctionnalité accessible via un clavier/lecteur d'écran
- Les utilisateurs disposent de suffisamment de temps pour lire et utiliser le contenu
- Aucun contenu susceptible de provoquer des crises (clignotement < 3 fois par seconde)
- Multiples façons de naviguer et de trouver du contenu
- Indicateurs de focus clairs sur les éléments interactifs

#### 1.1.3 Compréhensible
*Les informations et l'utilisation de l'interface utilisateur doivent être compréhensibles.*

**Exigences pour LiftUp:**
- Le texte est lisible et compréhensible
- Le contenu apparaît et fonctionne de manière prévisible
- Les utilisateurs sont aidés pour éviter et corriger les erreurs
- Messages d'erreur clairs avec des suggestions

#### 1.1.4 Robuste
*Le contenu doit être suffisamment robuste pour être interprété par une grande variété d'agents utilisateurs, y compris les technologies d'assistance.*

**Exigences pour LiftUp:**
- Compatible avec les technologies d'assistance actuelles et futures
- Balisage sémantique valide (équivalent dans le mobile natif)
- Noms, rôles et valeurs déterminables par programmation

### 1.2 Norme Française: RGAA 4.1

**Référentiel Général d'Amélioration de l'Accessibilité (RGAA)**  
Publié par: DINUM (Direction Interministérielle du Numérique)  
Version Actuelle: RGAA 4.1 (2021)  
Base Légale: Article 47 de la loi française n° 2005-102 (11 février 2005)

**Applicabilité à LiftUp:**

| Question | Réponse | Exigence RGAA |
|----------|---------|---------------|
| LiftUp est-il un service public ? | Non | Non légalement requis |
| LiftUp est-il un service privé ouvert au public ? | Oui | Optionnel mais recommandé |
| Chiffre d'affaires annuel > 250M€ ? | Non (startup) | Non obligatoire |
| **Conformité Volontaire ?** | **Oui** | **Avantage concurrentiel** |

**Avantages de la Conformité RGAA:**
- Crédibilité et confiance sur le marché français
- Éligibilité au label "Accessibilité Numérique"
- Marché adressable plus large (inclusion du handicap)
- Anticipation des changements réglementaires

**RGAA vs WCAG:**
```yaml
Alignement:
  - Le RGAA 4.1 est basé sur les WCAG 2.1
  - 106 critères mappés sur les critères de succès WCAG
  - Exigences supplémentaires spécifiques à la France:
    * Accessibilité de la langue française
    * Normes de communication gouvernementales
    
Différences Clés:
  - Le RGAA a une méthodologie de test plus prescriptive
  - Le RGAA comprend des cas de test spécifiques (258 tests)
  - Format de déclaration de conformité RGAA spécifié
```

### 1.3 Niveau de Conformité Cible

**Niveaux de Conformité WCAG:**

| Niveau | Exigences | Cible LiftUp |
|-------|-------------|---------------|
| **Niveau A** | Accessibilité minimum<br>Support de base tech asssistance | Indispensable (base) |
| **Niveau AA** | Supprime les barrières significatives<br>Standard industrie | **Cible principale** |
| **Niveau AAA** | Accessibilité maximale<br>Pas toujours possible pour tous | Partiel (où réalisable) |

**Cible de Conformité LiftUp:**

```yaml
Cible Officielle: WCAG 2.1 Niveau AA

Justification:
  - Le niveau AA est la norme standard internationalement reconnue
  - Requis pour les marchés publics de l'UE
  - Réalisable pour une application de fitness mobile
  - Couvre 99% des besoins en accessibilité
  
Considérations Niveau AAA:
  - Où réalisable sans compromettre l'UX de base
  - Interprétation en langue des signes avancée: Non planifié (trop coûteux)
  - Audiodescriptions étendues: Planifié pour le contenu vidéo
  - Contraste amélioré (ratio 7:1): Option dans les paramètres
```

**Calendrier de Conformité:**
```
Phase 1 (MVP): Niveau A + AA partiel (80%)
Phase 2 (v1.0): Conformité Niveau AA complète
Phase 3 (v2.0+): Sélection de fonctionnalités Niveau AAA
Continu: Maintenir la conformité avec les mises à jour
```

### 1.4 EN 301 549 (Norme Européenne)

**Exigences d'accessibilité pour les produits et services TIC**

**Pertinence pour LiftUp:**
- Les applications mobiles relèvent de la section 11 (Applications mobiles)
- Harmonisé avec les WCAG 2.1 Niveau AA
- Requis pour les appels d'offres du secteur public de l'UE
- Adoption volontaire pour le secteur privé (recommandée)

**Exigences Supplémentaires EN 301 549:**
- La documentation doit être accessible
- Les services d'assistance doivent être accessibles
- Compatibilité avec les technologies d'assistance
