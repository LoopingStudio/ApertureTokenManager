import ComposableArchitecture
import Foundation

extension TokenFeature {
  func handleBindingAction(_ action: BindingAction<State>, state: inout State) -> EffectOf<Self> {
    switch action {
    case \.excludeTokensStartingWithHash:
      UserDefaults.standard.set(state.excludeTokensStartingWithHash, forKey: "filter.excludeHash")
      return .send(.internal(.applyFilters))
    case \.excludeTokensEndingWithHover:
      UserDefaults.standard.set(state.excludeTokensEndingWithHover, forKey: "filter.excludeHover")
      return .send(.internal(.applyFilters))
    default: return .none
    }
  }
}
