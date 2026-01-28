import ComposableArchitecture
import Foundation

extension CompareFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .loadFile(let fileType, let url):
      return .run { send in
        do {
          let tokenExport = try await tokenClient.loadJSON(url)
          await send(.internal(.exportLoaded(fileType, tokenExport)))
        } catch {
          await send(.internal(.loadingFailed("Erreur chargement fichier: \(error.localizedDescription)")))
        }
      }
      
    case .exportLoaded(let fileType, let tokenExport):
      switch fileType {
      case .old:
        state.isLoadingOldFile = false
        state.oldVersionTokens = tokenExport.tokens
        state.isOldFileLoaded = true
        state.oldFileMetadata = tokenExport.metadata
        state.loadingError = nil

        // Ne plus lancer automatiquement la comparaison
      case .new:
        state.isLoadingNewFile = false
        state.newVersionTokens = tokenExport.tokens
        state.isNewFileLoaded = true
        state.newFileMetadata = tokenExport.metadata
        state.loadingError = nil

        // Ne plus lancer automatiquement la comparaison
      }
      return .none
      
    case .loadingFailed(let errorMessage):
      state.isLoadingOldFile = false
      state.isLoadingNewFile = false
      state.loadingError = errorMessage
      return .none
      
    case .performComparison:
      guard let oldTokens = state.oldVersionTokens, let newTokens = state.newVersionTokens else { return .none }
      return .run { send in
        let comparison = await comparisonClient.compareTokens(oldTokens, newTokens)
        await send(.internal(.comparisonCompleted(comparison)))
      }
      
    case .comparisonCompleted(let changes):
      state.changes = changes
      return .none
    }
  }
}
