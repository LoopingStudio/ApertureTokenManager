import Foundation

actor HistoryService {
  private let defaults = UserDefaults.standard
  private let importHistoryKey = "importHistory"
  private let comparisonHistoryKey = "comparisonHistory"
  private let maxHistoryEntries = 10
  
  // MARK: - Import History
  
  func getImportHistory() -> [ImportHistoryEntry] {
    guard let data = defaults.data(forKey: importHistoryKey) else { return [] }
    let entries = (try? JSONDecoder().decode([ImportHistoryEntry].self, from: data)) ?? []
    return cleanupInvalidEntries(entries)
  }
  
  func saveImportEntry(_ entry: ImportHistoryEntry) {
    var history = getImportHistory()
    
    // Remove duplicate if same file
    history.removeAll { $0.fileName == entry.fileName }
    
    // Add new entry at the beginning
    history.insert(entry, at: 0)
    
    // Keep only max entries
    if history.count > maxHistoryEntries {
      history = Array(history.prefix(maxHistoryEntries))
    }
    
    saveImportHistory(history)
  }
  
  func removeImportEntry(_ id: UUID) {
    var history = getImportHistory()
    history.removeAll { $0.id == id }
    saveImportHistory(history)
  }
  
  func clearImportHistory() {
    defaults.removeObject(forKey: importHistoryKey)
  }
  
  private func saveImportHistory(_ history: [ImportHistoryEntry]) {
    if let data = try? JSONEncoder().encode(history) {
      defaults.set(data, forKey: importHistoryKey)
    }
  }
  
  private func cleanupInvalidEntries(_ entries: [ImportHistoryEntry]) -> [ImportHistoryEntry] {
    entries.filter { entry in
      // Keep entries that can still resolve their URL
      entry.resolveURL() != nil
    }
  }
  
  // MARK: - Comparison History
  
  func getComparisonHistory() -> [ComparisonHistoryEntry] {
    guard let data = defaults.data(forKey: comparisonHistoryKey) else { return [] }
    let entries = (try? JSONDecoder().decode([ComparisonHistoryEntry].self, from: data)) ?? []
    return cleanupInvalidComparisonEntries(entries)
  }
  
  func saveComparisonEntry(_ entry: ComparisonHistoryEntry) {
    var history = getComparisonHistory()
    
    // Remove duplicate if same files
    history.removeAll {
      $0.oldFile.fileName == entry.oldFile.fileName && $0.newFile.fileName == entry.newFile.fileName
    }
    
    // Add new entry at the beginning
    history.insert(entry, at: 0)
    
    // Keep only max entries
    if history.count > maxHistoryEntries {
      history = Array(history.prefix(maxHistoryEntries))
    }
    
    saveComparisonHistory(history)
  }
  
  func removeComparisonEntry(_ id: UUID) {
    var history = getComparisonHistory()
    history.removeAll { $0.id == id }
    saveComparisonHistory(history)
  }
  
  func clearComparisonHistory() {
    defaults.removeObject(forKey: comparisonHistoryKey)
  }
  
  private func saveComparisonHistory(_ history: [ComparisonHistoryEntry]) {
    if let data = try? JSONEncoder().encode(history) {
      defaults.set(data, forKey: comparisonHistoryKey)
    }
  }
  
  private func cleanupInvalidComparisonEntries(_ entries: [ComparisonHistoryEntry]) -> [ComparisonHistoryEntry] {
    entries.filter { entry in
      let urls = entry.resolveURLs()
      return urls.old != nil || urls.new != nil
    }
  }
  
  // MARK: - Bookmark Creation
  
  func createBookmark(for url: URL) -> Data? {
    try? url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
  }
}
