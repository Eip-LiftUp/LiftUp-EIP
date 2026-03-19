# Stratégie d'Accessibilité (A11y) - LiftUp-EIP

**Version du document:** 1.0  
**Dernière mise à jour:** 10 Février 2026  
**Cible de conformité:** WCAG 2.1 Niveau AA / RGAA 4.1  
**Statut:** Planification de l'Accessibilité Pré-Développement

---

## Résumé Exécutif

LiftUp s'engage à offrir une expérience de coaching fitness inclusive et accessible à tous les utilisateurs, y compris les personnes en situation de handicap (PSH). Ce document détaille notre stratégie d'accessibilité, nos objectifs de conformité et nos directives d'implémentation pour garantir l'utilisation de l'application par des personnes souffrant de déficiences visuelles, motrices, auditives et cognitives.

**Engagements Clés:**
- **Conformité WCAG 2.1 Niveau AA** (norme internationale)
- **Conformité RGAA 4.1** (référentiel français des services publics)
- Support intégral **iOS VoiceOver** et **Android TalkBack**
- **Ratio de contraste minimal de 4.5:1** pour tout texte
- **Taille de cible tactile minimale de 44x44pt** pour les éléments interactifs
- Support de la **navigation clavier/contacteur (switch)**

**Impact:**
- **15% de la population mondiale** vit avec une forme de handicap (OMS)
- **2,2 milliards de personnes** ont une déficience visuelle dans le monde
- **1,3 milliard de personnes** vivent avec un handicap sévère
- **L'accessibilité mobile** est primordiale pour l'autonomie en matière de santé/sport

---

## 1. Normes d'Accessibilité

### 1.1 Normes Internationales : WCAG 2.1

**Règles pour l'accessibilité des contenus Web (WCAG) 2.1**  
Éditeur : W3C Web Accessibility Initiative (WAI)  
Version Actuelle : WCAG 2.1 (2018), WCAG 2.2 (2023)  
Statut Légal : Norme internationale, légalement contraignante au sein de l'UE sous la norme EN 301 549

**Quatre Principes Fondamentaux (POUR) :**

#### 1.1.1 Perceptible
*L'information et les composants de l'interface utilisateur doivent être présentés à l'utilisateur de façon à ce qu'il puisse les percevoir.*

**Exigences pour LiftUp :**
- Alternatives textuelles pour les contenus non-textuels (images, icônes, graphiques)
- Sous-titres et alternatives pour les médias (vidéos de workout)
- Contenu présentable de différentes façons sans perte d'information
- Contraste de couleur suffisant et texte redimensionnable
- L'information ne doit pas reposer uniquement sur la couleur

#### 1.1.2 Utilisable
*Les composants de l'interface utilisateur et la navigation doivent être utilisables.*

**Exigences pour LiftUp :**
- Toutes les fonctionnalités doivent être accessibles au clavier/lecteur d'écran
- Les utilisateurs doivent avoir assez de temps pour lire et utiliser le contenu
- Aucun contenu ne doit provoquer de crises (clignotement < 3 fois par seconde)
- Plusieurs moyens de naviguer et de trouver du contenu
- Indicateurs de focus clairement visibles sur les éléments interactifs

#### 1.1.3 Compréhensible
*Les informations et l'utilisation de l'interface utilisateur doivent être compréhensibles.*

**Exigences pour LiftUp :**
- Le texte est lisible et compréhensible
- Le contenu apparaît et s'utilise de manière prévisible
- Les utilisateurs sont aidés dans l'évitement et la correction des erreurs
- Messages d'errreur clairs avec suggestions

#### 1.1.4 Robuste
*Le contenu doit être suffisamment robuste pour être interprété de manière fiable par une grande variété d'agents utilisateurs, y compris les technologies d'assistance.*

**Exigences pour LiftUp :**
- Compatible avec les technologies d'assistance actuelles et futures
- Balisage sémantique valide (équivalent en mobile natif)
- Noms, rôles et valeurs identifiables programmatiquement

### 1.2 Norme Française : RGAA 4.1

**Référentiel Général d'Amélioration de l'Accessibilité (RGAA)**  
Éditeur : DINUM (Direction Interministérielle du Numérique)  
Version Actuelle : RGAA 4.1 (2021)  
Base Légale : Article 47 de la Loi n° 2005-102 (11 Février 2005)

**Applicabilité à LiftUp :**

| Question | Réponse | Obligation RGAA |
|----------|--------|------------------|
| LiftUp est-elle un service public ? | Non | Non requis légalement |
| LiftUp est-elle ouverte au public ? | Oui | Facultatif mais recommandé |
| Chiffre d'affaires > 250M€ ? | Non (startup) | Non obligatoire |
| **Conformité volontaire ?** | **Oui** | **Avantage concurrentiel** |

**Avantages d'une conformité RGAA :**
- Crédibilité et confiance sur le marché Français
- Éligibilité au label "Accessibilité Numérique"
- Marché adressable élargi (inclusion du handicap)
- Pérennité face aux évolutions réglementaires

**RGAA vs WCAG :**
```yaml
Alignement:
  - RGAA 4.1 est basé sur WCAG 2.1
  - 106 critères calqués sur les critères de réussite WCAG
  - Exigences additionnelles spécifiques (France):
    * Accessibilité relative à la langue française
    * Normes de communication gouvernementale
    
Différences Clés:
  - RGAA possède une méthodologie de test très stricte
  - RGAA inclut des cas de tests spécifiques (258 tests)
  - Le format de la déclaration de conformité est imposé
```

### 1.3 Niveau de Conformité Cible

**Niveaux de Conformité WCAG :**

| Niveau | Exigences | Cible LiftUp |
|-------|-------------|---------------|
| **Niveau A** | Accessibilité minimale<br>Support de base tech | Obligatoire (socle) |
| **Niveau AA** | Dépasse les gros blocages<br>Standard de l'industrie | **Cible Actuelle** |
| **Niveau AAA** | Accessibilité maximale<br>Pas toujours possible | Partiel (selon faisabilité) |

**Cible de Conformité LiftUp :**

```yaml
Cible Officielle: WCAG 2.1 Niveau AA

Justifications:
  - Le Niveau AA est le standard industriel mondialement reconnu
  - Requis pour les appels d'offres publics de l'UE
  - Réalisable pour une app fitness mobile
  - Couvre 99% des besoins d'accès
  
Considérations Niveau AAA:
  - Intégré là où c'est possible sans casser l'UX cœur
  - Langue des signes avancée : Non prévu (coût rédhibitoire)
  - Audio descriptions avancées : Prévu pour les vidéos
  - Contraste accru (ratio 7:1) : Option "High Contrast" dans les settings
```

**Calendrier de Conformité :**
```
Phase 1 (MVP): Conformité Niveau A + partiellement AA (80%)
Phase 2 (v1.0): Pleine conformité Niveau AA
Phase 3 (v2.0+): Sélection de fonctionnalités Niveau AAA
Continu: Maintien de l'accessibilité lors des updates
```

### 1.4 EN 301 549 (Norme Européenne)

**Exigences d'accessibilité pour les produits et services TIC**

**Pertinence pour LiftUp :**
- Les applications mobiles relèvent de la section 11 (Applications Mobiles)
- Harmonisé avec WCAG 2.1 Niveau AA
- Requis pour répondre aux marchés publics de l'Union Européenne
- Adoption volontaire pour le domaine privé fortement recommandée

**Exigences supplémentaires EN 301 549 :**
- La documentation doit être accessible
- Le SAV/Support technique doit être accessible
- Obligation de compatibilité avec les technologies d'assistance

---

## 2. Types de Handicaps & Besoins d'Accessibilité

### 2.1 Déficiences Visuelles

#### 2.1.1 Cécité (Perte de vue totale)

