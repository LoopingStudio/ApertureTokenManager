import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct CompareFeature: Sendable {
  @Dependency(\.tokenClient) var tokenClient
  @Dependency(\.comparisonClient) var comparisonClient

  @ObservableState
  public struct State: Equatable {
    var oldVersionTokens: [TokenNode]?
    var newVersionTokens: [TokenNode]?
    var changes: ComparisonChanges?
    var isOldFileLoaded: Bool = false
    var isNewFileLoaded: Bool = false
    var isLoadingOldFile: Bool = false
    var isLoadingNewFile: Bool = false
    var oldFileMetadata: TokenMetadata?
    var newFileMetadata: TokenMetadata?
    var loadingError: String?
    var selectedChange: TokenModification?
    
    // UI State
    var selectedTab: ComparisonTab = .overview
    
    public static var initial: Self {
      .init(
        oldVersionTokens: nil,
        newVersionTokens: nil,
        changes: nil,
        isOldFileLoaded: false,
        isNewFileLoaded: false,
        isLoadingOldFile: false,
        isLoadingNewFile: false,
        oldFileMetadata: nil,
        newFileMetadata: nil,
        loadingError: nil,
        selectedChange: nil,
        selectedTab: .overview
      )
    }
  }

  public enum FileType: Sendable {
    case old
    case new
  }

  public enum ComparisonTab: String, CaseIterable, Equatable, Sendable {
    case overview = "Vue d'ensemble"
    case added = "Ajoutés"
    case removed = "Supprimés"  
    case modified = "Modifiés"
  }

  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case `internal`(Internal)
    case view(View)

    @CasePathable
    public enum Internal: Sendable, Equatable {
      case comparisonCompleted(ComparisonChanges)
      case exportLoaded(FileType, TokenExport)
      case loadFile(FileType, URL)
      case loadingFailed(String)
      case performComparison
    }

    @CasePathable
    public enum View: Sendable, Equatable {
      case compareButtonTapped
      case exportToNotionTapped
      case fileDroppedWithProvider(FileType, NSItemProvider)
      case removeFile(FileType)
      case resetComparison
      case selectChange(TokenModification?)
      case selectFileTapped(FileType)
      case switchFiles
      case tabTapped(ComparisonTab)
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding: .none
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
