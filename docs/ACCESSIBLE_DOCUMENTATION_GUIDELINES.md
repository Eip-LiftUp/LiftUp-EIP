# Guide de Rédaction et d'Accessibilité de la Documentation

Ce document définit les standards obligatoires pour la rédaction de l'ensemble des documents techniques, spécifications et livrables du projet **LiftUp**. 

Afin de garantir que notre dossier candidat et nos livrables respectent les normes d'accessibilité numériques (RGAA, WCAG) et les critères d'évaluation **[C2] et [C3]**, tout contributeur au projet doit appliquer rigoureusement les règles de conception technique suivantes.

---

## 1. Structure Sémantique Stricte

Pour faciliter la navigation des personnes malvoyantes ou non-voyantes utilisant des lecteurs d'écran (VoiceOver, NVDA, JAWS), la documentation doit suivre une structure sémantique logique et prévisible.

**Règles à appliquer :**
*   **Hiérarchie stricte :** Utilisez les niveaux de titres dans l'ordre (`H1` suivi de `H2`, puis `H3`). Ne sautez jamais de niveau de titre (par exemple, ne passez pas d'un `H1` directement à un `H3`).
*   **Titre principal unique :** Chaque document ne doit contenir qu'un seul titre de niveau 1 (`# Titre` en Markdown), correspondant au nom du document.
*   **Balises sémantiques :** Utilisez les listes à puces (`-` ou `*`) et les listes numérotées (`1. 2.`) intégrées au langage Markdown ou au traitement de texte, plutôt que de créer de fausses listes manuellement.

**Exemple Markdown correct :**
```markdown
# Spécifications Techniques (H1)
## Architecture Backend (H2)
### Choix de la Base de données (H3)
```

---

## 2. Alternatives Textuelles pour les Médias et Schémas

Les schémas d'architecture, les diagrammes d'infrastructure Cloud et les maquettes UI/UX contiennent des informations techniques critiques qui doivent être transmises aux personnes ne pouvant pas voir ces images.

**Règles à appliquer :**
*   **Attribut `alt` systématique :** Toute image intégrée doit posséder un texte alternatif clair.
*   **Descriptions détaillées :** Pour les schémas complexes (diagrammes de flux, UML, infrastructures Cloud), l'attribut `alt` ne suffit pas. L'image doit être suivie d'un bloc de texte ou d'un tableau expliquant clairement le contenu de l'image.

**Exemple d'intégration :**
```markdown
![Schéma d'architecture Cloud AWS montrant le flux de données entre l'API Gateway, le serveur Rust et la base de données PostgreSQL](./assets/cloud_architecture.png)

**Description détaillée de l'architecture :**
Le flux utilisateur traverse d'abord l'API Gateway, qui route la requête vers nos conteneurs de serveurs Rust (ECS). Les données sont ensuite stockées et récupérées depuis une instance PostgreSQL managée...
```

---

## 3. Contraste et Utilisation de la Couleur

Les informations techniques (statuts, réussites, échecs, flux) ne doivent exclure ni les personnes malvoyantes, ni les personnes daltoniennes.

**Règles à appliquer :**
*   **Ratio de contraste minimum :** Assurez-vous que le texte des documents et les textes figurant dans vos schémas atteignent un ratio de contraste de **4.5:1** pour un texte normal, et **3:1** pour un texte en grand format (standards WCAG AA).
*   **Indépendance de la couleur :** Ne transmettez *jamais* une information technique uniquement par un code couleur. 

**Mauvaise pratique :**
> L'état du serveur backend en rouge indique une panne, en vert il est opérationnel.

**Bonne pratique :**
> L'état du serveur backend est indiqué par une icône avec un label textuel : ❌ (Erreur / Rouge) pour une panne, et ✅ (Opérationnel / Vert) quand il fonctionne. Le texte "Statut: En ligne" complète l'indicateur.

---

## 4. Format d'Export des Livrables Finaux (PDF/UA)

Le choix du format d'export est crucial pour que les métadonnées d'accessibilité (créées lors de l'application des règles 1, 2 et 3) ne soient pas détruites lors de la génération du livrable final.

**Règles à appliquer :**
*   **Balisage au moment de l'export :** Lors de la génération des documents finaux à livrer au jury ou aux partenaires, exportez obligatoirement dans un format balisé, comme la norme **PDF/UA** (Universal Accessibility).
*   **Conservation des métadonnées :** Ce format garantit que les lecteurs d'écran pourront analyser la structure `H1, H2, H3`, lire les attributs `alt` des images, et parcourir correctement les tableaux de données.
*   **Outils d'édition :** Si vous utilisez Word, Google Docs ou un outil comme Pandoc / Asciidoctor pour convertir ce Markdown en PDF, veillez à cocher l'option "Créer un PDF accessible (balisé)" ou "Tags for Accessibility" lors de l'exportation.

---

## 5. Checklist Avant Publication

Avant toute validation d'un nouveau document technique, vérifiez ces 4 points :
- [ ] La structure des titres ne saute aucun niveau (H1 -> H2 -> H3).
- [ ] Tous les diagrammes d'architecture, de bases de données et les maquettes possèdent une description textuelle complète.
- [ ] Aucun concept n'est expliqué *exclusivement* par une couleur de police ou de fond (ajout d'icônes ou de mots explicites).
- [ ] Le document finalisé est généré sous forme de PDF balisé (PDF/UA) ou dans un HTML sémantiquement pur.
