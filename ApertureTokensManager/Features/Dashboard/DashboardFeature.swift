import AppKit
import ComposableArchitecture
import Foundation

@Reducer
struct DashboardFeature: Sendable {
  @Dependency(\.exportClient) var exportClient
  @Dependency(\.fileClient) var fileClient

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
    @Shared(.tokenFilters) var filters: TokenFilters
    
    // UI State
    var isExportPopoverPresented: Bool = false
    
    // Token Browser Presentation
    @Presents var tokenBrowser: TokenBrowserFeature.State?
    
    static var initial: State { .init() }
  }

  // MARK: - Action
  
  @CasePathable
  enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case delegate(Delegate)
    case `internal`(Internal)
    case tokenBrowser(PresentationAction<TokenBrowserFeature.Action>)
    case view(View)

    @CasePathable
    enum Delegate: Equatable, Sendable {
      case compareWithBase(tokens: [TokenNode], metadata: TokenMetadata)
    }

    @CasePathable
    enum Internal: Equatable, Sendable {
      case baseCleared
    }

    @CasePathable
    enum View: Equatable, Sendable {
      case clearBaseButtonTapped
      case compareWithBaseButtonTapped
      case confirmExportButtonTapped
      case dismissExportPopover
      case exportButtonTapped
      case openFileButtonTapped
      case tokenCountTapped
    }
  }

  // MARK: - Body

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding: .none
      case .delegate: .none
      case .internal(let action): handleInternalAction(action, state: &state)
      case .tokenBrowser: .none
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
    .ifLet(\.$tokenBrowser, action: \.tokenBrowser) { TokenBrowserFeature() }
  }
  
  private func handleInternalAction(_ action: Action.Internal, state: inout State) -> Effect<Action> {
    switch action {
    case .baseCleared:
      return .none
    }
  }
}