**Profils Utilisateurs :**
```
Marie, 32 ans, Powerlifteuse aveugle
- Technologies d'assistance : iPhone avec VoiceOver
- Navigation : Gestes de balayage, commandes vocales
- Défis : Reconnaître les exercices, comprendre les indications de posture
- Besoins : Audiodescriptions claires, ordre de navigation logique
```

**Exigences d'Accessibilité :**

**Support du Lecteur d'Écran :**
```dart
// Exemple Flutter : Labels sémantiques
Semantics(
  label: 'Exercice de squat, 4 séries de 8 répétitions à 100 kilos',
  hint: 'Touchez deux fois pour voir les détails de l\'exercice',
  button: true,
  enabled: true,
  child: ExerciseCard(exercise: squat),
)

// Descriptions de contenu explicites
Semantics(
  label: 'Progression de l\'entraînement actuel : 3 sur 5 exercices terminés',
  value: '60 pourcent',
  child: CircularProgressIndicator(value: 0.6),
)
```

**Checklist d'Implémentation :**
- [ ] Tous les éléments de l'UI ont des labels sémantiques
- [ ] Les images ont un texte alternatif descriptif (pas "image1.png")
- [ ] Les graphiques ont des alternatives textuelles
- [ ] Les champs de formulaire ont des étiquettes appropriées (pas juste des placeholders)
- [ ] L'ordre de navigation est logique (de haut en bas, de gauche à droite)
- [ ] Le lecteur d'écran annonce les changements de contenu dynamique
- [ ] Les composants personnalisés ont des traits d'accessibilité
- [ ] Les images décoratives sont marquées comme telles (sémantique masquée)

**Descriptions d'Exercices :**
```dart
// Descriptions audio détaillées pour les utilisateurs de lecteurs d'écran
class ExerciseDescriptor {
  String name: "Squat Arrière (Barbell Back Squat)",
  String audioDescription: """
    Tenez-vous debout, les pieds écartés de la largeur des épaules. 
    La barre repose sur le haut du dos, en travers des trapèzes.
    Pliez les genoux et les hanches pour abaisser le corps jusqu'à ce que les cuisses soient parallèles au sol.
    Poussez sur vos talons pour revenir à la position de départ.
    Ceci est une répétition.
  """,
  String formCues: [
    "Gardez la poitrine haute et le tronc engagé",
    "Les genoux suivent la direction des orteils, sans rentrer vers l'intérieur",
    "Profondeur complète : le pli de la hanche sous le genou"
  ],
}
```

**Modèles de Navigation :**
```yaml
Écran d'Accueil (Ordre VoiceOver) :
  1. "Logo LiftUp, en-tête"
  2. "Bouton Entraînement du jour, touchez deux fois pour démarrer"
  3. "Résumé nutritionnel, 1 850 sur 2 200 calories consommées"
  4. "Titre du graphique de progression"
  5. "Progression du poids, augmentation de 2 kilos ce mois-ci"
  6. "Barre d'onglets, 5 éléments : Accueil sélectionné, Entraînements, Nutrition, Progression, Paramètres"
```

