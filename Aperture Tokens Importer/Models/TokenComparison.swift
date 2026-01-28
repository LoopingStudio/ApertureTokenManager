import Foundation

public struct ComparisonChanges: Equatable, Sendable {
  let added: [TokenSummary]
  let removed: [TokenSummary] 
  let modified: [TokenModification]
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
