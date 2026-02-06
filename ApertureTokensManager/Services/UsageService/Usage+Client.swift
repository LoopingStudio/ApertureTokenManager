import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct UsageClient: Sendable {
  /// Analyse l'utilisation des tokens dans les dossiers spécifiés
  var analyzeUsage: @Sendable (
    _ directories: [ScanDirectory],
    _ exportedTokens: [TokenNode],
    _ config: UsageAnalysisConfig,
    _ tokenFilters: TokenFilters
  ) async throws -> TokenUsageReport = { _, _, _, _ in .empty }
}

// MARK: - Dependency Key

extension UsageClient: DependencyKey {
  static let liveValue: Self = {
    let service = UsageService()
    
    return Self(
      analyzeUsage: { directories, tokens, config, tokenFilters in
        try await service.analyzeUsage(
          directories: directories,
          exportedTokens: tokens,
          config: config,
          tokenFilters: tokenFilters
        )
      }
    )
  }()
  
  static let testValue: Self = Self(
    analyzeUsage: { _, _, _, _ in .empty }
  )
  
  static let previewValue: Self = Self(
    analyzeUsage: { _, tokens, _, _ in
      // Générer des données de preview
      let allTokens = flattenTokens(tokens)
      let usedCount = min(allTokens.count / 2, 5)
      let orphanedCount = min(allTokens.count - usedCount, 3)
      
      let usedTokens = allTokens.prefix(usedCount).map { node in
        UsedToken(
          enumCase: TokenUsageHelpers.tokenNameToEnumCase(node.name),
          originalPath: node.path,
          usages: [
            TokenUsage(
              filePath: "/App/Views/ContentView.swift",
              lineNumber: 42,
              lineContent: ".foregroundColor(.bgBrandSolid)",
              matchType: "."
            )
          ]
        )
      }
      
      let orphanedTokens = allTokens.dropFirst(usedCount).prefix(orphanedCount).map { node in
        OrphanedToken(
          enumCase: TokenUsageHelpers.tokenNameToEnumCase(node.name),
          originalPath: node.path
        )
      }
      
      return TokenUsageReport(
        scannedDirectories: [
          ScannedDirectory(
            name: "MyApp",
            url: URL(fileURLWithPath: "/Users/dev/MyApp"),
            bookmarkData: nil,
            filesScanned: 42
          )
        ],
        usedTokens: Array(usedTokens),
        orphanedTokens: Array(orphanedTokens)
      )
    }
  )
  
  private static func flattenTokens(_ nodes: [TokenNode]) -> [TokenNode] {
    var result: [TokenNode] = []
    func collect(_ nodes: [TokenNode]) {
      for node in nodes {
        if node.type == .token {
          result.append(node)
        }
        if let children = node.children {
          collect(children)
        }
      }
    }
    collect(nodes)
    return result
  }
}

// MARK: - Dependency Values

extension DependencyValues {
  var usageClient: UsageClient {
    get { self[UsageClient.self] }
    set { self[UsageClient.self] = newValue }
  }
}
