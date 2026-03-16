# LIFTUP - BETA TEST PLAN

### Context
LiftUp atteint le stade de la bêta. Après avoir pivoté vers une architecture 100% en ligne, cette version démontre la stabilité de notre infrastructure cloud (Rust/DigitalOcean) et la valeur de notre algorithme de coaching (Python). L'objectif de cette bêta est de prouver que l'application peut générer un programme cohérent, permettre à l'utilisateur de tracker sa séance sans latence, et synchroniser ses données de manière fiable.

### User Roles
| Rôle | Description |
|------|-------------|
| **Athlete (User)** | Pratiquant de musculation qui utilise l'application pour générer ses programmes et tracker ses performances en salle. |
| **Admin** | Membre de l'équipe (DevOps) ayant accès aux dashboards Grafana/PostHog pour surveiller la santé des serveurs et de la base de données. |

### Feature Table (Beta Scope)
| ID | User Role | Feature Name | Short Description |
|---|---|---|---|
| **F1** | Athlete | **Create** a profile | L'utilisateur s'inscrit et renseigne ses données physiques de base. |
| **F2** | Athlete | **Generate** a workout | L'utilisateur demande un programme ; le backend Rust interroge le service ML Python. |
| **F3** | Athlete | **Log** a workout session | Saisie des exercices, poids et répétitions, avec sauvegarde cloud en temps réel. |
| **F4** | Admin | **Monitor** API Health | Vérification de la disponibilité du backend Rust et des temps de réponse via le dashboard. |

### Success Criteria Table
| Feature ID | Key Success Criteria | Indicator / Metric | Result Achieved |
|---|---|---|---|
| **F1** | Un utilisateur peut créer un compte et ses données sont sauvegardées en base de données. | 10 tentatives de création, 0 échec. | *[À remplir après test]* |
| **F2** | L'IA génère un programme d'entraînement personnalisé cohérent sans timeout. | Temps de réponse de l'API < 3 secondes. | *[À remplir après test]* |
| **F3** | Une séance complète est trackée et synchronisée sur le cloud sans perte de données. | 100% des séries entrées sur Flutter sont retrouvées sur le DB PostgreSQL. | *[À remplir après test]* |
| **F4** | Les requêtes mobiles sont correctement traitées par le pipeline CI/CD et l'infrastructure. | Uptime de 99% sur la durée de la session de test. | *[À remplir après test]* |
