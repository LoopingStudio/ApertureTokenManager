import AppKit
import ComposableArchitecture
import Foundation

struct TokenClient {
  var loadJSON: @Sendable (_ url: URL) async throws -> TokenExport
  var exportDesignSystem: @Sendable ([TokenNode]) async throws -> Void
  var pickFile: @Sendable () async throws -> URL?
  var handleFileDrop: (NSItemProvider) async -> URL?
}

extension DependencyValues {
  var tokenClient: TokenClient {
    get { self[TokenClient.self] }
    set { self[TokenClient.self] = newValue }
  }
}

extension TokenClient: DependencyKey {
  static let liveValue: Self = {
    let service = TokenService()
    return .init(
      loadJSON: { try await service.loadTokenExport(from: $0) },
      exportDesignSystem: { try await service.exportDesignSystem($0) },
      pickFile: { try await service.pickFile() },
      handleFileDrop: { await service.handleFileDrop(provider: $0) }
    )
  }()
}
