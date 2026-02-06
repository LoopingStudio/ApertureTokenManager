import ComposableArchitecture
import Foundation

extension TokenBrowserFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> Effect<Action> {
    switch action {
    case .collapseNode(let id):
      state.expandedNodes.remove(id)
      return .none
      
    case .expandNode(let id):
      state.expandedNodes.insert(id)
      return .none
      
    case .selectNode(let node):
      state.selectedNode = node
      return .none
      
    case .toggleNode(let id):
      if state.expandedNodes.contains(id) {
        state.expandedNodes.remove(id)
      } else {
        state.expandedNodes.insert(id)
      }
      return .none
    }
  }
}
