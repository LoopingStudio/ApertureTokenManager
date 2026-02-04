import ComposableArchitecture
import Foundation

extension CompareFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .loadFile(let fileType, let url):
      return .run { send in
        do {
          let tokenExport = try await fileClient.loadTokenExport(url)
          await send(.internal(.exportLoaded(fileType, tokenExport, url)))
        } catch {
          await send(.internal(.loadingFailed("Erreur chargement fichier: \(error.localizedDescription)")))
        }
      }
      
    case .exportLoaded(let fileType, let tokenExport, let url):
      var fileState = fileType == .old ? state.oldFile : state.newFile
      fileState.isLoading = false
      fileState.tokens = tokenExport.tokens
      fileState.isLoaded = true
      fileState.metadata = tokenExport.metadata
      fileState.url = url
      
      if fileType == .old {
        state.oldFile = fileState
      } else {
        state.newFile = fileState
      }
      state.loadingError = nil
      return .none
      
    case .loadingFailed(let errorMessage):
      state.oldFile.isLoading = false
      state.newFile.isLoading = false
      state.loadingError = errorMessage
      return .none
      
    case .performComparison:
      guard let oldTokens = state.oldFile.tokens, let newTokens = state.newFile.tokens else { return .none }
      return .run { send in
        let comparison = await comparisonClient.compareTokens(oldTokens, newTokens)
        await send(.internal(.comparisonCompleted(comparison)))
      }
      
    case .comparisonCompleted(let changes):
      state.changes = changes
      
      // Save comparison to history
      guard let oldURL = state.oldFile.url, let newURL = state.newFile.url else {
        return .none
      }
      let oldMetadata = state.oldFile.metadata
      let newMetadata = state.newFile.metadata
      let summary = ComparisonSummary(from: changes)
      
      return .run { _ in
        let oldBookmark = await historyClient.createBookmark(oldURL)
        let newBookmark = await historyClient.createBookmark(newURL)
        let entry = ComparisonHistoryEntry(
          oldFile: FileSnapshot(
            fileName: oldURL.lastPathComponent,
            bookmarkData: oldBookmark,
            metadata: oldMetadata
          ),
          newFile: FileSnapshot(
            fileName: newURL.lastPathComponent,
            bookmarkData: newBookmark,
            metadata: newMetadata
          ),
          summary: summary
        )
        await historyClient.saveComparisonEntry(entry)
      }
      
    case .historyLoaded(let history):
      state.comparisonHistory = history
      return .none
      
    case .historySaved:
      return .run { send in
        let history = await historyClient.getComparisonHistory()
        await send(.internal(.historyLoaded(history)))
      }
    }
  }
}