**Exigences de Test :**
- [ ] Navigation complète de l'application possible avec VoiceOver (iOS) / TalkBack (Android)
- [ ] Toutes les fonctionnalités accessibles sans voir l'écran
- [ ] Les minuteurs et compteurs de répétitions annoncés automatiquement
- [ ] L'achèvement de l'entraînement confirmé avec retour audio
- [ ] Pas de piège au clavier (l'utilisateur peut s'éloigner de n'importe quel élément)

#### 2.1.2 Basse Vision

**Profils Utilisateurs :**
```
Jean, 67 ans, Retraité avec Dégénérescence Maculaire
- Vision : 20/200, vision périphérique uniquement
- Technologies d'assistance : Grand texte, loupe, mode contraste élevé
- Défis : Lire les petits textes, distinguer les éléments de l'UI
- Besoins : UI évolutive, fort contraste, hiérarchie visuelle claire
```

**Exigences d'Accessibilité :**

**Support Typographie Dynamique (Dynamic Type) :**
```dart
// Respecter la mise à l'échelle du texte du système
Text(
  'Développé Couché (Bench Press)',
  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
    // NE PAS utiliser de tailles de police fixes
    // fontSize: 24,  // MAUVAIS : Ne se met pas à l'échelle
  ),
)

// Autoriser la mise à l'échelle du texte jusqu'à 200%
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(1.0, 2.0),
      ),
      child: child!,
    );
  },
)
```

**Tailles de Texte Minimales :**
```yaml
Texte Principal : 16sp minimum (iOS: 17pt)
Légendes : 12sp minimum (iOS: 13pt)
Labels Interactifs : 14sp minimum (iOS: 15pt)
Infos Critiques : 18sp minimum (iOS: 19pt)

# Tous les textes doivent s'adapter aux paramètres du système
# Pas de texte tramé (dans les images)
```

**Contraste des Couleurs (WCAG AA) :**
```yaml
Texte Normal (< 18pt):
  Ratio de Contraste : Minimum 4.5:1
  Exemples :
    - Noir (#000000) sur Blanc (#FFFFFF) : 21:1
    - Gris Foncé (#595959) sur Blanc : 7:1
    - Gris Clair (#767676) sur Blanc : 4.5:1 (minimum)
    - Gris Clair (#777777) sur Blanc : 4.49:1 (échec)

Grand Texte (≥ 18pt ou gras ≥ 14pt):
  Ratio de Contraste : Minimum 3:1
  Exemples :
    - Gris Moyen (#595959) sur Blanc : 7:1
    - Gris Clair (#999999) sur Blanc : 3:1 (minimum)

Composants UI (boutons, inputs):
  Ratio de Contraste : Minimum 3:1 avec les couleurs adjacentes
  
Palette de Couleurs LiftUp :
  Primaire (Action):
    - Couleur : #1976D2 (Bleu)
    - Sur Blanc : 4.8:1
    - Usage : Boutons, liens, éléments interactifs
  
  Succès (Terminé):
    - Couleur : #388E3C (Vert)
    - Sur Blanc : 5.2:1
    - Usage : Indicateurs de progression, accomplissements
  
  Avertissement (Attention):
    - Couleur : #F57C00 (Orange)
    - Sur Blanc : 3.8:1
    - Usage : Notices importantes, validation des formulaires
  
  Erreur (Échec):
    - Couleur : #D32F2F (Rouge)
    - Sur Blanc : 5.9:1
    - Usage : Erreurs, avertissements de suppression
  
  Texte:
    - Primaire : #212121 (Presque Noir) - 18.7:1
    - Secondaire : #757575 (Gris) - 4.6:1
    - Désactivé : #BDBDBD (Gris Clair) - 3:1 (minimum)
```

**Tests de Contraste :**
```dart
 // Test de contraste automatisé dans la CI
void testContrastRatio(Color foreground, Color background) {
  double ratio = calculateContrastRatio(foreground, background);
  
  expect(ratio, greaterThanOrEqualTo(4.5),
    reason: 'Le contraste du texte doit être au moins 4.5:1 pour la conformité WCAG AA');
}

// Calcul de contraste (Formule WCAG)
double calculateContrastRatio(Color c1, Color c2) {
  double l1 = relativeLuminance(c1);
  double l2 = relativeLuminance(c2);
  
  double lighter = max(l1, l2);
  double darker = min(l1, l2);
  
  return (lighter + 0.05) / (darker + 0.05);
}
```

**Mode Contraste Élevé :**
```dart
// Détecter les paramètres système de contraste élevé
bool isHighContrastEnabled() {
  return MediaQuery.of(context).highContrast;
}

// Thème contraste amélioré
ThemeData highContrastTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.white,
  textTheme: TextTheme(
    bodyMedium: TextStyle(
      color: Colors.black,
      fontSize: 18,  // Taille de base plus grande
      height: 1.5,   // Hauteur de ligne augmentée
      fontWeight: FontWeight.w600,  // Plus gras
    ),
  ),
  // 7:1 ratio de contraste pour la conformité AAA
);
```

**Zoom et Grossissement :**
```dart
// Supporter les gestes système de grossissement
// iOS : Triple tap avec trois doigts
// Android : Raccourci de grossissement

// S'assurer que l'UI ne se casse pas agrandie à 200%
// - Défilement horizontal pour le contenu large
// - Écoulement du texte (pas de troncature)
// - Cibles tactiles qui restent accessibles
```

**Checklist d'Implémentation :**
- [ ] Tous les textes s'adaptent selon les réglages de police du système
- [ ] L'application est testée avec un texte mis à l'échelle de 200%
- [ ] Toutes les combinaisons de couleurs atteignent le minimum 4.5:1 de contraste
- [ ] Le mode de contraste élevé est supporté
- [ ] La couleur n'est pas le seul moyen de transmettre de l'information
- [ ] L'UI est testée avec le Zoom iOS et le Zoom d'Android
- [ ] Les indicateurs de focus atteignent 3:1 de contraste avec l'arrière-plan

#### 2.1.3 Daltonisme

**Types et Prévalence :**
```
Deutéranomalie (Rouge-Vert) : 6% des hommes, 0.4% des femmes
Protanomalie (Rouge-Vert) : 2% des hommes, 0.01% des femmes
Tritanomalie (Bleu-Jaune) : 0.01% de la population (rare)
Achromatopsie (Complète) : 0.003% de la population (très rare)
```

**Exigences d'Accessibilité :**

**Ne Jamais s'Appuyer Seulement sur la Couleur :**
```dart
// MAUVAIS : Indicateurs uniquement via de la couleur
Container(
  color: isCompleted ? Colors.green : Colors.red,
  child: Text('Série'),
)

// BON : Couleur + icône + texte
Row(
  children: [
    Icon(isCompleted ? Icons.check_circle : Icons.cancel),
    SizedBox(width: 8),
    Text(isCompleted ? 'Terminé' : 'Échoué'),
    // La couleur apporte un renfort additionnel
  ],
)
```

**Workout Progress Indicators:**
```dart
// Progress visualization with multiple cues
class WorkoutSetIndicator extends StatelessWidget {
  final bool completed;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: completed ? Colors.green.shade50 : Colors.grey.shade50,
        border: Border.all(
          color: completed ? Colors.green : Colors.grey,
          width: 2,  // Visual border
        ),
      ),
      child: Row(
        children: [
          // Icon provides non-color cue
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? Colors.green : Colors.grey,
            semanticLabel: completed ? 'Terminé' : 'Incomplet',
          ),
          // Le texte fournit une information explicite
          Text(
            completed ? 'Fait' : 'À faire',
            style: TextStyle(
              fontWeight: completed ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          // Remplissage par motif (pour cas extrêmes)
          if (completed) PatternFill(pattern: 'checkered'),
        ],
      ),
    );
  }
}
```

**Accessibilité des Graphiques :**
```dart
// Graphiques en courbes avec de multiples différenciateurs
class AccessibleLineChart extends StatelessWidget {
  final List<WorkoutData> data;
  
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            colors: [Colors.blue],
            spots: data.map((d) => FlSpot(d.x, d.y)).toList(),
            dotData: FlDotData(show: true),  // Points de données visibles
            dashArray: null,  // Ligne pleine
            barWidth: 3,
          ),
          LineChartBarData(
            colors: [Colors.red],
            spots: compareData.map((d) => FlSpot(d.x, d.y)).toList(),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Formes différentes pour lignes différentes
                return FlDotSquarePainter();  // Points carrés vs circulaires
              },
            ),
            dashArray: [5, 5],  // Ligne pointillée (motif différent)
            barWidth: 3,
          ),
        ],
      ),
    );
  }
}

// Légende avec motifs, pas seulement des couleurs
class ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LegendItem(
          label: 'Poids Corporel',
          color: Colors.blue,
          pattern: LinePattern.solid,
          shape: ShapeType.circle,
        ),
        LegendItem(
          label: 'Poids Cible',
          color: Colors.red,
          pattern: LinePattern.dashed,
          shape: ShapeType.square,
        ),
      ],
    );
  }
}
```

**Checklist d'Implémentation :**
- [ ] Aucune information transmise uniquement par la couleur
- [ ] Des icônes, motifs, ou labels textes complètent la couleur
- [ ] Les graphiques utilisent des motifs de ligne, formes, ou labels
- [ ] La validation de formulaire montre des icônes avec les couleurs d'erreur
- [ ] Les messages de succès/erreur incluent des icônes
- [ ] Tests avec simulateur de daltonisme (Sim Daltonism, Color Oracle)

### 2.2 Déficiences Motrices

#### 2.2.1 Dextérité Manuelle Limitée

**Profils Utilisateurs :**
```
Carlos, 45 ans, Arthrite
- Condition : Polyarthrite rhumatoïde, mobilité des doigts limitée
- Défis : Petites cibles tactiles, gestes précis, appuis longs
- Besoins : Grands boutons, gestes simples, saisie vocale
- Technologies d'assistance : Contrôle Vocal, Contacteur (Switch Control)
```

**Exigences d'Accessibilité :**

**Taille des Cibles Tactiles (WCAG 2.5.5) :**
```yaml
Taille de Cible Minimale : 44x44pt (iOS) / 48x48dp (Android)
Recommandé : 48x48pt minimum pour les actions critiques

Espacement entre les Cibles : Minimum 8pt
Recommandé : Espacement de 16pt pour un usage confortable

Exemples:
  - Boutons : 48x48pt minimum
  - Éléments de barre d'onglets : 44x44pt minimum
  - Zones interactives de liste : Pleine largeur, hauteur 56pt minimum
  - Boutons icônes : Zone tactile 48x48pt (l'icône peut être plus petite)
```

**Implémentation :**
```dart
// Assurer la taille minimale de zone tactile
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          // Forcer la taille minimale
          constraints: BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(label),
        ),
      ),
    );
  }
}

// Zone tactile élargie pour les petites icônes
class ExpandedTouchArea extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: IconButton(
          icon: child,
          iconSize: 24,  // Taille visuelle
          padding: EdgeInsets.all(12),  // Padding de la zone tactile
          onPressed: onTap,
        ),
      ),
    );
  }
}
```

**Alternatives aux Gestes :**
```dart
// Fournir des alternatives aux gestes complexes

// MAUVAIS : Actions par glissement uniquement
ListView(
  children: items.map((item) => Dismissible(
    key: Key(item.id),
    onDismissed: (_) => deleteItem(item),
    child: ItemWidget(item),
  )).toList(),
)

// BON : Glissement + alternative bouton
ListView(
  children: items.map((item) => Row(
    children: [
      Expanded(child: ItemWidget(item)),
      // Explicit delete button
      IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => deleteItem(item),
        tooltip: 'Delete ${item.name}',
        // Large touch target
        iconSize: 24,
        padding: EdgeInsets.all(12),
      ),
    ],
  )).toList(),
)
```

**Voice Control Support:**
```dart
// iOS Voice Control / Android Voice Access

// 1. Visible labels for voice commands
// User can say: "Tap Start Workout"
ElevatedButton(
  onPressed: startWorkout,
  child: Text('Start Workout'),  // Visible label for voice command
)

// 2. Accessibility labels for unlabeled elements
// User can say: "Tap menu button"
IconButton(
  icon: Icon(Icons.menu),
  onPressed: openMenu,
  tooltip: 'Menu',  // Used by voice control
)

// 3. Number overlays work automatically
// User can say: "Tap 3" to activate third item
```

**Switch Control Support:**
```dart
// iOS Switch Control / Android Switch Access
// Single-switch or two-switch scanning

// Requirements:
// - Focus order must be logical
// - All interactive elements must be focusable
// - Grouped elements for efficient scanning

Semantics(
  container: true,  // Group related elements
  child: Column(
    children: [
      Text('Bench Press'),
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: decreaseWeight,
          ),
          Text('100 kg'),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: increaseWeight,
          ),
        ],
      ),
    ],
  ),
)
```

**Implementation Checklist:**
- [ ] All interactive elements minimum 44x44pt
- [ ] Spacing between targets minimum 8pt
- [ ] No functionality requires precise gestures
- [ ] Alternatives to multi-touch gestures
- [ ] Alternatives to time-based interactions
- [ ] Voice Control/Voice Access tested
- [ ] Switch Control/Switch Access tested
- [ ] Shake gestures have alternatives (no shaking required)

#### 2.2.2 Tremors and Reduced Precision

**Accessibility Requirements:**

**Accidental Activation Prevention:**
```dart
// Confirmation for destructive actions
Future<void> deleteWorkout(Workout workout) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Workout?'),
      content: Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    performDeletion(workout);
  }
}
```

**Undo Functionality:**
```dart
// Provide undo for accidental actions
void deleteExercise(Exercise exercise) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  // Perform deletion
  repository.delete(exercise);
  
  // Show undo option
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Text('Exercise deleted'),
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          repository.restore(exercise);
        },
      ),
    ),
  );
}
```

**Sticky Keys / Tap Assistance:**
```yaml
iOS Settings → Accessibility → Touch → Tap Assistance
  - Ignore Repeat: Prevent multiple taps
  - Tap Assistance: Hold duration before tap registers

Android Settings → Accessibility → Timing Controls
  - Touch & hold delay: Adjust long-press timing
  - Time to take action: Longer timeout for dialogs
```

**Implementation Checklist:**
- [ ] Confirmation dialogs for destructive actions
- [ ] Undo functionality for important actions
- [ ] No drag-and-drop as only method
- [ ] No hover-required functionality
- [ ] Timeout warnings (30 seconds before session expires)
- [ ] App respects platform touch accommodation settings

### 2.3 Hearing Impairments

#### 2.3.1 Deafness and Hard of Hearing

**User Personas:**
```
Emma, 28, Deaf Athlete
- Assistive Tech: None needed for visual app
- Challenges: Audio-only feedback, video instructions without captions
- Needs: Visual feedback, captions, text alternatives to audio
```

**Accessibility Requirements:**

**Visual Feedback:**
```dart
// Never rely on audio alone

// BAD: Audio-only timer countdown
void playCountdownBeep() {
  audioPlayer.play('beep.mp3');  // Deaf users can't hear
}

// GOOD: Visual + audio feedback
void countdownFeedback(int secondsRemaining) {
  // Visual indicator
  setState(() {
    timerDisplay = secondsRemaining.toString();
    timerColor = secondsRemaining <= 3 ? Colors.red : Colors.white;
  });
  
  // Haptic feedback
  if (secondsRemaining <= 3) {
    HapticFeedback.mediumImpact();
  }
  
  // Audio (supplementary, not required)
  audioPlayer.play('beep.mp3');
  
  // Screen flash (visual alert)
  if (secondsRemaining == 0) {
    flashScreen();
  }
}
```

**Video Captions:**
```yaml
Exercise Tutorial Videos:
  - Closed captions required (WCAG 1.2.2)
  - Caption all spoken words and relevant sounds
  - Caption format: WebVTT or SRT
  - User-controllable (can turn on/off)
  
Caption Content:
  - Spoken dialogue
  - Speaker identification (if multiple people)
  - Sound effects: [weight clangs], [heavy breathing]
  - Music: [upbeat music playing]
  
Caption Quality:
  - Synchronized with video
  - Accurate transcription (99%+)
  - Proper grammar and punctuation
  - Readable font and contrast
```

**Haptic Feedback:**
```dart
// Haptic patterns for different events
import 'package:flutter/services.dart';

class HapticPatterns {
  // Rest timer completion
  static void restComplete() {
    HapticFeedback.heavyImpact();
    Future.delayed(Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }
  
  // Set completion
  static void setComplete() {
    HapticFeedback.mediumImpact();
  }
  
  // Workout completion
  static void workoutComplete() {
    HapticFeedback.heavyImpact();
    Future.delayed(Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
    Future.delayed(Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }
  
  // Error
  static void error() {
    HapticFeedback.vibrate();
  }
}
```

**Implementation Checklist:**
- [ ] All audio has visual equivalent
- [ ] All video content has captions
- [ ] Haptic feedback supplements audio cues
- [ ] Visual alerts (flashing, color change, animation)
- [ ] No audio-only content
- [ ] Volume controls visible (even if not used)
- [ ] Captions tested for accuracy and sync

### 2.4 Cognitive and Learning Disabilities

#### 2.4.1 Reading Difficulties (Dyslexia, Low Literacy)

**Accessibility Requirements:**

**Clear, Simple Language:**
```yaml
Writing Guidelines:
  - Short sentences (15-20 words maximum)
  - Active voice preferred
  - Common words (avoid jargon)
  - Consistent terminology
  - Logical information flow
  
Examples:
 BAD: "Utilize progressive overload methodology to optimize hypertrophic adaptations"
 GOOD: "Gradually increase weight to build muscle"
  
 BAD: "Macro-nutrient partitioning protocol"
 GOOD: "Protein, carbs, and fats daily targets"
```

**Typography:**
```dart
// Dyslexia-friendly typography
TextStyle dyslexiaFriendlyStyle = TextStyle(
  fontFamily: 'OpenDyslexic',  // Or Atkinson Hyperlegible
  fontSize: 18,
  height: 1.5,  // Line spacing: 1.5x minimum
  letterSpacing: 0.5,  // Slight letter spacing
  wordSpacing: 2,  // Increased word spacing
);

// Text alignment
Text(
  longText,
  textAlign: TextAlign.left,  // Never justified (uneven spacing)
  // No center alignment for paragraphs
)
```

**Font Recommendations:**
```yaml
Accessible Fonts:
  Primary Recommendations:
    - Atkinson Hyperlegible (designed for low vision)
    - OpenDyslexic (designed for dyslexia)
    - Lexend (variable font for readability)
  
  System Fallbacks:
    - San Francisco (iOS)
    - Roboto (Android)
  
  Avoid:
    - Decorative fonts
    - Script/cursive fonts
    - All caps text (harder to read)
    - Italics for long passages
```

**Content Structure:**
```dart
// Clear visual hierarchy
class WorkoutInstructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clear heading
        Text(
          'Bench Press',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 16),
        
        // Short, numbered steps
        InstructionStep(
          number: 1,
          text: 'Lie flat on bench',
        ),
        InstructionStep(
          number: 2,
          text: 'Grip bar slightly wider than shoulders',
        ),
        InstructionStep(
          number: 3,
          text: 'Lower bar to chest',
        ),
        InstructionStep(
          number: 4,
          text: 'Press bar up until arms are straight',
        ),
        
        // Visual aids
        SizedBox(height: 24),
        ExerciseAnimation(exercise: benchPress),
      ],
    );
  }
}
```

**Implementation Checklist:**
- [ ] Plain language (8th-grade reading level)
- [ ] Short sentences and paragraphs
- [ ] Clear headings and structure
- [ ] Sans-serif fonts
- [ ] Line spacing 1.5x minimum
- [ ] Left-aligned text (not justified)
- [ ] Important information highlighted
- [ ] Visual aids supplement text

#### 2.4.2 Attention and Memory

**Accessibility Requirements:**

**Minimize Distractions:**
```dart
// Focus mode option
class FocusMode {
  static bool enabled = false;
  
  static Widget build(BuildContext context, Widget child) {
    if (enabled) {
      return Container(
        // Remove distractions
        // - No animations
        // - No auto-playing videos
        // - Simplified UI
        child: SimplifiedUI(child: child),
      );
    }
    return child;
  }
}

// Reduced motion
bool reduceMotion = MediaQuery.of(context).disableAnimations;

Widget buildWithAnimation() {
  return AnimatedContainer(
    duration: reduceMotion ? Duration.zero : Duration(milliseconds: 300),
    curve: reduceMotion ? Curves.linear : Curves.easeInOut,
    // ...
  );
}
```

**Clear Progress Indicators:**
```dart
// Workout progress with clear steps
class WorkoutProgressIndicator extends StatelessWidget {
  final int currentExercise;
  final int totalExercises;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Textual progress
        Text(
          'Exercise $currentExercise of $totalExercises',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        
        // Visual progress bar
        LinearProgressIndicator(
          value: currentExercise / totalExercises,
          semanticsLabel: '$currentExercise of $totalExercises exercises completed',
        ),
        SizedBox(height: 16),
        
        // Step indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalExercises, (index) {
            return Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < currentExercise
                    ? Colors.green  // Completed
                    : index == currentExercise
                        ? Colors.blue  // Current
                        : Colors.grey[300],  // Upcoming
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
```

**Session Timeout:**
```dart
// Extended timeout with warning
class SessionManager {
  final Duration timeout = Duration(minutes: 30);
  final Duration warning = Duration(minutes: 25);
  
  Timer? _timeoutTimer;
  Timer? _warningTimer;
  
  void startSession() {
    _warningTimer = Timer(warning, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Are you still there?'),
          content: Text(
            'Your session will time out in 5 minutes. '
            'Tap "Continue" to keep your session active.'
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                resetSession();
              },
              child: Text('Continue'),
            ),
          ],
        ),
      );
    });
    
    _timeoutTimer = Timer(timeout, () {
      // Save state before timeout
      saveWorkoutState();
      // Show timeout message with recovery option
      showTimeoutDialog();
    });
  }
}
```

**Consistent Navigation:**
```yaml
Navigation Consistency:
  - Always same structure
  - Tab bar always visible
  - Back button always top-left
  - Primary action always bottom-right
  - Settings always same location
  
Predictable Interactions:
  - Buttons always do what label says
  - Swipe directions consistent
  - Confirmation pattern consistent
  - Error message location consistent
```

**Implementation Checklist:**
- [ ] Reduced motion option
- [ ] Focus/distraction-free mode
- [ ] Clear progress indicators
- [ ] Ample time for interactions (30+ sec)
- [ ] Timeout warnings before session expires
- [ ] Consistent navigation patterns
- [ ] State saved automatically (no data loss)
- [ ] Clear instructions at each step

---

## 3. Platform-Specific Implementation

### 3.1 iOS Accessibility Features

#### VoiceOver Support

**Semantic Properties:**
```swift
// UIKit
button.accessibilityLabel = "Start workout"
button.accessibilityHint = "Begins your scheduled workout for today"
button.accessibilityTraits = .button

// Flutter
Semantics(
  label: 'Start workout',
  hint: 'Begins your scheduled workout for today',
  button: true,
  enabled: true,
  child: ElevatedButton(
    onPressed: startWorkout,
    child: Text('Start'),
  ),
)
```

**Accessibility Actions:**
```dart
// Custom actions for VoiceOver rotor
Semantics(
  label: 'Bench Press, 100 kilograms, 4 sets of 8 reps',
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Edit weight'): () {
      showWeightEditor();
    },
    CustomSemanticsAction(label: 'View history'): () {
      showExerciseHistory();
    },
    CustomSemanticsAction(label: 'Remove exercise'): () {
      removeExercise();
    },
  },
  child: ExerciseCard(exercise: benchPress),
)
```

**Reading Order:**
```dart
// Control reading order with sortKey
Semantics(
  sortKey: OrdinalSortKey(1.0),
  label: 'Exercise name: Squat',
  child: Text('Squat'),
)

Semantics(
  sortKey: OrdinalSortKey(2.0),
  label: 'Weight: 100 kilograms',
  child: Text('100 kg'),
)
```

#### Dynamic Type

**Text Scaling:**
```dart
// Respect user's text size preferences
Text(
  'Workout name',
  style: Theme.of(context).textTheme.bodyMedium,
  // Automatically scales with accessibility settings
)

// For special cases, allow scaling
Text(
  'Title',
  textScaleFactor: MediaQuery.textScaleFactorOf(context),
  maxLines: null,  // Allow text to expand
)
```

#### Voice Control

**Voice Control Labels:**
```dart
// Provide explicit labels for voice commands
IconButton(
  icon: Icon(Icons.play_arrow),
  tooltip: 'Play',  // Voice Control uses this
  onPressed: play,
)

// For complex layouts, use Semantics
Semantics(
  label: 'Start timer',  // User says: "Tap start timer"
  button: true,
  child: CustomPlayButton(),
)
```

### 3.2 Android Accessibility Features

#### TalkBack Support

**Content Descriptions:**
```dart
// Flutter Semantics work on Android TalkBack
Semantics(
  label: 'Add exercise',
  hint: 'Opens exercise library',
  button: true,
  child: FloatingActionButton(
    onPressed: openExerciseLibrary,
    child: Icon(Icons.add),
  ),
)
```

**Live Regions:**
```dart
// Announce dynamic content changes
Semantics(
  liveRegion: true,  // TalkBack announces changes
  label: 'Timer: $remainingSeconds seconds',
  child: Text('$remainingSeconds'),
)
```

#### Switch Access

**Focus Order:**
```dart
// Ensure logical focus traversal
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: NumericFocusOrder(1.0),
        child: TextField(controller: nameController),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(2.0),
        child: TextField(controller: weightController),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(3.0),
        child: ElevatedButton(
          onPressed: save,
          child: Text('Save'),
        ),
      ),
    ],
  ),
)
```

#### Voice Access

**Numbered Labels:**
```dart
// Voice Access automatically numbers clickable elements
// Ensure all interactive elements have labels
ElevatedButton(
  onPressed: submit,
  child: Text('Submit'),  // Voice Access: "Tap Submit" or "Tap 5"
)
```

### 3.3 Cross-Platform Testing

**Accessibility Scanner Tools:**
```yaml
iOS Tools:
  - Accessibility Inspector (Xcode)
  - VoiceOver (iOS Settings)
  - Voice Control (iOS Settings)
  - Color Contrast Analyzer
  
Android Tools:
  - Accessibility Scanner (Play Store)
  - TalkBack (Android Settings)
  - Switch Access (Android Settings)
  - Android Studio Layout Inspector
  
Cross-Platform:
  - Flutter Semantics Debugger
  - Contrast Checker (WebAIM)
  - WAVE accessibility testing
```

**Automated Testing:**
```dart
// Flutter accessibility tests
testWidgets('Button has semantic label', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Find button by semantic label
  final semantics = tester.getSemantics(find.byType(ElevatedButton));
  expect(semantics.label, equals('Start workout'));
  expect(semantics.hasAction(SemanticsAction.tap), isTrue);
});

testWidgets('Meets minimum touch target size', (tester) async {
  await tester.pumpWidget(MyButton());
  
  final size = tester.getSize(find.byType(MyButton));
  expect(size.width, greaterThanOrEqualTo(44.0));
  expect(size.height, greaterThanOrEqualTo(44.0));
});

testWidgets('Meets contrast ratio requirements', (tester) async {
  // Test color contrast
  final textColor = await tester.getTextColor();
  final backgroundColor = await tester.getBackgroundColor();
  final ratio = calculateContrastRatio(textColor, backgroundColor);
  
  expect(ratio, greaterThanOrEqualTo(4.5));
});
```

---

## 4. Testing & Validation

### 4.1 Manual Testing Procedures

**VoiceOver Testing (iOS):**
```yaml
Test Plan:
  Setup:
    1. Enable VoiceOver: Settings → Accessibility → VoiceOver
    2. Practice VoiceOver gestures
    3. Familiarize with rotor (two-finger twist)
  
  Navigation Tests:
    - Swipe through all screens
    - Verify reading order is logical
    - Check all elements are announced
    - Test custom actions in rotor
    - Verify form input flow
  
  Content Tests:
    - Images have alt text
    - Buttons have clear labels
    - Status messages announced
    - Charts have text alternatives
    - Timer updates announced
  
  Interaction Tests:
    - Double tap activates buttons
    - Three-finger swipe scrolls pages
    - Rotor provides heading navigation
    - Text input with virtual keyboard
    - Adjustable values (sliders, steppers)
```

**TalkBack Testing (Android):**
```yaml
Test Plan:
  Setup:
    1. Enable TalkBack: Settings → Accessibility → TalkBack
    2. Complete tutorial
    3. Learn local context menu (swipe up then right)
  
  Navigation Tests:
    - Swipe through all screens
    - Verify reading order
    - Test local context menu actions
    - Verify focus indicators
  
  Interaction Tests:
    - Double tap to activate
    - Explore by touch
    - Reading controls (adjust verbosity)
    - Text entry with keyboard
```

**Keyboard Navigation Testing:**
```yaml
Desktop/iPad Keyboard Testing:
  Connection: External keyboard or iPad keyboard
  
  Tests:
    - Tab key moves focus forward
    - Shift+Tab moves focus backward
    - Enter/Space activates focused element
    - Arrow keys navigate within component
    - Escape dismisses modals/dialogs
    - No keyboard traps
    - Focus visible at all times
    
  Focus Order:
    - Logical (reading order)
    - Doesn't skip interactive elements
    - Doesn't focus non-interactive elements
```

**Switch Control Testing:**
```yaml
Setup:
  - iOS: Settings → Accessibility → Switch Control
  - Connect switch (or use screen tap as switch)
  
Tests:
  - Single-switch scanning works
  - All elements reachable
  - Grouped elements efficient
  - No auto-advancing without warning
  - Pause/resume available
```

### 4.2 Automated Testing

**CI/CD Integration:**
```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  a11y-tests:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        
      - name: Run accessibility tests
        run: flutter test --tags=accessibility
        
      - name: Check semantic labels
        run: flutter analyze --check-semantics
        
      - name: Contrast ratio tests
        run: flutter test test/accessibility/contrast_test.dart
        
      - name: Touch target size tests
        run: flutter test test/accessibility/touch_targets_test.dart
        
      - name: Screen reader announcement tests
        run: flutter test test/accessibility/announcements_test.dart
```

**Test Examples:**
```dart
// test/accessibility/contrast_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Color Contrast Tests', () {
    test('Primary button meets AA contrast ratio', () {
      final buttonColor = Color(0xFF1976D2);
      final textColor = Colors.white;
      final ratio = calculateContrastRatio(buttonColor, textColor);
      
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Button text must meet WCAG AA contrast ratio');
    });
    
    test('All theme colors meet contrast requirements', () {
      final theme = AppTheme.lightTheme;
      
      // Test each color combination
      testContrast(theme.primaryColor, theme.onPrimary, 4.5);
      testContrast(theme.backgroundColor, theme.onBackground, 4.5);
      testContrast(theme.surfaceColor, theme.onSurface, 4.5);
    });
  });
}

// test/accessibility/touch_targets_test.dart
void main() {
  testWidgets('All buttons meet minimum size', (tester) async {
    await tester.pumpWidget(MaterialApp(home: WorkoutScreen()));
    
    // Find all buttons
    final buttons = find.byType(ElevatedButton);
    
    for (int i = 0; i < buttons.evaluate().length; i++) {
      final size = tester.getSize(buttons.at(i));
      
      expect(size.width, greaterThanOrEqualTo(44.0),
        reason: 'Button width must be at least 44pt');
      expect(size.height, greaterThanOrEqualTo(44.0),
        reason: 'Button height must be at least 44pt');
    }
  });
}

// test/accessibility/semantics_test.dart
void main() {
  testWidgets('Exercise card has proper semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseCard(
            exercise: Exercise(name: 'Squat', sets: 4, reps: 8, weight: 100),
          ),
        ),
      ),
    );
    
    // Get semantics
    final semantics = tester.getSemantics(find.byType(ExerciseCard));
    
    // Verify label
    expect(semantics.label, contains('Squat'));
    expect(semantics.label, contains('4 sets'));
    expect(semantics.label, contains('8 reps'));
    expect(semantics.label, contains('100'));
    
    // Verify actions
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    
    // Verify not focusable if disabled
    if (!exercise.enabled) {
      expect(semantics.hasFlag(SemanticsFlag.isFocusable), isFalse);
    }
  });
}
```

### 4.3 User Testing with PWD

**Recruitment:**
```yaml
Test Participants:
  Blind Users (2-3):
    - Daily screen reader users
    - iOS and Android representation
    - Fitness experience varied
  
  Low Vision Users (2-3):
    - Use magnification/high contrast
    - One colorblind user
  
  Motor Impairment Users (2-3):
    - Limited dexterity
    - Use voice control or switch access
    - One uses mobility aid
  
  Deaf/Hard of Hearing Users (1-2):
    - Rely on visual feedback
    - Caption users
  
  Cognitive Disability (1-2):
    - Dyslexia or ADHD
    - Memory or attention challenges
```

**Test Scenarios:**
```yaml
Scenario 1: First Launch
  - Download and open app
  - Create account
  - Complete onboarding
  - Set fitness goal
  
Scenario 2: Start Workout
  - Navigate to workouts
  - Select a program
  - Start first workout
  - Complete one exercise
  - Log sets and reps
  
Scenario 3: Track Nutrition
  - Navigate to nutrition
  - Log a meal
  - Search food database
  - View calorie summary
  
Scenario 4: View Progress
  - Navigate to progress
  - Interpret charts
  - Understand trends
  - Export data
  
Scenario 5: Adjust Settings
  - Find settings
  - Change preferences
  - Adjust accessibility options
  - Save changes
```

**Success Metrics:**
```yaml
Quantitative:
  - Task completion rate: >95%
  - Time on task: Within 2x of non-disabled users
  - Errors per task: <2
  - Accessibility violation count: 0 critical, <5 minor
  
Qualitative:
  - Satisfaction (1-5 scale): >4.0 average
  - Perceived ease of use (SUS score): >70
  - Would recommend: >80%
  - Verbatim feedback themes
```

---

## 5. Checklist de Conformité

### 5.1 Checklist WCAG 2.1 Niveau AA

#### Perceptible

**1.1 Alternatives Textuelles**
- [ ] Toutes les images ont un texte alternatif (1.1.1 Niveau A)
- [ ] Les images décoratives sont exclues de l'arborescence d'accessibilité
- [ ] Les graphiques ont des descriptions textuelles
- [ ] Les icônes ont des libellés (labels ou aria-labels)

**1.2 Médias temporels**
- [ ] Les vidéos sont sous-titrées (1.2.2 Niveau A)
- [ ] Audiodescription fournie pour la vidéo (1.2.5 Niveau AA)
- [ ] Sous-titres en direct pour la vidéo en direct (1.2.4 Niveau AA)

**1.3 Adaptable**
- [ ] L'information n'est pas perdue lorsqu'elle est présentée différemment (1.3.1 Niveau A)
- [ ] L'ordre de lecture est logique (1.3.2 Niveau A)
- [ ] Les instructions ne reposent pas sur des caractéristiques sensorielles (1.3.3 Niveau A)
- [ ] Le contenu se place au format 320px de large (1.3.4 Niveau AA)
- [ ] La finalité des champs de saisie est identifiée (1.3.5 Niveau AA)

**1.4 Discernable**
- [ ] La couleur n'est pas le seul moyen de transmettre de l'information (1.4.1 Niveau A)
- [ ] Un contrôle audio est disponible (1.4.2 Niveau A)
- [ ] Le contraste du texte est d'au moins 4.5:1 (1.4.3 Niveau AA)
- [ ] Le texte est redimensionnable à 200% (1.4.4 Niveau AA)
- [ ] Pas d'images de texte (1.4.5 Niveau AA)
- [ ] Le redimensionnement du contenu fonctionne (1.4.10 Niveau AA)
- [ ] Contraste non-textuel à 3:1 (1.4.11 Niveau AA)
- [ ] Espacement du texte ajustable (1.4.12 Niveau AA)
- [ ] Le contenu au survol/au focus peut être rejeté (1.4.13 Niveau AA)

#### Utilisable

**2.1 Accessible au Clavier**
- [ ] Toute fonctionnalité accessible via un clavier (2.1.1 Niveau A)
- [ ] Pas de blocage au clavier (2.1.2 Niveau A)
- [ ] Raccourcis avec touches de caractères (2.1.4 Niveau A)

**2.2 Délai Suffisant**
- [ ] Les limites de temps sont ajustables (2.2.1 Niveau A)
- [ ] Pause, arrêt, masquer pour les contenus en mouvement (2.2.2 Niveau A)
- [ ] Le temps n'est pas essentiel (2.2.3 Niveau AAA - optionnel)

**2.3 Crises**
- [ ] Pas de clignotement plus de 3 fois par seconde (2.3.1 Niveau A)

**2.4 Navigable**
- [ ] Liens d'évitement (skip nav) (2.4.1 Niveau A)
- [ ] Les pages ont un titre (2.4.2 Niveau A)
- [ ] L'ordre de focus est logique (2.4.3 Niveau A)
- [ ] La fonction du lien est claire (2.4.4 Niveau A)
- [ ] Multiples façons de naviguer (2.4.5 Niveau AA)
- [ ] En-têtes et étiquettes descriptifs (2.4.6 Niveau AA)
- [ ] Focus visible (2.4.7 Niveau AA)

**2.5 Modalités de Saisie**
- [ ] Les gestes ont des alternatives (2.5.1 Niveau A)
- [ ] Annulation du pointeur (2.5.2 Niveau A)
- [ ] Nom dans l'étiquette visible (2.5.3 Niveau A)
- [ ] Actionnement par le mouvement (2.5.4 Niveau A)
- [ ] Cibles tactiles de 44x44pt minimum (2.5.5 Niveau AAA - objectif visé)

#### Compréhensible

**3.1 Lisible**
- [ ] Langue de la page identifiée (3.1.1 Niveau A)
- [ ] Langue de base et des passages/articles identifiée (3.1.2 Niveau AA)

**3.2 Prévisible**
- [ ] Lors du focus, ne provoque pas de changement de contexte (3.2.1 Niveau A)
- [ ] Lors de la saisie, ne provoque pas de changement inattendu (3.2.2 Niveau A)
- [ ] Navigation cohérente (3.2.3 Niveau AA)
- [ ] Identification cohérente (3.2.4 Niveau AA)

**3.3 Assistance à la Saisie**
- [ ] Identification des erreurs (3.3.1 Niveau A)
- [ ] Étiquettes ou instructions fournies (3.3.2 Niveau A)
- [ ] Suggestions pour l'erreur fournies (3.3.3 Niveau AA)
- [ ] Prévention des erreurs (médicales/financières) (3.3.4 Niveau AA)

#### Robuste

**4.1 Compatible**
- [ ] Décodage valide/Parsing (4.1.1 Niveau A)
- [ ] Nom, Rôle, Valeur déterminable par programmation (4.1.2 Niveau A)
- [ ] Messages de statut lisibles (4.1.3 Niveau AA)

### 5.2 Conformité RGAA 4.1 (Si ciblée)

```yaml
Étapes de conformité RGAA:
  1. Mapper les critères WCAG sur les 106 critères RGAA
  2. Effectuer les 258 tests spécifiques RGAA
  3. Documenter les résultats dans une déclaration de conformité
  4. Viser les 100% de conformité (ou expliquer la non-conformité)
  5. Publier la déclaration d'accessibilité
  6. Mettre à jour annuellement

Processus d'audit RGAA:
  - Audit interne d'abord
  - Audit externe par un expert (recommandé)
  - Demande du label RGAA (optionnel)
  - Publication des résultats
```

---

## 6. Feuille de Route d'Implémentation

### 6.1 Phase 1 : Fondations (MVP)

**Priorité : Critique**

```yaml
Semaines 1-2: Accessibilité cœur
  - [ ] Labels sémantiques pour tous les éléments interactifs
  - [ ] Support basique VoiceOver/TalkBack
  - [ ] Cibles tactiles minimales (44x44pt)
  - [ ] Contraste couleur 4.5:1 ratio respecté
  - [ ] Navigation clavier (si pertinent)
  
Semaines 3-4: Accessibilité visuelle
  - [ ] Typographie dynamique supportée
  - [ ] Mode fort contraste détecté
  - [ ] Indicateurs de focus visibles
  - [ ] Plus aucune info basée uniquement sur la couleur
  
Semaines 5-6: Test
  - [ ] Tests manuels VoiceOver
  - [ ] Tests manuels TalkBack
  - [ ] Tests auto de contrastes
  - [ ] Test des tailles de cibles tactiles
  
Livrable: Conformité WCAG Niveau A (Produit minimalement utilisable)
```

### 6.2 Phase 2 : Renforcements (v1.0)

**Priorité : Haute**

```yaml
Semaines 7-10: Support Lecteur d'écran avancé
  - [ ] Actions sémantiques personnalisées
  - [ ] Les "Live Regions" pour les contenus dynamiques
  - [ ] Ordre de navigation amélioré
  - [ ] Hints/Astuces d'accessibilité
  
Semaines 11-12: Accessibilité Motrice
  - [ ] Support du Contrôle Vocal
  - [ ] Optimisation de la fonctionnalité de contacteur (Switch Control)
  - [ ] Gestes alternatifs
  - [ ] Dialogues de confirmation sur actions irréversibles
  
Semaines 13-14: Accessibilité cognitive
  - [ ] Langage clair & simple revu
  - [ ] Patterns d'UI consistants
  - [ ] Indicateurs de progrès clarifiés
  - [ ] Option de réduction des animations
  
Semaines 15-16: Test & Itérations
  - [ ] Tests utilisateurs avec des PSH (5-8 participants)
  - [ ] Audit d'accessibilité externe
  - [ ] Résolutions de bugs
  
Livrable: Conformité WCAG Niveau AA (Standard de l'industrie)
```

### 6.3 Phase 3 : Excellence (v2.0+)

**Priorité : Moyenne**

```yaml
Continu: Fonctionnalités AAA
  - [ ] Ratio de fort contraste (7:1)
  - [ ] Audiodescription étendue des vidéos
  - [ ] Aide contextuelle
  - [ ] Apprentissage simplifié (niveau 6ème)
  
Continu: Fonctionnalités avancées
  - [ ] UX/UI Configurable (font, espacement, couleurs)
  - [ ] Profils d'accessibilité personnalisés
  - [ ] Plage braille
  - [ ] Vidéos langages des signes
  
Continu: Conformité
  - [ ] Validité RGAA 4.1 totale (Axe France)
  - [ ] Validation EN 301 549
  - [ ] Publication de la déclaration
  - [ ] Audit annuel et mise à jour
  
Livrable: L'excellence de l'accessibilité comme avantage compétitif
```

---

## 7. Déclaration d'Accessibilité

**Brouillon de la Déclaration d'Accessibilité - LiftUp:**

```markdown
# Déclaration d'Accessibilité pour LiftUp

Dernière mise à jour : 10 Février 2026

## Notre Engagement

LiftUp s'engage à garantir l'accessibilité numérique pour les personnes en situation de handicap. 
Nous améliorons continuellement l'expérience utilisateur pour tous et appliquons 
les normes d'accessibilité pertinentes.

## Statut de Conformité

Les Règles pour l'Accessibilité des Contenus Web (WCAG) définissent les exigences pour améliorer 
l'accessibilité pour les personnes touchées par le handicap. Notre objectif est de nous conformer aux WCAG 2.1, Niveau AA.

**Statut Actuel :** [En développement / Partiellement conforme / Totalement conforme]

- Conforme : Le contenu répond totalement au standard d'accessibilité
- Partiellement conforme : Certaines parties du contenu ne répondent pas totalement au standard
- Non-conforme : Le contenu ne répond pas au standard

## Fonctionnalités d'Accessibilité

LiftUp inclut les fonctionnalités d'accessibilité suivantes :

- **Support du Lecteur d'Écran** : Compatibilité totale iOS VoiceOver et Android TalkBack.
- **Typographie Dynamique** : Le texte s'adapte aux préférences système de taille de police.
- **Contraste Élevé** : Supporte le mode de contraste élevé.
- **Contrôle Vocal** : Toutes les fonctionnalités sont accessibles via Commandes Vocales.
- **Navigation Clavier** : Support complet du clavier (ex. iPad avec clavier Bluetooth).
- **Couleur** : L'information n'est pas uniquement transmise par la couleur.
- **Sous-titres** : Toutes les vidéos incluent des sous-titres (close-captions).
- **Cible Tactile** : Taille de zone tactile minimum fixée à 44x44pt.
- **Animations Réduites** : L'application respecte la configuration de mouvement réduit.

## Retours

Nous sommes ouverts à vos commentaires sur l'accessibilité de LiftUp. Merci de nous contacter à :

- **Email** : accessibility@liftup.app
- **Temps de réponse** : Sous de 5 jours ouvrés.

Nous travaillerons de concert pour fournir l'information sous un format accessible.

## Spécifications Techniques

L'accessibilité de LiftUp repose sur la technologie suivante :

- API Accessibilité iOS (UIAccessibility)
- API Accessibilité Android (AccessibilityService)
- Framework Sémantique Flutter

## Méthode d'Évaluation

LiftUp a été audité via :

- Auto-évaluation : Tests en interne par l'équipe de dev.
- Évaluation utilisateur :  avec les technologies d'assistance.
- Tests automatisés : Framework d'analyse, Checkeurs de contraste.
- Audit externe : [En attente / Complété par XXX le DATE]

## Problèmes Connus

Nous sommes au fait des problèmes d'accessibilité suivants :

[Lister tout aspect connu avec son alternative]

## Date

Cette déclaration a été créée le 10 Février 2026.

---

Davantage d'informations sur l'accessibilité :
- [Web Accessibility Initiative (WAI)](https://www.w3.org/WAI/)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
```

---

## 8. Resources & Tools

### 8.1 Standards & Guidelines

**Primary Standards:**
- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/) - W3C Quick Reference
- [WCAG 2.2](https://www.w3.org/WAI/WCAG22/Understanding/) - Understanding WCAG 2.2
- [RGAA 4.1](https://www.numerique.gouv.fr/publications/rgaa-accessibilite/) - French standard
- [EN 301 549](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/03.02.01_60/en_301549v030201p.pdf) - European standard
- [Section 508](https://www.section508.gov/) - US federal standard

**Mobile Guidelines:**
- [iOS Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Android Accessibility Principles](https://developer.android.com/guide/topics/ui/accessibility/principles)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)

### 8.2 Testing Tools

**Automated Testing:**
```yaml
Flutter/Dart:
  - flutter analyze --check-semantics
  - Flutter Semantics Debugger
  - Golden tests for UI consistency

iOS:
  - Accessibility Inspector (Xcode)
  - Simulator Accessibility Features
  - XCTest UI Testing

Android:
  - Accessibility Scanner (app)
  - Android Studio Layout Inspector
  - Espresso accessibility checks

Cross-Platform:
  - Contrast Checker (WebAIM)
  - Color Oracle (color blindness simulator)
  - Sim Daltonism (color blindness simulator)
  - WAVE (if web components)
```

**Manual Testing:**
```yaml
Screen Readers:
  - VoiceOver (iOS): Settings → Accessibility
  - TalkBack (Android): Settings → Accessibility
  - NVDA (Windows - for web): Free download
  - JAWS (Windows - for web): Commercial

Voice Control:
  - Voice Control (iOS): Settings → Accessibility
  - Voice Access (Android): Play Store app
  - Dragon NaturallySpeaking (Windows): Commercial

Switch Control:
  - Switch Control (iOS): Settings → Accessibility
  - Switch Access (Android): Settings → Accessibility
```

### 8.3 Learning Resources

**Courses & Certifications:**
- [W3C Introduction to Web Accessibility](https://www.edx.org/course/web-accessibility-introduction) - Free
- [Deque University](https://dequeuniversity.com/) - Paid courses
- [Google Accessibility Course](https://www.udacity.com/course/mobile-accessibility--ud839) - Free
- [A11ycasts by Google](https://www.youtube.com/playlist?list=PLNYkxOF6rcICWx0C9LVWWVqvHlYJyqw7g) - Free videos

**Communities:**
- [A11y Slack](https://web-a11y.slack.com/) - Community discussion
- [WebAIM Forum](https://webaim.org/discussion/) - Q&A
- [Stack Overflow [accessibility]](https://stackoverflow.com/questions/tagged/accessibility) - Technical Q&A

---

## 9. Conclusion

Accessibility is not an add-on feature—it's a fundamental requirement for an inclusive fitness app. By following WCAG 2.1 Level AA standards and implementing the strategies outlined in this document, LiftUp will be usable by the widest possible audience, including people with disabilities.

**Key Success Factors:**

1. **Build accessibility in from the start** - Retrofitting is more expensive
2. **Test with real users** - Automated tests catch only 30% of issues
3. **Continuous improvement** - Accessibility is ongoing, not one-time
4. **Team education** - Everyone must understand accessibility principles
5. **User empathy** - Experience the app as users with disabilities would

**Business Benefits:**

- **Larger market**: 15% of population has disabilities
- **Competitive advantage**: Many fitness apps fail accessibility
- **Legal compliance**: Avoid lawsuits and meet regulations
- **Brand reputation**: Demonstrate social responsibility
- **Better UX for all**: Accessible design benefits everyone

**Next Steps:**

1. Review and approve this strategy
2. Integrate accessibility into sprint planning
3. Assign accessibility champion/lead
4. Begin Phase 1 implementation
5. Schedule user testing with PWD
6. Conduct external accessibility audit
7. Publish accessibility statement

---

**Document Control:**
- **Next Review Date:** March 10, 2026
- **Owner:** Product & Engineering Teams
- **Approvers:** CTO, Product Manager, UX Lead
- **Distribution:** All team members, accessibility consultants

---

*Accessibility is about removing barriers and creating opportunities. Let's build a LiftUp that truly lifts everyone up.*
