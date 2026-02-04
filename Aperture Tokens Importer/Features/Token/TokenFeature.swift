import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct TokenFeature: Sendable {
  @Dependency(\.tokenClient) var tokenClient
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.historyClient) var historyClient

  @ObservableState
  public struct State: Equatable {
    var rootNodes: [TokenNode]
    var isFileLoaded: Bool
    var isLoading: Bool
    var loadingError: Bool
    var errorMessage: String?
    var metadata: TokenMetadata?
    var selectedNode: TokenNode?
    var expandedNodes: Set<TokenNode.ID> = []
    var allNodes: [TokenNode] = []
    var currentFileURL: URL?
    
    // History
    var importHistory: [ImportHistoryEntry] = []
    
    // Export filters
    var excludeTokensStartingWithHash: Bool = false
    var excludeTokensEndingWithHover: Bool = false
    
    // UI State
    var splitViewRatio: Double = 0.6

    public static var initial: Self {
      .init(
        rootNodes: [],
        isFileLoaded: false,
        isLoading: false,
        loadingError: false,
        errorMessage: nil,
        metadata: nil,
        selectedNode: nil,
        expandedNodes: [],
        allNodes: [],
        currentFileURL: nil,
        importHistory: [],
        excludeTokensStartingWithHash: UserDefaults.standard.bool(forKey: "filter.excludeHash"),
        excludeTokensEndingWithHover: UserDefaults.standard.bool(forKey: "filter.excludeHover"),
        splitViewRatio: 0.6
      )
    }
  }

  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case `internal`(Internal)
    case view(View)

    @CasePathable
    public enum Internal: Sendable, Equatable {
      case loadFile(URL)
      case exportLoaded(TokenExport, URL)
      case fileLoadingStarted
      case fileLoadingFailed(String)
      case applyFilters
      case historyLoaded([ImportHistoryEntry])
      case historySaved
    }

    @CasePathable
    public enum View: Sendable, Equatable {
      case exportButtonTapped
      case fileDroppedWithProvider(NSItemProvider)
      case selectFileTapped
      case resetFile
      case selectNode(TokenNode)
      case toggleNode(TokenNode.ID)
      case expandNode(TokenNode.ID)
      case collapseNode(TokenNode.ID)
      case keyPressed(KeyEquivalent)
      case onAppear
      case historyEntryTapped(ImportHistoryEntry)
      case removeHistoryEntry(UUID)
      case clearHistory
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(let action): handleBindingAction(action, state: &state)
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
