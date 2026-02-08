import AppKit
import ComposableArchitecture
import Foundation
import Sharing

@Reducer
struct SettingsFeature: Sendable {
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.loggingClient) var loggingClient

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    // Shared settings
    @Shared(.tokenFilters) var tokenFilters: TokenFilters
    @Shared(.appSettings) var appSettings: AppSettings
    @Shared(.importHistory) var importHistory: [ImportHistoryEntry]
    @Shared(.comparisonHistory) var comparisonHistory: [ComparisonHistoryEntry]
    @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
    @Shared(.analysisDirectories) var analysisDirectories: [ScanDirectory]
    
    // Logs
    var logEntries: [LogEntry] = []
    var logCount: Int = 0
    var isLoadingLogs: Bool = false
    var isExportingLogs: Bool = false
    
    // UI
    var selectedSection: SettingsSection = .export
    var showResetConfirmation: Bool = false
    
    static var initial: State { .init() }
  }
  
  // MARK: - Settings Sections
  
  enum SettingsSection: String, CaseIterable, Equatable, Sendable {
    case export = "Export"
    case history = "Historique"
    case data = "Données"
    case logs = "Logs"
    case about = "À propos"
  }

  // MARK: - Action

  @CasePathable
  enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case `internal`(Internal)
    case view(View)

    @CasePathable
    enum Internal: Equatable, Sendable {
      case logEntriesLoaded([LogEntry])
      case logsExported(String)
    }

    @CasePathable
    enum View: Equatable, Sendable {
      case clearLogsButtonTapped
      case confirmResetAllData
      case dismissResetConfirmation
      case exportLogsButtonTapped
      case onAppear
      case openDataFolderButtonTapped
      case refreshLogsButtonTapped
      case resetAllDataButtonTapped
      case sectionSelected(SettingsSection)
    }
  }

  // MARK: - Body

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding: return .none
      case .internal(let action): return handleInternalAction(action, state: &state)
      case .view(let action): return handleViewAction(action, state: &state)
      }
    }
  }
}
