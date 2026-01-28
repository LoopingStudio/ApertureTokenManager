import Foundation

// MARK: - Token Export Models

public struct TokenMetadata: Codable, Equatable, Sendable {
  let exportedAt: String
  let timestamp: Int
  let version: String
  let generator: String
}

public struct TokenExport: Codable, Equatable, Sendable {
  let metadata: TokenMetadata
  let tokens: [TokenNode]
}
