import ComposableArchitecture
import Dependencies
import Foundation
import Sharing

@Reducer
public struct TutorialFeature: Sendable {
  @Dependency(\.loggingClient) var loggingClient

  // MARK: - State
  
  @ObservableState
  public struct State: Equatable {
    @Shared(.onboardingState) var onboardingState: OnboardingState
    var currentStep: TutorialStep = .welcome
    
    public static var initial: Self { .init() }
  }
  
  // MARK: - Actions
  
  @CasePathable
  public enum Action: ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case delegate(Delegate)
    case view(View)
    
    @CasePathable
    public enum Delegate: Equatable, Sendable {
      case completed
      case dismissed
    }
    
    @CasePathable
    public enum View: Equatable, Sendable {
      case backTapped
      case closeTapped
      case nextTapped
      case onAppear
      case skipTapped
      case stepTapped(TutorialStep)
    }
    
    @CasePathable
    public enum Analytics: Equatable, Sendable {
      case tutorialStarted
      case tutorialCompleted
      case tutorialSkipped(atStep: TutorialStep)
      case tutorialDismissed(atStep: TutorialStep)
      case stepViewed(TutorialStep)
      case stepNavigatedBack(from: TutorialStep)
    }
  }
  
  // MARK: - Body
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .analytics(let analyticsAction):
        return handleAnalyticsAction(analyticsAction)
        
      case .delegate:
        return .none
        
      case .view(let viewAction):
        return handleViewAction(viewAction, state: &state)
      }
    }
  }
}
