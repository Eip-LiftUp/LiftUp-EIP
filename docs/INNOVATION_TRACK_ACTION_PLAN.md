# LIFTUP - INNOVATION TRACK: ACTION PLAN

## 1. Context
LiftUp est une application mobile intelligente de coaching en musculation. Le problème actuel est que la plupart des applications fitness génériques ne s'adaptent pas à la progression réelle des athlètes et bodybuilders. Notre solution est un coach IA 100% en ligne qui génère des programmes d'entraînement dynamiques, suit les performances détaillées et offre des recommandations personnalisées. Le projet cible les pratiquants de musculation réguliers cherchant à optimiser leur progression sans payer un coach physique.

## 2. Technical Specifications
**Technological Stack:**
- **Frontend :** Flutter (iOS & Android) avec interface sombre (cyan/orange).
- **Backend :** Rust (API haute performance, 100% cloud).
- **Machine Learning :** Python (Génération dynamique des programmes).
- **Infrastructure & CI/CD :** Hébergement cloud (Digital Ocean / Render), PostgreSQL, et pipelines automatisés via GitHub Actions.

**User Stories (Core Scope) :**
- *En tant qu'utilisateur*, je peux créer un profil avec mes mensurations et mes objectifs pour que l'IA comprenne mon niveau.
- *En tant qu'utilisateur*, je peux générer un programme d'entraînement personnalisé (géré par le microservice Python via l'API Rust).
- *En tant qu'utilisateur*, je peux tracker mes séries, répétitions et poids en temps réel pendant ma séance avec une sauvegarde cloud instantanée.
- *En tant qu'utilisateur*, je peux visualiser mes métriques de progression sur un dashboard dédié.

**Milestones Tech4 :**
1. **M1 - Core Cloud Infrastructure :** Déploiement du backend Rust, base de données PostgreSQL et CI/CD complète sur GitHub Actions.
2. **M2 - IA & Tracking (Alpha) :** Intégration du moteur ML Python au backend et développement de l'UI Flutter pour le tracking de séance.
3. **M3 - Beta Release :** Sortie de la V1 100% online auprès de nos "early adopters" pour tester la charge serveur et la pertinence de l'IA.
4. **M4 - UI/UX Refinement :** Itération sur le design (inspiré d'applications comme Hevy) suite aux retours utilisateurs.

## 3. Non-Technical Specifications (Solution Track)

### Solution - Mandatory
1. **Develop and retain a user community :** 
   - Création d'un serveur Discord dédié aux passionnés de musculation.
   - Objectif : Recruter et activer au moins 20 bêta-testeurs parmi les early adopters identifiés.
   - Mise en place d'un programme d'accès anticipé (VIP) pour les membres les plus actifs.
2. **Work on user experience (UX/UI) :**
   - Création de prototypes sur Figma basés sur nos recherches (design sombre, éléments cyan/orange).
   - Conduite de 5 tests utilisateurs minimum lors des séances de sport pour identifier les frictions de l'UI (ex: temps de saisie des poids pendant le temps de repos).

### Solution - Optional (Choisis 2 sur 4)
1. **Increase visibility and impact on social networks :**
   - Création de contenu sur Instagram et TikTok (vidéos courtes montrant la différence entre un programme générique et le programme IA dynamique de LiftUp).
   - Stratégie d'acquisition de testeurs via ces réseaux.
2. **Optimize relationships with the target audience :**
   - Mise en place de boucles de feedback structurées sur Discord pour ajuster la pertinence du modèle ML Python selon le ressenti des athlètes.
