# Lessons Learned

## Table des matières
1. [Architecture TCA](#architecture-tca)
2. [Services & Clients](#services--clients)
3. [State Management](#state-management)
4. [Modèles de données](#modèles-de-données)
5. [Opérations récursives](#opérations-récursives)
6. [Fuzzy Matching](#fuzzy-matching)
7. [Export](#export)
8. [SwiftUI Patterns](#swiftui-patterns)
9. [Performance](#performance)
10. [Conventions de nommage](#conventions-de-nommage)

---

## Architecture TCA

### Organisation des Features
Chaque feature suit une structure cohérente :
- `Feature.swift` - Reducer principal avec State et Actions
- `Feature+View.swift` - Vue SwiftUI avec `@ViewAction`
- `Actions/Feature+ViewActions.swift` - Handler des actions utilisateur
- `Actions/Feature+InternalActions.swift` - Handler des résultats async
- `Views/` - Sous-vues spécifiques à la feature

### Hiérarchie des Actions
```swift
enum Action: BindableAction, ViewAction, Equatable, Sendable {
  case binding(BindingAction<State>)
  case `internal`(Internal)
  case view(View)
  case delegate(Delegate)  // Pour communication cross-feature
}
```

**Règles** :
- `View` = actions initiées par l'utilisateur (imperatif: `buttonTapped`, `fileTapped`)
- `Internal` = résultats async (passé: `fileLoaded`, `exportCompleted`)
- `Delegate` = effets cross-feature (`compareWithBase`, `baseUpdated`)
- Toujours `@CasePathable`, `Equatable`, `Sendable`
- Actions triées par ordre alphabétique

### ViewAction Pattern
Conformer `Action` à `ViewAction` pour utiliser `send()` au lieu de `store.send(.view())` :
```swift
@ViewAction(for: TokenFeature.self)
struct TokenView: View {
  @Bindable var store: StoreOf<TokenFeature>

  var body: some View {
    Button("Load") { send(.loadButtonTapped) }  // Pas store.send(.view(...))
  }
}
```

---

## Services & Clients

### Pattern Client-Service
Chaque service a deux fichiers :
1. **Client** (`File+Client.swift`) - Interface avec closures `@Sendable`
2. **Service** (`File+Service.swift`) - Implémentation actor

```swift
// Client - Interface
struct FileClient {
  var pickFile: @Sendable () async throws -> URL?
  var loadTokenExport: @Sendable (URL) async throws -> TokenExport
}

// Service - Implémentation
actor FileService {
  @MainActor
  func pickFile() async throws -> URL? { /* NSOpenPanel */ }
}
```

### Trois valeurs obligatoires
Toujours fournir pour chaque client :
- `liveValue` - Implémentation réelle avec le service actor
- `testValue` - Retourne des valeurs vides/mock pour les tests
- `previewValue` - Souvent égal à testValue, pour les previews SwiftUI

```swift
extension FileClient: DependencyKey {
  static let liveValue: Self = { let service = FileService(); return .init(...) }()
  static let testValue: Self = .init(pickFile: { nil }, loadTokenExport: { _ in .empty })
  static let previewValue: Self = testValue
}
```

### Actors pour thread-safety
Les services utilisent `actor` pour la sécurité des threads sans locks explicites.

---

## State Management

### @Shared pour état persistant
Utiliser `@Shared` (Sharing library) pour l'état partagé entre features :
```swift
@ObservableState
struct State: Equatable {
  // État local UI
  var isLoading: Bool = false

  // État partagé/persistant
  @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
  @Shared(.tokenFilters) var filters: TokenFilters
}
```

### SharedKeys
Définir les clés dans `Extensions/SharedKeys.swift` :
```swift
extension SharedKey where Self == FileStorageKey<DesignSystemBase?>.Default {
  static var designSystemBase: Self {
    Self[.fileStorage(.designSystemBase), default: nil]
  }
}
```

### Mutation atomique avec withLock
```swift
state.$designSystemBase.withLock {
  $0 = DesignSystemBase(fileName: ..., bookmarkData: ..., metadata: ..., tokens: ...)
}
```

---

## Modèles de données

### UUID sur decode, pas encode
Générer un nouvel UUID à chaque décodage pour éviter les collisions :
```swift
public init(from decoder: Decoder) throws {
  self.id = UUID()  // Nouveau ID à chaque import
  self.name = try container.decode(String.self, forKey: .name)
}

public func encode(to encoder: Encoder) throws {
  // NE PAS encoder l'ID
  try container.encode(name, forKey: .name)
}
```

### Modèles de projection légers
Utiliser `TokenSummary` au lieu de `TokenNode` dans les collections pour réduire la mémoire :
```swift
public struct TokenSummary: Equatable, Sendable, Identifiable {
  public let id = UUID()
  let name: String
  let path: String
  let modes: TokenThemes?

  init(from node: TokenNode) { /* projeter les champs */ }
}
```

### Flag + Message pour erreurs
Stocker à la fois le booléen et le message :
```swift
var loadingError: Bool
var errorMessage: String?
```

---

## Opérations récursives

### Mutation in-place avec index
Utiliser des boucles avec index pour muter des structures imbriquées :
```swift
private func updateNodeRecursively(nodes: inout [TokenNode], targetId: TokenNode.ID) {
  for i in 0..<nodes.count {
    if nodes[i].id == targetId {
      nodes[i].toggleRecursively(newState)
      return
    }
    if nodes[i].children != nil {
      updateNodeRecursively(nodes: &nodes[i].children!, targetId: targetId)
    }
  }
}
```

### Cascade de désactivation
Passer un flag `forceDisabled` pour propager l'état parent aux enfants :
```swift
private func applyFiltersRecursively(
  nodes: inout [TokenNode],
  filters: TokenFilters,
  forceDisabled: Bool = false
) {
  for i in 0..<nodes.count {
    var shouldDisableChildren = forceDisabled

    if nodes[i].type == .group && nodes[i].name == "Utility" && filters.excludeUtilityGroup {
      nodes[i].isEnabled = false
      shouldDisableChildren = true
    }

    if nodes[i].children != nil {
      applyFiltersRecursively(nodes: &nodes[i].children!, filters: filters, forceDisabled: shouldDisableChildren)
    }
  }
}
```

---

## Fuzzy Matching

### Hiérarchie des critères
Pour le matching de tokens de design, prioriser :
1. **Couleur (50%)** - Le plus important car on cherche un remplacement visuel
2. **Contexte d'usage (30%)** - Marqueurs sémantiques (`bg`, `fg`, `hover`, `solid`, `surface`, etc.)
3. **Structure/Path (20%)** - Moins important si couleur et contexte matchent

**Règle** : Ne jamais prioriser le path/nom sur la couleur. L'utilisateur cherche une équivalence visuelle, pas de nomenclature.

### Marqueurs sémantiques
Groupes de contexte pour matcher des usages similaires :
- **Fond** : `bg`, `background`, `surface`, `fill`, `canvas`
- **Premier plan** : `fg`, `foreground`, `text`, `label`, `title`, `content`
- **Bordures** : `border`, `stroke`, `outline`, `divider`, `separator`
- **États interactifs** : `hover`, `hovered`, `active`, `pressed`, `focus`, `focused`
- **États désactivés** : `disabled`, `inactive`, `muted`
- **Variantes** : `solid`, `filled`, `ghost`, `subtle`, `tinted`
- **Hiérarchie** : `primary`, `secondary`, `tertiary`
- **Feedback** : `error`, `warning`, `success`, `info`, `danger`

---

## Export

### Pattern temp directory + move
Assure une opération atomique :
```swift
@MainActor
func exportDesignSystem(nodes: [TokenNode]) async throws {
  // 1. Créer dans un dossier temporaire
  let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try await createColorsXCAssets(from: filtered, at: tempURL)
  try await createApertureColorsSwift(from: filtered, at: tempURL)

  // 2. Déplacer vers destination finale
  try FileManager.default.copyItem(at: tempURL, to: destinationURL)
  try? FileManager.default.removeItem(at: tempURL)
}
```

**Avantages** : Pas d'export partiel en cas d'erreur.

### Security-scoped bookmarks
Pour accéder aux fichiers sélectionnés par l'utilisateur après redémarrage :
```swift
let bookmarkData = url.securityScopedBookmark()
// Plus tard...
if let url = URL(resolvingBookmarkData: bookmarkData, ...) {
  _ = url.startAccessingSecurityScopedResource()
  defer { url.stopAccessingSecurityScopedResource() }
  // Utiliser url
}
```

---

## SwiftUI Patterns

### ViewBuilder pour sections logiques
Utiliser des computed properties `@ViewBuilder` pour découper les vues :
```swift
struct MyView: View {
  var body: some View {
    VStack {
      headerSection
      contentSection
      footerSection
    }
  }

  @ViewBuilder
  private var headerSection: some View { /* ... */ }

  @ViewBuilder
  private var contentSection: some View { /* ... */ }
}
```

### State machine avec ViewBuilder
Plusieurs `@State` bools + `@ViewBuilder` = états UI clairs :
```swift
@State private var isLoading = false
@State private var hasError = false
@State private var isLoaded = false

@ViewBuilder
private var iconView: some View {
  if isLoading {
    ProgressView()
  } else if hasError {
    Image(systemName: "exclamationmark.circle.fill")
  } else if isLoaded {
    Image(systemName: "checkmark.circle.fill")
  } else {
    Image(systemName: "doc.text")
  }
}
```

### ViewModifier pour effets réutilisables
```swift
struct StaggeredAppearModifier: ViewModifier {
  let index: Int
  @State private var isVisible = false

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 10)
      .onAppear {
        withAnimation(.easeOut(duration: 0.35).delay(Double(index) * 0.08)) {
          isVisible = true
        }
      }
  }
}

extension View {
  func staggeredAppear(index: Int) -> some View {
    modifier(StaggeredAppearModifier(index: index))
  }
}
```

---

## Performance

### Aplatir pour recherche
Éviter la traversée récursive pour chaque recherche :
```swift
static func flattenTokens(_ tokens: [TokenNode]) -> [TokenNode] {
  var result: [TokenNode] = []
  func flatten(_ nodes: [TokenNode]) {
    for node in nodes {
      if node.type == .token { result.append(node) }
      if let children = node.children { flatten(children) }
    }
  }
  flatten(tokens)
  return result
}
```

### Filtrage lazy avec publisher
Appliquer les filtres une seule fois au chargement, puis réappliquer uniquement quand les filtres changent :
```swift
case .observeFilters:
  return .publisher {
    state.$filters.publisher
      .dropFirst()
      .map { Action.internal(.filtersChanged($0)) }
  }
```

---

## Conventions de nommage

### Actions
- **View** : Impératif présent (`selectFileTapped`, `exportButtonTapped`)
- **Internal** : Passé composé (`fileLoaded`, `exportCompleted`, `filtersChanged`)
- **Delegate** : Verbe d'action (`compareWithBase`, `navigateToTab`)

### Modèles
- **Concrets** : `TokenNode`, `TokenExport`, `DesignSystemBase`
- **Projections** : `TokenSummary` (léger)
- **Entries** : `ImportHistoryEntry`, `ComparisonHistoryEntry`
- **Changes** : `ComparisonChanges`, `TokenModification`, `ColorChange`

### Services
- **Clients** : `FileClient`, `ExportClient` (interfaces)
- **Services** : `FileService`, `ExportService` (actors)

### Constantes
Regrouper dans `Constants.swift` :
```swift
enum Brand: String, CaseIterable { case legacy, newBrand }
enum ThemeType: String { case light, dark }
enum GroupNames { static let utility = "utility" }
```

---

## Token Usage Analysis

### Architecture de l'analyse
L'analyse d'utilisation suit le pattern standard :
```
AnalysisFeature
    ↓ (startAnalysisTapped)
UsageClient.analyzeUsage()
    ↓
UsageService (actor)
    ↓ (utilise)
TokenUsageHelpers (static methods)
    ↓
TokenUsageReport → affiché dans les vues
```

### Patterns de recherche
Pour détecter les usages de tokens dans les fichiers Swift :
```swift
enum UsagePattern {
  // .tokenName (shorthand)
  static let dotPrefix = #"\.([a-z][a-zA-Z0-9]*)"#

  // Color.tokenName ou Aperture.Foundations.Color.tokenName
  static let fullyQualified = #"(?:Aperture\.Foundations\.)?Color\.([a-z][a-zA-Z0-9]*)"#

  // theme.color(.tokenName)
  static let themeColor = #"\.color\(\s*\.([a-z][a-zA-Z0-9]*)\s*\)"#
}
```

### Conversion nom → enumCase
Les tokens exportés utilisent camelCase :
```swift
// "bg-brand-solid" → "bgBrandSolid"
static func tokenNameToEnumCase(_ name: String) -> String {
  let cleanName = name
    .replacingOccurrences(of: "-", with: " ")
    .replacingOccurrences(of: "_", with: " ")

  let components = cleanName.split(separator: " ")
  let firstComponent = String(components[0]).lowercased()
  let otherComponents = components.dropFirst().map { String($0).capitalized }

  return firstComponent + otherComponents.joined()
}
```

### Filtering des fichiers
Ignorer les dossiers non pertinents lors du scan :
```swift
let ignoredDirs = ["DerivedData", ".build", "Pods", "Carthage", ".xcodeproj", ".xcworkspace"]
```

Options de config :
- `ignoreTestFiles` - Fichiers contenant "test" ou "spec"
- `ignorePreviewFiles` - Fichiers contenant "preview"

---

## Notes pour le futur

### Localisation
Tous les strings UI sont en français. Pour le multi-langue, extraire vers `Localizable.strings`.

### Tests
Utiliser `testValue` des clients pour les tests unitaires. Les reducers peuvent être testés avec `TestStore`.

### Historique
- Max 10 entrées (défini dans le service)
- Déduplication par nom de fichier (imports) ou paires (comparaisons)
- Insertion en tête (plus récent en premier)
