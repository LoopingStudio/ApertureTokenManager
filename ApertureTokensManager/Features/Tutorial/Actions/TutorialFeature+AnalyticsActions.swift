import ComposableArchitecture

// MARK: - Analytics Actions

extension TutorialFeature {
  func handleAnalyticsAction(_ action: Action.Analytics) -> Effect<Action> {
    switch action {
    case .tutorialStarted:
      loggingClient.logUserAction(
        LogFeature.tutorial,
        "started",
        ["source": "first_launch"]
      )
      return .none
      
    case .tutorialCompleted:
      loggingClient.logUserAction(
        LogFeature.tutorial,
        "completed",
        [:]
      )
      return .none
      
    case .tutorialSkipped(let atStep):
      loggingClient.logUserAction(
        LogFeature.tutorial,
        "skipped",
        ["at_step": atStep.title]
      )
      return .none
      
    case .tutorialDismissed(let atStep):
      loggingClient.logUserAction(
        LogFeature.tutorial,
        "dismissed",
        ["at_step": atStep.title]
      )
      return .none
      
    case .stepViewed(let step):
      loggingClient.logUserAction(
        LogFeature.tutorial,
        "step_viewed",
        ["step": step.title, "step_index": "\(step.rawValue)"]
      )
      return .none
      
    case .stepNavigatedBack(let fromStep):
      loggingClient.logUserAction(
        LogFeature.tutorial,
        "step_back",
        ["from_step": fromStep.title]
      )
      return .none
    }
  }
}
