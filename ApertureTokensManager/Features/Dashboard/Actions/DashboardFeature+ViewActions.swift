import ComposableArchitecture
import Foundation
import Sharing

extension DashboardFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> EffectOf<Self> {
    switch action {
    case .clearBaseButtonTapped:
      state.$designSystemBase.withLock { $0 = nil }
      return .send(.internal(.baseCleared))
      
    case .compareWithBaseButtonTapped:
      guard let base = state.designSystemBase else { return .none }
      return .send(.delegate(.compareWithBase(tokens: base.tokens, metadata: base.metadata)))
      
    case .confirmExportButtonTapped:
      guard let base = state.designSystemBase else { return .none }
      state.isExportPopoverPresented = false
      return .run { _ in
        try await exportClient.exportDesignSystem(base.tokens)
      }
      
    case .dismissExportPopover:
      state.isExportPopoverPresented = false
      return .none
      
    case .exportButtonTapped:
      state.isExportPopoverPresented = true
      return .none
      
    case .openFileButtonTapped:
      guard let base = state.designSystemBase,
            let url = base.resolveURL() else { return .none }
      return .run { _ in
        await fileClient.openInFinder(url)
      }
      
    case .tokenCountTapped:
      guard let base = state.designSystemBase else { return .none }
      state.tokenBrowser = .initial(tokens: base.tokens, metadata: base.metadata)
      return .none
    }
  }
}
