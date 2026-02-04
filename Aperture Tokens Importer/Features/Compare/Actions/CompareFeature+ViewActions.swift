import ComposableArchitecture
import Foundation

extension CompareFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> EffectOf<Self> {
    switch action {
    case .selectFileTapped(let fileType):
      switch fileType {
      case .old:
        state.isLoadingOldFile = true
      case .new:
        state.isLoadingNewFile = true
      }
      return .run { send in
        guard let url = try? await fileClient.pickFile() else { 
          await send(.internal(.loadingFailed("Aucun fichier sélectionné")))
          return 
        }
        await send(.internal(.loadFile(fileType, url)))
      }
      
    case .fileDroppedWithProvider(let fileType, let provider):
      switch fileType {
      case .old:
        state.isLoadingOldFile = true
      case .new:
        state.isLoadingNewFile = true
      }
      return .run { send in
        guard let url = await fileClient.handleFileDrop(provider) else { 
          await send(.internal(.loadingFailed("Impossible de lire le fichier")))
          return 
        }
        await send(.internal(.loadFile(fileType, url)))
      }
      
    case .selectChange(let change):
      state.selectedChange = change
      return .none
      
    case .compareButtonTapped:
      if state.isOldFileLoaded && state.isNewFileLoaded {
        return .send(.internal(.performComparison))
      }
      return .none
      
    case .exportToNotionTapped:
      guard let changes = state.changes else { return .none }
      return .run { [changes, oldMetadata = state.oldFileMetadata, newMetadata = state.newFileMetadata] _ in
        guard let oldMetadata, let newMetadata else { return }
        try await comparisonClient.exportToNotion(changes, oldMetadata, newMetadata)
      } catch: { error, _ in
        print("Erreur export Notion: \(error)")
      }
      
    case .resetComparison:
      state = .initial
      return .none
          case .removeFile(let fileType):
      switch fileType {
      case .old:
        state.oldVersionTokens = nil
        state.isOldFileLoaded = false
        state.oldFileMetadata = nil
      case .new:
        state.newVersionTokens = nil
        state.isNewFileLoaded = false
        state.newFileMetadata = nil
      }
      // Reset comparison if it was already done
      state.changes = nil
      state.selectedTab = .overview
      return .none
      
    case .switchFiles:
      // Échanger les fichiers et leurs métadonnées
      let tempTokens = state.oldVersionTokens
      let tempMetadata = state.oldFileMetadata
      let tempLoaded = state.isOldFileLoaded
      
      state.oldVersionTokens = state.newVersionTokens
      state.oldFileMetadata = state.newFileMetadata
      state.isOldFileLoaded = state.isNewFileLoaded
      
      state.newVersionTokens = tempTokens
      state.newFileMetadata = tempMetadata
      state.isNewFileLoaded = tempLoaded
      
      // Reset comparison if it was already done
      state.changes = nil
      state.selectedTab = .overview
      return .none
      
    case .tabTapped(let tab):
      state.selectedTab = tab
      return .none
      
    case .suggestReplacement(let removedTokenPath, let replacementTokenPath):
      guard state.changes != nil else { return .none }
      
      if let replacementPath = replacementTokenPath {
        state.changes?.addReplacementSuggestion(removedTokenPath: removedTokenPath, suggestedTokenPath: replacementPath)
      } else {
        state.changes?.removeReplacementSuggestion(for: removedTokenPath)
      }
      return .none
    }
  }
}
