import Foundation

/// Helpers for token operations used across Compare views
enum TokenHelpers {
  /// Flattens a hierarchy of tokens into a flat array
  static func flattenTokens(_ tokens: [TokenNode]) -> [TokenNode] {
    var result: [TokenNode] = []

    func flatten(_ nodes: [TokenNode]) {
      for node in nodes {
        if node.type == .token {
          result.append(node)
        }
        if let children = node.children {
          flatten(children)
        }
      }
    }
    flatten(tokens)
    return result
  }

  /// Finds a token by its path in a token hierarchy
  static func findTokenByPath(_ path: String, in tokens: [TokenNode]?) -> TokenNode? {
    guard let tokens = tokens else { return nil }

    func search(_ nodes: [TokenNode]) -> TokenNode? {
      for node in nodes {
        if (node.path ?? node.name) == path {
          return node
        }
        if let children = node.children,
           let found = search(children) {
          return found
        }
      }
      return nil
    }

    return search(tokens)
  }
}
