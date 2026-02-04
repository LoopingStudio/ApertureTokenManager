import Foundation

public struct ComparisonChanges: Equatable, Sendable {
  let added: [TokenSummary]
  let removed: [TokenSummary] 
  let modified: [TokenModification]
  var replacementSuggestions: [ReplacementSuggestion] = []
  
  // Helper methods
  mutating func addReplacementSuggestion(removedTokenPath: String, suggestedTokenPath: String) {
    // Remove existing suggestion for this token first
    replacementSuggestions.removeAll { $0.removedTokenPath == removedTokenPath }
    // Add new suggestion
    replacementSuggestions.append(ReplacementSuggestion(
      removedTokenPath: removedTokenPath,
      suggestedTokenPath: suggestedTokenPath
    ))
  }
  
  mutating func removeReplacementSuggestion(for removedTokenPath: String) {
    replacementSuggestions.removeAll { $0.removedTokenPath == removedTokenPath }
  }
  
  func getSuggestion(for removedTokenPath: String) -> ReplacementSuggestion? {
    return replacementSuggestions.first { $0.removedTokenPath == removedTokenPath }
  }
}

// Résumé léger d'un token (sans stocker le node complet)
public struct TokenSummary: Equatable, Sendable, Identifiable {
  public let id = UUID()
  let name: String
  let path: String
  let modes: TokenThemes?
  
  init(from node: TokenNode) {
    self.name = node.name
    self.path = node.path ?? node.name
    self.modes = node.modes
  }
}

// Structure pour représenter une suggestion de remplacement
public struct ReplacementSuggestion: Equatable, Sendable, Identifiable {
  public let id = UUID()
  let removedTokenPath: String
  let suggestedTokenPath: String
}

// Structure pour représenter une modification de token (allégée)
public struct TokenModification: Equatable, Sendable, Identifiable {
  public let id = UUID()
  let tokenPath: String
  let tokenName: String
  let colorChanges: [ColorChange]
}

public struct ColorChange: Equatable, Sendable, Identifiable {
  public let id = UUID()
  let brandName: String
  let theme: String
  let oldColor: String
  let newColor: String
}
