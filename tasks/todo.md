# Todo

## Completed

### [2026-02-06] Feature: Suggestions intelligentes avec fuzzy matching

- [x] Créer `FuzzyMatchingHelpers.swift` avec algorithmes de similarité
- [x] Ajouter `AutoSuggestion` model dans `TokenComparison.swift`
- [x] Créer `SuggestionService` (actor) et `SuggestionClient`
- [x] Intégrer dans `CompareFeature` avec `@Dependency`
- [x] Ajouter actions `suggestionsComputed`, `acceptAutoSuggestion`, `rejectAutoSuggestion`
- [x] Mettre à jour `RemovedTokensView` avec UI de confiance
- [x] Refactorer hiérarchie: Couleur (50%) > Contexte d'usage (30%) > Structure (20%)
- [x] Ajouter marqueurs sémantiques: `bg`, `fg`, `hover`, `solid`, `surface`, etc.
- [x] Build et vérification preview

**Résultat**: Feature fonctionnelle avec suggestions automatiques affichées dans l'onglet "Supprimés" de la comparaison. Score de confiance visible avec code couleur (vert >70%, orange 50-70%, gris <50%).

---

### [2026-02-06] Feature: Token Usage Analysis

- [x] Créer `TokenUsageHelpers.swift` - Parsing Swift et regex pour détecter les usages
- [x] Créer `UsageAnalysis.swift` model - TokenUsageReport, UsedToken, OrphanedToken
- [x] Créer `UsageService` (actor) et `UsageClient`
- [x] Créer `AnalysisFeature` - TCA reducer avec State/Actions
- [x] Créer `AnalysisFeature+ViewActions.swift` et `AnalysisFeature+InternalActions.swift`
- [x] Créer `AnalysisFeature+View.swift` - UI de configuration avec sélection de dossiers
- [x] Créer `UsageOverviewView.swift` - Vue d'ensemble avec statistiques
- [x] Créer `UsedTokensListView.swift` - Liste des tokens utilisés avec détails
- [x] Créer `OrphanedTokensListView.swift` - Liste des tokens orphelins par catégorie
- [x] Intégrer dans `AppFeature` - Nouvel onglet "Analyser"
- [x] Build et vérification

**Résultat**: Nouvel onglet "Analyser" permettant de scanner des projets Swift pour détecter l'utilisation des tokens. Affiche les tokens utilisés avec leurs occurrences (fichier, ligne, contexte) et les tokens orphelins groupés par catégorie.

---

## En cours

_Aucune tâche en cours_

---

## Backlog

_À définir avec l'utilisateur_

---
