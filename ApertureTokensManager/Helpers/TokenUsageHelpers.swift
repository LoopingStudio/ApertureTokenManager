import Foundation

/// Helpers pour analyser l'utilisation des tokens dans les fichiers Swift
enum TokenUsageHelpers {
  
  // MARK: - Token Name Conversion
  
  /// Convertit un nom de token (ex: "bg-brand-solid") en case enum (ex: "bgBrandSolid")
  static func tokenNameToEnumCase(_ name: String) -> String {
    let cleanName = name
      .replacingOccurrences(of: "-", with: " ")
      .replacingOccurrences(of: "_", with: " ")
    
    let components = cleanName.split(separator: " ")
    guard !components.isEmpty else { return "unknown" }
    
    let firstComponent = String(components[0]).lowercased()
    let otherComponents = components.dropFirst().map { String($0).capitalized }
    
    return firstComponent + otherComponents.joined()
  }
  
  /// Convertit un path complet (ex: "Background/Brand/solid") en case enum (ex: "bgBrandSolid")
  static func pathToEnumCase(_ path: String) -> String {
    // Extraire le dernier composant du path
    let name = path.split(separator: "/").last.map(String.init) ?? path
    return tokenNameToEnumCase(name)
  }
  
  // MARK: - Swift File Parsing
  
  /// Patterns de recherche pour les usages de tokens
  enum UsagePattern {
    /// Pattern pour `.tokenName` (shorthand)
    static let dotPrefix = #"\.([a-z][a-zA-Z0-9]*)"#
    
    /// Pattern pour `Color.tokenName` ou `Aperture.Foundations.Color.tokenName`
    static let fullyQualified = #"(?:Aperture\.Foundations\.)?Color\.([a-z][a-zA-Z0-9]*)"#
    
    /// Pattern pour `theme.color(.tokenName)`
    static let themeColor = #"\.color\(\s*\.([a-z][a-zA-Z0-9]*)\s*\)"#
  }
  
  /// Résultat d'une recherche d'usage
  struct UsageMatch: Equatable, Sendable {
    let tokenEnumCase: String
    let filePath: String
    let lineNumber: Int
    let lineContent: String
    let matchType: MatchType
    
    enum MatchType: String, Equatable, Sendable {
      case dotPrefix = "."
      case fullyQualified = "Color."
      case themeColor = "theme.color"
    }
  }
  
  /// Recherche tous les usages de tokens dans un contenu Swift
  static func findTokenUsages(
    in content: String,
    filePath: String,
    knownTokens: Set<String>
  ) -> [UsageMatch] {
    var matches: [UsageMatch] = []
    let lines = content.components(separatedBy: .newlines)
    
    for (index, line) in lines.enumerated() {
      let lineNumber = index + 1
      
      // Ignorer les commentaires
      let trimmedLine = line.trimmingCharacters(in: .whitespaces)
      if trimmedLine.hasPrefix("//") || trimmedLine.hasPrefix("/*") || trimmedLine.hasPrefix("*") {
        continue
      }
      
      // Chercher les patterns
      matches.append(contentsOf: findPatternMatches(
        pattern: UsagePattern.themeColor,
        in: line,
        filePath: filePath,
        lineNumber: lineNumber,
        matchType: .themeColor,
        knownTokens: knownTokens
      ))
      
      matches.append(contentsOf: findPatternMatches(
        pattern: UsagePattern.fullyQualified,
        in: line,
        filePath: filePath,
        lineNumber: lineNumber,
        matchType: .fullyQualified,
        knownTokens: knownTokens
      ))
      
      // Pour le dot prefix, on vérifie seulement si c'est un token connu
      matches.append(contentsOf: findDotPrefixMatches(
        in: line,
        filePath: filePath,
        lineNumber: lineNumber,
        knownTokens: knownTokens
      ))
    }
    
    return matches
  }
  
  private static func findPatternMatches(
    pattern: String,
    in line: String,
    filePath: String,
    lineNumber: Int,
    matchType: UsageMatch.MatchType,
    knownTokens: Set<String>
  ) -> [UsageMatch] {
    var matches: [UsageMatch] = []
    
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
      return []
    }
    
    let range = NSRange(line.startIndex..., in: line)
    let results = regex.matches(in: line, options: [], range: range)
    
    for result in results {
      guard result.numberOfRanges >= 2,
            let tokenRange = Range(result.range(at: 1), in: line) else {
        continue
      }
      
      let tokenName = String(line[tokenRange])
      
      // Vérifier si c'est un token connu
      if knownTokens.contains(tokenName) {
        matches.append(UsageMatch(
          tokenEnumCase: tokenName,
          filePath: filePath,
          lineNumber: lineNumber,
          lineContent: line.trimmingCharacters(in: .whitespaces),
          matchType: matchType
        ))
      }
    }
    
    return matches
  }
  
  private static func findDotPrefixMatches(
    in line: String,
    filePath: String,
    lineNumber: Int,
    knownTokens: Set<String>
  ) -> [UsageMatch] {
    var matches: [UsageMatch] = []
    
    // Pattern plus restrictif pour éviter les faux positifs
    // On cherche `.tokenName` suivi de `)`, `,`, ` `, ou fin de ligne
    guard let regex = try? NSRegularExpression(
      pattern: #"\.([a-z][a-zA-Z0-9]*)(?=[\s,\)\]]|$)"#,
      options: []
    ) else {
      return []
    }
    
    let range = NSRange(line.startIndex..., in: line)
    let results = regex.matches(in: line, options: [], range: range)
    
    for result in results {
      guard result.numberOfRanges >= 2,
            let tokenRange = Range(result.range(at: 1), in: line) else {
        continue
      }
      
      let tokenName = String(line[tokenRange])
      
      // Vérifier si c'est un token connu (évite les faux positifs)
      if knownTokens.contains(tokenName) {
        // Vérifier qu'on n'a pas déjà trouvé ce match via un autre pattern
        let alreadyFound = matches.contains { $0.tokenEnumCase == tokenName && $0.lineNumber == lineNumber }
        if !alreadyFound {
          matches.append(UsageMatch(
            tokenEnumCase: tokenName,
            filePath: filePath,
            lineNumber: lineNumber,
            lineContent: line.trimmingCharacters(in: .whitespaces),
            matchType: .dotPrefix
          ))
        }
      }
    }
    
    return matches
  }
  
  // MARK: - File System Helpers
  
  /// Trouve tous les fichiers Swift dans un dossier (récursif)
  static func findSwiftFiles(in directory: URL) throws -> [URL] {
    let fileManager = FileManager.default
    var swiftFiles: [URL] = []
    
    guard let enumerator = fileManager.enumerator(
      at: directory,
      includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
      options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) else {
      return []
    }
    
    for case let fileURL as URL in enumerator {
      // Ignorer certains dossiers
      let lastComponent = fileURL.lastPathComponent
      if lastComponent == "DerivedData" || 
         lastComponent == ".build" ||
         lastComponent == "Pods" ||
         lastComponent == "Carthage" ||
         lastComponent.hasSuffix(".xcodeproj") ||
         lastComponent.hasSuffix(".xcworkspace") {
        enumerator.skipDescendants()
        continue
      }
      
      // Collecter les fichiers .swift
      if fileURL.pathExtension == "swift" {
        swiftFiles.append(fileURL)
      }
    }
    
    return swiftFiles
  }
}
