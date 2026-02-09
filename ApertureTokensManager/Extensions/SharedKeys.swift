import Foundation
import Sharing

extension URL {
  static let importHistory = Self.documentsDirectory.appending(component: "import-history.json")
  static let comparisonHistory = Self.documentsDirectory.appending(component: "comparison-history.json")
  
  func securityScopedBookmark() -> Data? {
    try? bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
  }
}

extension SharedKey where Self == FileStorageKey<[ImportHistoryEntry]>.Default {
  static var importHistory: Self {
    Self[.fileStorage(.importHistory), default: []]
  }
}

extension SharedKey where Self == FileStorageKey<[ComparisonHistoryEntry]>.Default {
  static var comparisonHistory: Self {
    Self[.fileStorage(.comparisonHistory), default: []]
  }
}

// MARK: - Filter Settings

public struct TokenFilters: Equatable, Sendable {
  public var excludeTokensStartingWithHash: Bool = false
  public var excludeTokensEndingWithHover: Bool = false
  public var excludeUtilityGroup: Bool = false
  
  public init(
    excludeTokensStartingWithHash: Bool = false,
    excludeTokensEndingWithHover: Bool = false,
    excludeUtilityGroup: Bool = false
  ) {
    self.excludeTokensStartingWithHash = excludeTokensStartingWithHash
    self.excludeTokensEndingWithHover = excludeTokensEndingWithHover
    self.excludeUtilityGroup = excludeUtilityGroup
  }
  
  enum CodingKeys: String, CodingKey {
    case excludeTokensStartingWithHash
    case excludeTokensEndingWithHover
    case excludeUtilityGroup
  }
}

extension TokenFilters: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    excludeTokensStartingWithHash = try container.decodeIfPresent(Bool.self, forKey: .excludeTokensStartingWithHash) ?? false
    excludeTokensEndingWithHover = try container.decodeIfPresent(Bool.self, forKey: .excludeTokensEndingWithHover) ?? false
    excludeUtilityGroup = try container.decodeIfPresent(Bool.self, forKey: .excludeUtilityGroup) ?? false
  }
}

extension TokenFilters: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(excludeTokensStartingWithHash, forKey: .excludeTokensStartingWithHash)
    try container.encode(excludeTokensEndingWithHover, forKey: .excludeTokensEndingWithHover)
    try container.encode(excludeUtilityGroup, forKey: .excludeUtilityGroup)
  }
}

extension URL {
  static let tokenFilters = Self.documentsDirectory.appending(component: "token-filters.json")
}

extension SharedKey where Self == FileStorageKey<TokenFilters>.Default {
  static var tokenFilters: Self {
    Self[.fileStorage(.tokenFilters), default: TokenFilters()]
  }
}

// MARK: - Design System Base

extension URL {
  static let designSystemBase = Self.documentsDirectory.appending(component: "design-system-base.json")
}

extension SharedKey where Self == FileStorageKey<DesignSystemBase?>.Default {
  static var designSystemBase: Self {
    Self[.fileStorage(.designSystemBase), default: nil]
  }
}

// MARK: - Analysis Directories

extension URL {
  static let analysisDirectories = Self.documentsDirectory.appending(component: "analysis-directories.json")
}

extension SharedKey where Self == FileStorageKey<[ScanDirectory]>.Default {
  static var analysisDirectories: Self {
    Self[.fileStorage(.analysisDirectories), default: []]
  }
}

// MARK: - App Settings

public struct AppSettings: Equatable, Sendable, Codable {
  public var maxHistoryEntries: Int = 10
  
  public init(maxHistoryEntries: Int = 10) {
    self.maxHistoryEntries = maxHistoryEntries
  }
}

extension URL {
  static let appSettings = Self.documentsDirectory.appending(component: "app-settings.json")
}

extension SharedKey where Self == FileStorageKey<AppSettings>.Default {
  static var appSettings: Self {
    Self[.fileStorage(.appSettings), default: AppSettings()]
  }
}

// MARK: - Onboarding State

public struct OnboardingState: Equatable, Sendable, Codable {
  public var hasCompletedTutorial: Bool = false
  public var tutorialVersion: String = "1.0"
  
  public init(hasCompletedTutorial: Bool = false, tutorialVersion: String = "1.0") {
    self.hasCompletedTutorial = hasCompletedTutorial
    self.tutorialVersion = tutorialVersion
  }
}

extension URL {
  static let onboardingState = Self.documentsDirectory.appending(component: "onboarding-state.json")
}

extension SharedKey where Self == FileStorageKey<OnboardingState>.Default {
  static var onboardingState: Self {
    Self[.fileStorage(.onboardingState), default: OnboardingState()]
  }
}
