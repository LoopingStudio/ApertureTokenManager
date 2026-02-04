import Foundation

// MARK: - Import History Entry

public struct ImportHistoryEntry: Codable, Identifiable, Equatable, Sendable {
  public let id: UUID
  public let date: Date
  public let fileName: String
  public let bookmarkData: Data?
  public let metadata: TokenMetadata?
  
  public init(
    id: UUID = UUID(),
    date: Date = Date(),
    fileName: String,
    bookmarkData: Data?,
    metadata: TokenMetadata?
  ) {
    self.id = id
    self.date = date
    self.fileName = fileName
    self.bookmarkData = bookmarkData
    self.metadata = metadata
  }
  
  /// Resolves the bookmark to get the file URL
  public func resolveURL() -> URL? {
    guard let bookmarkData else { return nil }
    var isStale = false
    return try? URL(
      resolvingBookmarkData: bookmarkData,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &isStale
    )
  }
}

// MARK: - File Snapshot (for history)

public struct FileSnapshot: Codable, Equatable, Sendable {
  public let fileName: String
  public let bookmarkData: Data?
  public let metadata: TokenMetadata?
  
  public init(fileName: String, bookmarkData: Data?, metadata: TokenMetadata?) {
    self.fileName = fileName
    self.bookmarkData = bookmarkData
    self.metadata = metadata
  }
  
  public func resolveURL() -> URL? {
    guard let bookmarkData else { return nil }
    var isStale = false
    return try? URL(
      resolvingBookmarkData: bookmarkData,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &isStale
    )
  }
}

// MARK: - Comparison History Entry

public struct ComparisonHistoryEntry: Codable, Identifiable, Equatable, Sendable {
  public let id: UUID
  public let date: Date
  public let oldFile: FileSnapshot
  public let newFile: FileSnapshot
  public let summary: ComparisonSummary
  
  public init(
    id: UUID = UUID(),
    date: Date = Date(),
    oldFile: FileSnapshot,
    newFile: FileSnapshot,
    summary: ComparisonSummary
  ) {
    self.id = id
    self.date = date
    self.oldFile = oldFile
    self.newFile = newFile
    self.summary = summary
  }
  
  /// Resolves bookmarks to get file URLs
  public func resolveURLs() -> (old: URL?, new: URL?) {
    (oldFile.resolveURL(), newFile.resolveURL())
  }
}

// MARK: - Comparison Summary

public struct ComparisonSummary: Codable, Equatable, Sendable {
  public let addedCount: Int
  public let removedCount: Int
  public let modifiedCount: Int
  
  public var totalChanges: Int {
    addedCount + removedCount + modifiedCount
  }
  
  public init(addedCount: Int, removedCount: Int, modifiedCount: Int) {
    self.addedCount = addedCount
    self.removedCount = removedCount
    self.modifiedCount = modifiedCount
  }
  
  public init(from changes: ComparisonChanges) {
    self.addedCount = changes.added.count
    self.removedCount = changes.removed.count
    self.modifiedCount = changes.modified.count
  }
}
