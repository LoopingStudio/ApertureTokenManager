import ComposableArchitecture
import Foundation

@Reducer
struct TokenBrowserFeature: Sendable {
  
  // MARK: - State
  
  @ObservableState
  struct State: Equatable {
    let tokens: [TokenNode]
    let metadata: TokenMetadata
    var selectedNode: TokenNode?
    var expandedNodes: Set<TokenNode.ID> = []
    
    var tokenCount: Int { TokenHelpers.countLeafTokens(tokens) }

    static func initial(tokens: [TokenNode], metadata: TokenMetadata) -> Self {
      .init(tokens: tokens, metadata: metadata, selectedNode: nil, expandedNodes: [])
    }
  }
  
  // MARK: - Action
  
  @CasePathable
  enum Action: ViewAction, Equatable, Sendable {
    case view(View)
    
    @CasePathable
    enum View: Equatable, Sendable {
      case collapseNode(TokenNode.ID)
      case expandNode(TokenNode.ID)
      case selectNode(TokenNode)
      case toggleNode(TokenNode.ID)
    }
  }
  
  // MARK: - Body
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
