import Dependencies
import Foundation

struct HistoryClient {
  // Import history
  var getImportHistory: @Sendable () async -> [ImportHistoryEntry]
  var saveImportEntry: @Sendable (ImportHistoryEntry) async -> Void
  var removeImportEntry: @Sendable (UUID) async -> Void
  var clearImportHistory: @Sendable () async -> Void
  
  // Comparison history
  var getComparisonHistory: @Sendable () async -> [ComparisonHistoryEntry]
  var saveComparisonEntry: @Sendable (ComparisonHistoryEntry) async -> Void
  var removeComparisonEntry: @Sendable (UUID) async -> Void
  var clearComparisonHistory: @Sendable () async -> Void
  
  // Helpers
  var createBookmark: @Sendable (URL) async -> Data?
}

extension HistoryClient: DependencyKey {
  static let liveValue: Self = {
    let service = HistoryService()
    return .init(
      getImportHistory: { await service.getImportHistory() },
      saveImportEntry: { await service.saveImportEntry($0) },
      removeImportEntry: { await service.removeImportEntry($0) },
      clearImportHistory: { await service.clearImportHistory() },
      getComparisonHistory: { await service.getComparisonHistory() },
      saveComparisonEntry: { await service.saveComparisonEntry($0) },
      removeComparisonEntry: { await service.removeComparisonEntry($0) },
      clearComparisonHistory: { await service.clearComparisonHistory() },
      createBookmark: { await service.createBookmark(for: $0) }
    )
  }()
  
  static let testValue: Self = .init(
    getImportHistory: { [] },
    saveImportEntry: { _ in },
    removeImportEntry: { _ in },
    clearImportHistory: { },
    getComparisonHistory: { [] },
    saveComparisonEntry: { _ in },
    removeComparisonEntry: { _ in },
    clearComparisonHistory: { },
    createBookmark: { _ in nil }
  )
}

extension DependencyValues {
  var historyClient: HistoryClient {
    get { self[HistoryClient.self] }
    set { self[HistoryClient.self] = newValue }
  }
}
