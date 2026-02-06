import ComposableArchitecture
import Foundation

extension AnalysisFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> EffectOf<Self> {
    switch action {
    case .addDirectoryTapped:
      return .run { send in
        guard let url = try? await fileClient.pickDirectory("Sélectionnez un dossier à analyser") else {
          return
        }
        
        // Créer un bookmark pour accès futur
        let bookmarkData = try? url.bookmarkData(
          options: .withSecurityScope,
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        
        await send(.internal(.directoryPicked(url, bookmarkData)))
      }
      
    case .clearResultsTapped:
      state.report = nil
      state.selectedTab = .overview
      state.selectedUsedToken = nil
      state.expandedOrphanCategories = []
      return .none
      
    case .onAppear:
      return .none
      
    case .removeDirectory(let id):
      state.directoriesToScan.removeAll { $0.id == id }
      return .none
      
    case .startAnalysisTapped:
      guard state.canStartAnalysis, let tokens = state.designSystemBase?.tokens else {
        return .none
      }
      
      state.isAnalyzing = true
      state.analysisError = nil
      state.report = nil
      
      return .run { [directories = state.directoriesToScan, config = state.config, filters = state.tokenFilters] send in
        do {
          let report = try await usageClient.analyzeUsage(directories, tokens, config, filters)
          await send(.internal(.analysisCompleted(report)))
        } catch {
          await send(.internal(.analysisFailed(error.localizedDescription)))
        }
      }
      
    case .tabTapped(let tab):
      state.selectedTab = tab
      return .none
      
    case .toggleOrphanCategory(let category):
      if state.expandedOrphanCategories.contains(category) {
        state.expandedOrphanCategories.remove(category)
      } else {
        state.expandedOrphanCategories.insert(category)
      }
      return .none
      
    case .usedTokenTapped(let token):
      state.selectedUsedToken = token
      return .none
    }
  }
}
