import ComposableArchitecture
import Foundation
import UniformTypeIdentifiers

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
      return .send(.analytics(.resultsCleared))
      
    case .onAppear:
      // Résoudre les bookmarks pour avoir des URLs valides
      state.$directoriesToScan.withLock { directories in
        for i in 0..<directories.count {
          if let resolvedURL = directories[i].resolveAndAccess() {
            directories[i].url = resolvedURL
          }
        }
      }
      return .send(.analytics(.screenViewed))
      
    case .removeDirectory(let id):
      state.$directoriesToScan.withLock { directories in
        directories.removeAll { $0.id == id }
      }
      return .send(.analytics(.directoryRemoved))
      
    case .cancelAnalysisTapped:
      state.isAnalyzing = false
      state.scanProgress = nil
      return .cancel(id: CancelID.analysis)
      
    case .startAnalysisTapped:
      guard state.canStartAnalysis, let tokens = state.designSystemBase?.tokens else {
        return .none
      }
      
      state.isAnalyzing = true
      state.analysisError = nil
      state.report = nil
      state.scanProgress = .initial
      
      let directoryCount = state.directoriesToScan.count
      let tokenCount = TokenHelpers.countLeafTokens(tokens)
      
      return .merge(
        .send(.analytics(.analysisStarted(directoryCount: directoryCount, tokenCount: tokenCount))),
        .run { [directories = state.directoriesToScan, config = state.config, filters = state.tokenFilters] send in
          do {
            let report = try await usageClient.analyzeUsage(directories, tokens, config, filters) { progress in
              Task { @MainActor in
                await send(.internal(.progressUpdated(progress)))
              }
            }
            await send(.internal(.analysisCompleted(report)))
          } catch is CancellationError {
            // Cancelled by user, don't report as error
          } catch {
            await send(.internal(.analysisFailed(error.localizedDescription)))
          }
        }
        .cancellable(id: CancelID.analysis, cancelInFlight: true)
      )
      
    case .tabTapped(let tab):
      state.selectedTab = tab
      return .send(.analytics(.tabChanged(tab: tab.rawValue)))
      
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
      
    case .exportReportTapped:
      guard let report = state.report else { return .none }
      
      let markdown = AnalysisReportFormatter.formatAsMarkdown(report)
      let defaultName = "analyse-tokens-\(Date().formatted(.dateTime.year().month().day())).md"
      
      return .run { send in
        _ = try? await fileClient.saveTextFile(markdown, defaultName, "Exporter le rapport", nil, .markdown)
      }
    }
  }
}
