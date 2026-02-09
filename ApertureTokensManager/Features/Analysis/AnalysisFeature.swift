import ComposableArchitecture
import Foundation
import Sharing
import SwiftUI

@Reducer
public struct AnalysisFeature: Sendable {
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.loggingClient) var loggingClient
  @Dependency(\.usageClient) var usageClient

  // MARK: - Cancel IDs
  
  enum CancelID: Hashable {
    case analysis
  }

  // MARK: - State
  
  @ObservableState
  public struct State: Equatable {
    // Tokens exportés (depuis la base)
    @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
    
    // Filtres d'export (partagés avec TokenFeature)
    @Shared(.tokenFilters) var tokenFilters: TokenFilters
    
    // Configuration de l'analyse
    var config: UsageAnalysisConfig = .default
    
    // Dossiers à scanner (persistés)
    @Shared(.analysisDirectories) var directoriesToScan: [ScanDirectory]
    
    // Résultat de l'analyse
    var report: TokenUsageReport?
    
    // UI State
    var isAnalyzing: Bool = false
    var scanProgress: ScanProgress?
    var analysisError: String?
    var selectedTab: AnalysisTab = .overview
    var expandedOrphanCategories: Set<String> = []
    var selectedUsedToken: UsedToken?
    var searchText: String = ""
    
    // Filtered results based on search
    var filteredUsedTokens: [UsedToken] {
      guard let report, !searchText.isEmpty else { return report?.usedTokens ?? [] }
      let query = searchText.lowercased()
      return report.usedTokens.filter {
        $0.enumCase.lowercased().contains(query) ||
        ($0.originalPath?.lowercased().contains(query) ?? false) ||
        $0.usages.contains { $0.filePath.lowercased().contains(query) }
      }
    }
    
    var filteredOrphanedTokens: [OrphanedToken] {
      guard let report, !searchText.isEmpty else { return report?.orphanedTokens ?? [] }
      let query = searchText.lowercased()
      return report.orphanedTokens.filter {
        $0.enumCase.lowercased().contains(query) ||
        ($0.originalPath?.lowercased().contains(query) ?? false) ||
        $0.category.lowercased().contains(query)
      }
    }
    
    // Computed
    var hasTokensLoaded: Bool {
      designSystemBase?.tokens != nil
    }
    
    var canStartAnalysis: Bool {
      hasTokensLoaded && !directoriesToScan.isEmpty && !isAnalyzing
    }
    
    public static var initial: Self {
      .init()
    }
  }

  // MARK: - Analysis Tab
  
  public enum AnalysisTab: String, CaseIterable, Equatable, Sendable {
    case overview = "Vue d'ensemble"
    case used = "Utilisés"
    case orphaned = "Orphelins"
  }

  // MARK: - Actions
  
  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case binding(BindingAction<State>)
    case `internal`(Internal)
    case view(View)

    @CasePathable
    public enum Analytics: Sendable, Equatable {
      case analysisCompleted(usedCount: Int, orphanedCount: Int, filesScanned: Int)
      case analysisFailed(error: String)
      case analysisStarted(directoryCount: Int, tokenCount: Int)
      case directoryAdded(name: String)
      case directoryRemoved
      case resultsCleared
      case screenViewed
      case tabChanged(tab: String)
    }

    @CasePathable
    public enum Internal: Sendable, Equatable {
      case analysisCompleted(TokenUsageReport)
      case analysisFailed(String)
      case directoryPicked(URL, Data?)
      case progressUpdated(ScanProgress)
    }

    @CasePathable
    public enum View: Sendable, Equatable {
      case addDirectoryTapped
      case cancelAnalysisTapped
      case clearResultsTapped
      case exportReportTapped
      case onAppear
      case removeDirectory(UUID)
      case startAnalysisTapped
      case tabTapped(AnalysisTab)
      case toggleOrphanCategory(String)
      case usedTokenTapped(UsedToken?)
    }
  }

  // MARK: - Body
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .analytics(let action): handleAnalyticsAction(action, state: &state)
      case .binding: .none
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
