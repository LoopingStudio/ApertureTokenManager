import Foundation
import Testing

@testable import ApertureTokensManager

@Suite("Suggestion Service Tests")
struct SuggestionServiceTests {
  
  // MARK: - Test Helpers
  
  /// Crée un TokenNode avec des couleurs pour les tests
  private func makeTokenNode(
    name: String,
    path: String,
    legacyLight: String? = nil,
    legacyDark: String? = nil,
    newBrandLight: String? = nil,
    newBrandDark: String? = nil
  ) -> TokenNode {
    let legacy: TokenThemes.Appearance? = if legacyLight != nil || legacyDark != nil {
      TokenThemes.Appearance(
        light: legacyLight.map { TokenValue(hex: $0, primitiveName: "test") },
        dark: legacyDark.map { TokenValue(hex: $0, primitiveName: "test") }
      )
    } else {
      nil
    }
    
    let newBrand: TokenThemes.Appearance? = if newBrandLight != nil || newBrandDark != nil {
      TokenThemes.Appearance(
        light: newBrandLight.map { TokenValue(hex: $0, primitiveName: "test") },
        dark: newBrandDark.map { TokenValue(hex: $0, primitiveName: "test") }
      )
    } else {
      nil
    }
    
    let modes: TokenThemes? = if legacy != nil || newBrand != nil {
      TokenThemes(legacy: legacy, newBrand: newBrand)
    } else {
      nil
    }
    
    return TokenNode(
      name: name,
      type: .token,
      path: path,
      modes: modes
    )
  }
  
  /// Crée un TokenSummary à partir d'un TokenNode
  private func makeSummary(from node: TokenNode) -> TokenSummary {
    TokenSummary(from: node)
  }
  
  // MARK: - Basic Suggestion Tests
  
  @Suite("Compute Suggestions")
  struct ComputeSuggestionsTests {
    
    @Test("Returns empty array when no removed tokens")
    func emptyRemovedTokens() async {
      // Arrange
      let service = SuggestionService()
      let added = [
        TokenSummary(from: TokenNode(name: "bg-primary", type: .token, path: "Colors/bg-primary"))
      ]
      
      // Act
      let suggestions = await service.computeSuggestions(removedTokens: [], addedTokens: added)
      
      // Assert
      #expect(suggestions.isEmpty)
    }
    
    @Test("Returns empty array when no added tokens")
    func emptyAddedTokens() async {
      // Arrange
      let service = SuggestionService()
      let removed = [
        TokenSummary(from: TokenNode(name: "bg-old", type: .token, path: "Colors/bg-old"))
      ]
      
      // Act
      let suggestions = await service.computeSuggestions(removedTokens: removed, addedTokens: [])
      
      // Assert
      #expect(suggestions.isEmpty)
    }
    
    @Test("Finds suggestion for similar token")
    func findsSimilarToken() async {
      // Arrange
      let service = SuggestionService()
      
      let removedNode = TokenNode(
        name: "bg-brand-solid",
        type: .token,
        path: "Colors/Background/bg-brand-solid",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#3B82F6", primitiveName: "Blue/500"),
            dark: TokenValue(hex: "#3B82F6", primitiveName: "Blue/500")
          ),
          newBrand: nil
        )
      )
      
