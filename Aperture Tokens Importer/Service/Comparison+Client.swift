import Foundation
import ComposableArchitecture

struct ComparisonClient {
  var compareTokens: @Sendable ([TokenNode], [TokenNode]) async -> ComparisonChanges
  var exportToNotion: @Sendable (
    _ changes: ComparisonChanges,
    _ oldMetadata: TokenMetadata,
    _ newMetadata: TokenMetadata
  ) async throws -> Void
}

extension ComparisonClient: DependencyKey {
  static let liveValue: Self = {
    let service = ComparisonService()
    return .init(
      compareTokens: { await service.compareTokens(oldTokens: $0, newTokens: $1) },
      exportToNotion: { try await service.exportToNotion($0, oldMetadata: $1, newMetadata: $2) }
    )
  }()
}

extension DependencyValues {
  var comparisonClient: ComparisonClient {
    get { self[ComparisonClient.self] }
    set { self[ComparisonClient.self] = newValue }
  }
}
