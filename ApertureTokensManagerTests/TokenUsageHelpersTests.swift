import Foundation
import Testing

@testable import ApertureTokensManager

@Suite("Token Usage Helpers Tests")
struct TokenUsageHelpersTests {
  
  // MARK: - Token Name Conversion Tests
  
  @Suite("Token Name to Enum Case")
  struct NameConversionTests {
    
    @Test("Converts kebab-case to camelCase")
    func kebabToCamel() {
      #expect(TokenUsageHelpers.tokenNameToEnumCase("bg-brand-solid") == "bgBrandSolid")
      #expect(TokenUsageHelpers.tokenNameToEnumCase("fg-text-primary") == "fgTextPrimary")
    }
    
    @Test("Converts snake_case to camelCase")
    func snakeToCamel() {
      #expect(TokenUsageHelpers.tokenNameToEnumCase("bg_brand_solid") == "bgBrandSolid")
    }
    
    @Test("Single word stays lowercase")
    func singleWord() {
      #expect(TokenUsageHelpers.tokenNameToEnumCase("primary") == "primary")
    }
    
    @Test("Empty string returns unknown")
    func emptyString() {
      #expect(TokenUsageHelpers.tokenNameToEnumCase("") == "unknown")
    }
    
    @Test("Mixed separators work correctly")
    func mixedSeparators() {
      #expect(TokenUsageHelpers.tokenNameToEnumCase("bg-brand_solid") == "bgBrandSolid")
    }
  }
  
  // MARK: - Path to Enum Case Tests
  
  @Suite("Path to Enum Case")
  struct PathConversionTests {
    
    @Test("Extracts last component and converts")
    func extractsLastComponent() {
      #expect(TokenUsageHelpers.pathToEnumCase("Colors/Background/bg-primary") == "bgPrimary")
    }
    
    @Test("Handles single component path")
    func singleComponent() {
      #expect(TokenUsageHelpers.pathToEnumCase("bg-primary") == "bgPrimary")
    }
  }
  
  // MARK: - Find Token Usages Tests
  
  @Suite("Find Token Usages")
  struct FindUsagesTests {
    
    let knownTokens: Set<String> = ["bgPrimary", "fgText", "borderDefault", "bgBrandSolid"]
    
    @Test("Finds dot prefix usage")
    func findsDotPrefix() {
      let content = """
      let color = .bgPrimary
      """
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: "Test.swift",
        knownTokens: knownTokens
      )
      
      #expect(matches.count == 1)
      #expect(matches.first?.tokenEnumCase == "bgPrimary")
      #expect(matches.first?.matchType == .dotPrefix)
    }
    
    @Test("Finds fully qualified Color usage")
    func findsFullyQualified() {
      let content = """
      let color = Color.bgPrimary
      """
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: "Test.swift",
        knownTokens: knownTokens
      )
      
      #expect(matches.count >= 1)
      #expect(matches.contains { $0.tokenEnumCase == "bgPrimary" })
    }
    
    @Test("Finds theme.color usage")
    func findsThemeColor() {
      let content = """
      view.backgroundColor = theme.color(.bgPrimary)
      """
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: "Test.swift",
        knownTokens: knownTokens
      )
      
      #expect(matches.count >= 1)
      #expect(matches.contains { $0.tokenEnumCase == "bgPrimary" })
    }
    
    @Test("Ignores comment lines")
    func ignoresComments() {
      let content = """
      // let color = .bgPrimary
      /* let color = .fgText */
      * .borderDefault
      """
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: "Test.swift",
        knownTokens: knownTokens
      )
      
      #expect(matches.isEmpty)
    }
    
    @Test("Only matches known tokens")
    func onlyMatchesKnown() {
      let content = """
      let color = .unknownToken
      let other = .bgPrimary
      """
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: "Test.swift",
        knownTokens: knownTokens
      )
      
      #expect(matches.count == 1)
      #expect(matches.first?.tokenEnumCase == "bgPrimary")
    }
    
    @Test("Returns correct line numbers")
    func correctLineNumbers() {
      let content = """
      let a = 1
      let b = 2
      let color = .bgPrimary
      let c = 3
      """
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: "Test.swift",
        knownTokens: knownTokens
      )
      
      #expect(matches.first?.lineNumber == 3)
    }
    
    @Test("Finds multiple usages in same file")
    func multipleUsages() {
      let content = """
      let bg = .bgPrimary
      let fg = .fgText
      let border = .borderDefault
      """
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: "Test.swift",
        knownTokens: knownTokens
      )
      
      #expect(matches.count == 3)
    }
    
    @Test("Captures line content trimmed")
    func capturesLineContent() {
      let content = """
          let color = .bgPrimary  
      """
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: "Test.swift",
        knownTokens: knownTokens
      )
      
      #expect(matches.first?.lineContent == "let color = .bgPrimary")
    }
  }
  
  // MARK: - Usage Match Type Tests
  
  @Suite("Usage Match Types")
  struct MatchTypeTests {
    
    @Test("MatchType raw values are correct")
    func matchTypeRawValues() {
      #expect(TokenUsageHelpers.UsageMatch.MatchType.dotPrefix.rawValue == ".")
      #expect(TokenUsageHelpers.UsageMatch.MatchType.fullyQualified.rawValue == "Color.")
      #expect(TokenUsageHelpers.UsageMatch.MatchType.themeColor.rawValue == "theme.color")
    }
  }
}