      let addedNode = TokenNode(
        name: "bg-brand-primary",
        type: .token,
        path: "Colors/Background/bg-brand-primary",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#3B82F6", primitiveName: "Blue/500"),
            dark: TokenValue(hex: "#3B82F6", primitiveName: "Blue/500")
          ),
          newBrand: nil
        )
      )
      
      let removed = [TokenSummary(from: removedNode)]
      let added = [TokenSummary(from: addedNode)]
      
      // Act
      let suggestions = await service.computeSuggestions(removedTokens: removed, addedTokens: added)
      
      // Assert
      #expect(suggestions.count == 1)
      #expect(suggestions.first?.removedTokenPath == "Colors/Background/bg-brand-solid")
      #expect(suggestions.first?.suggestedTokenPath == "Colors/Background/bg-brand-primary")
    }
  }
  
  // MARK: - Confidence Score Tests
  
  @Suite("Confidence Scores")
  struct ConfidenceScoreTests {
    
    @Test("Identical colors produce high confidence")
    func identicalColorsHighConfidence() async {
      // Arrange
      let service = SuggestionService()
      
      let removedNode = TokenNode(
        name: "old-token",
        type: .token,
        path: "Colors/Background/old-token",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#FF0000", primitiveName: "Red"),
            dark: TokenValue(hex: "#FF0000", primitiveName: "Red")
          ),
          newBrand: nil
        )
      )
      
      let addedNode = TokenNode(
        name: "new-token",
        type: .token,
        path: "Colors/Background/new-token",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#FF0000", primitiveName: "Red"),
            dark: TokenValue(hex: "#FF0000", primitiveName: "Red")
          ),
          newBrand: nil
        )
      )
      
      let removed = [TokenSummary(from: removedNode)]
      let added = [TokenSummary(from: addedNode)]
      
      // Act
      let suggestions = await service.computeSuggestions(removedTokens: removed, addedTokens: added)
      
      // Assert
      #expect(suggestions.count == 1)
      #expect(suggestions.first!.confidence > 0.7)
      #expect(suggestions.first!.matchFactors.colorSimilarity == 1.0)
    }
    
    @Test("Different colors produce lower confidence")
    func differentColorsLowerConfidence() async {
      // Arrange
      let service = SuggestionService()
      
      let removedNode = TokenNode(
        name: "bg-red",
        type: .token,
        path: "Colors/Background/bg-red",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#FF0000", primitiveName: "Red"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      let addedNode = TokenNode(
        name: "bg-blue",
        type: .token,
        path: "Colors/Background/bg-blue",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#0000FF", primitiveName: "Blue"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      let removed = [TokenSummary(from: removedNode)]
      let added = [TokenSummary(from: addedNode)]
      
      // Act
      let suggestions = await service.computeSuggestions(removedTokens: removed, addedTokens: added)
      
      // Assert
      // May or may not have suggestion depending on threshold
      if let suggestion = suggestions.first {
        #expect(suggestion.matchFactors.colorSimilarity < 0.5)
      }
    }
    
    @Test("Confidence is between 0 and 1")
    func confidenceInRange() async {
      // Arrange
      let service = SuggestionService()
      
      let removedNode = TokenNode(
        name: "token-a",
        type: .token,
        path: "Colors/token-a",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#AABBCC", primitiveName: "Test"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      let addedNode = TokenNode(
        name: "token-b",
        type: .token,
        path: "Colors/token-b",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#AABBDD", primitiveName: "Test"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      let removed = [TokenSummary(from: removedNode)]
      let added = [TokenSummary(from: addedNode)]
      
      // Act
      let suggestions = await service.computeSuggestions(removedTokens: removed, addedTokens: added)
      
      // Assert
      for suggestion in suggestions {
        #expect(suggestion.confidence >= 0.0 && suggestion.confidence <= 1.0)
        #expect(suggestion.matchFactors.colorSimilarity >= 0.0 && suggestion.matchFactors.colorSimilarity <= 1.0)
        #expect(suggestion.matchFactors.nameSimilarity >= 0.0 && suggestion.matchFactors.nameSimilarity <= 1.0)
        #expect(suggestion.matchFactors.pathSimilarity >= 0.0 && suggestion.matchFactors.pathSimilarity <= 1.0)
      }
    }
  }
  
  // MARK: - Best Match Selection Tests
  
  @Suite("Best Match Selection")
  struct BestMatchTests {
    
    @Test("Selects best match among multiple candidates")
    func selectsBestMatch() async {
      // Arrange
      let service = SuggestionService()
      
      let removedNode = TokenNode(
        name: "bg-brand-solid",
        type: .token,
        path: "Colors/Background/bg-brand-solid",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#3B82F6", primitiveName: "Blue/500"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      // Candidate 1: Same color, similar path
      let goodMatch = TokenNode(
        name: "bg-brand-primary",
        type: .token,
        path: "Colors/Background/bg-brand-primary",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#3B82F6", primitiveName: "Blue/500"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      // Candidate 2: Different color, different path
      let poorMatch = TokenNode(
        name: "fg-text-error",
        type: .token,
        path: "Colors/Foreground/fg-text-error",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#EF4444", primitiveName: "Red/500"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      let removed = [TokenSummary(from: removedNode)]
      let added = [TokenSummary(from: goodMatch), TokenSummary(from: poorMatch)]
      
      // Act
      let suggestions = await service.computeSuggestions(removedTokens: removed, addedTokens: added)
      
      // Assert
      #expect(suggestions.count == 1)
      #expect(suggestions.first?.suggestedTokenPath == "Colors/Background/bg-brand-primary")
    }
  }
  
  // MARK: - Configuration Tests
  
  @Suite("Custom Configuration")
  struct ConfigurationTests {
    
    @Test("Custom threshold filters low confidence matches")
    func customThresholdFilters() async {
      // Arrange
      let config = SuggestionMatchingConfig(
        minimumConfidenceThreshold: 0.9, // Very high threshold
        colorWeight: 0.5,
        usageContextWeight: 0.3,
        structureWeight: 0.2
      )
      let service = SuggestionService(config: config)
      
      let removedNode = TokenNode(
        name: "old-token",
        type: .token,
        path: "Colors/old-token",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#FF0000", primitiveName: "Red"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      let addedNode = TokenNode(
        name: "different-token",
        type: .token,
        path: "Other/different-token",
        modes: TokenThemes(
          legacy: TokenThemes.Appearance(
            light: TokenValue(hex: "#00FF00", primitiveName: "Green"),
            dark: nil
          ),
          newBrand: nil
        )
      )
      
      let removed = [TokenSummary(from: removedNode)]
      let added = [TokenSummary(from: addedNode)]
      
      // Act
      let suggestions = await service.computeSuggestions(removedTokens: removed, addedTokens: added)
      
      // Assert - High threshold should filter out poor matches
      #expect(suggestions.isEmpty)
    }
    
    @Test("Default config values are correct")
    func defaultConfigValues() {
      let config = SuggestionMatchingConfig.default
      
      #expect(config.minimumConfidenceThreshold == 0.35)
      #expect(config.colorWeight == 0.50)
      #expect(config.usageContextWeight == 0.30)
      #expect(config.structureWeight == 0.20)
      
      // Weights should sum to 1.0
      let totalWeight = config.colorWeight + config.usageContextWeight + config.structureWeight
      #expect(totalWeight == 1.0)
    }
  }
}
