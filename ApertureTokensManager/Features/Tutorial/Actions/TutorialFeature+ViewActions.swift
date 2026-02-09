import ComposableArchitecture

// MARK: - View Actions

extension TutorialFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> Effect<Action> {
    switch action {
    case .backTapped:
      let fromStep = state.currentStep
      if let previousIndex = TutorialStep.allCases.firstIndex(of: state.currentStep),
         previousIndex > 0 {
        state.currentStep = TutorialStep.allCases[previousIndex - 1]
      }
      return .send(.analytics(.stepNavigatedBack(from: fromStep)))
      
    case .closeTapped:
      let atStep = state.currentStep
      return .concatenate(
        .send(.analytics(.tutorialDismissed(atStep: atStep))),
        .send(.delegate(.dismissed))
      )
      
    case .onAppear:
      return .send(.analytics(.tutorialStarted))
      
    case .nextTapped:
      if state.currentStep.isLast {
        state.$onboardingState.withLock { $0.hasCompletedTutorial = true }
        return .concatenate(
          .send(.analytics(.tutorialCompleted)),
          .send(.delegate(.completed))
        )
      } else if let currentIndex = TutorialStep.allCases.firstIndex(of: state.currentStep),
                currentIndex < TutorialStep.allCases.count - 1 {
        let nextStep = TutorialStep.allCases[currentIndex + 1]
        state.currentStep = nextStep
        return .send(.analytics(.stepViewed(nextStep)))
      }
      return .none
      
    case .skipTapped:
      let atStep = state.currentStep
      state.$onboardingState.withLock { $0.hasCompletedTutorial = true }
      return .concatenate(
        .send(.analytics(.tutorialSkipped(atStep: atStep))),
        .send(.delegate(.dismissed))
      )
      
    case .stepTapped(let step):
      state.currentStep = step
      return .send(.analytics(.stepViewed(step)))
    }
  }
}
