# Politique de Gestion de Version (Git Workflow & Standards)

Ce document définit les standards de contribution, la stratégie de branching et les conventions de commit pour le projet LiftUp. L'objectif est de maintenir un historique propre, lisible et cohérent pour faciliter la collaboration et la maintenance.

---

## 1. Stratégie de Branching

Nous utilisons une variation simplifiée du **Gitflow**.

### Branches Principales
| Branche   | Description | Protection |
|-----------|-------------|------------|
| `main`    | Contient le code de production stable. Ne doit jamais être cassée. Tout commit ici est une release potentielle. | **Protégée** (PR requise) |
| `develop` | Branche d'intégration principale. C'est la base pour les nouvelles fonctionnalités. | **Protégée** (PR requise) |

### Branches Temporaires
| Type | Préfixe | Description | Source | Merge vers |
|------|---------|-------------|--------|------------|
| **Feature** | `feature/` | Pour le développement d'une nouvelle fonctionnalité. | `develop` | `develop` |
| **Bugfix** | `bugfix/` | Pour la correction d'un bug non critique (hors prod). | `develop` | `develop` |
| **Hotfix** | `hotfix/` | Pour la correction urgente d'un bug en production. | `main` | `main` & `develop` |
| **Release** | `release/` | Pour la préparation d'une nouvelle version (vX.Y.Z). | `develop` | `main` & `develop` |

---

## 2. Convention de Nommage des Branches

Les noms de branches doivent être en **anglais**, en **kebab-case** (minuscules séparées par des tirets).

**Format :** `<type>/<courte-description>`

**Exemples :**
- ✅ `feature/user-authentication`
- ✅ `bugfix/fix-login-button`
- ✅ `hotfix/crash-on-startup`
- ✅ `docs/update-readme`

---

## 3. Convention des Commits

Nous suivons la convention **[Conventional Commits](https://www.conventionalcommits.org/)**. Cela permet de générer automatiquement des changelogs et de comprendre rapidement la nature des modifications.

### Format du Message

```text
<type>(<scope>): <description courte>

[Description détaillée optionnelle]

[Footer optionnel (ex: Closes #123)]
```

### Types Autorisés (`<type>`)

| Type | Description |
|------|-------------|
| **`feat`** | Une nouvelle fonctionnalité (corrèle avec MINOR dans le versioning sémantique). |
| **`fix`** | Correction d'un bug (corrèle avec PATCH dans le versioning sémantique). |
| **`docs`** | Changements dans la documentation uniquement. |
| **`style`** | Changements qui n'affectent pas le sens du code (espaces, formatage, points-virgules manquants, etc). |
| **`refactor`** | Modification du code qui ne corrige pas de bug et n'ajoute pas de fonctionnalité. |
| **`perf`** | Amélioration de la performance. |
| **`test`** | Ajout ou correction de tests. |
| **`chore`** | Changements dans le processus de build, outils ou bibliothèques auxiliaires. |
| **`ci`** | Changements dans les fichiers de configuration et scripts CI/CD. |

### Exemples

- `feat(auth): add google sign-in support`
- `fix(ui): correct button alignment on mobile`
- `docs(readme): update installation instructions`
- `refactor(core): simplify data processing logic`

---

## 4. Processus de Pull Request (PR) / Merge Request (MR)

1. **Synchronisation** : Assurez-vous que votre branche est à jour avec `develop` (via `git merge develop` ou `git rebase develop`) avant de créer la PR.
2. **Titre** : Utilisez le format Conventional Commits pour le titre de la PR.
3. **Description** :
    - Expliquez le contexte ("Pourquoi ?").
    - Résumez les changements ("Quoi ?").
    - Mentionnez les tickets liés (ex: `Closes #42`).
4. **Review** : Au moins **1 approbation** d'un autre développeur est requise pour merger.
5. **CI/CD** : Tous les tests automatiques doivent passer.

---

## 5. Bonnes Pratiques

- **Atomic Commits** : Un commit doit faire une seule chose et le faire bien. Évitez les commit "fourre-tout".
- **Pas de code commenté** : Supprimez le code mort au lieu de le commenter. Git garde l'historique si besoin.
- **Messages clairs** : Le message de commit doit compléter le code, pas le répéter. Expliquez *pourquoi* le changement a été fait si ce n'est pas évident.
