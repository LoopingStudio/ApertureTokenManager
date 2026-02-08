import Foundation
import Testing
import Dependencies

@testable import ApertureTokensManager

@Suite("Comparison Service Tests")
struct ComparisonServiceTests {
  
  // MARK: - Test Data Helpers
  
  private func makeToken(
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
  
  // MARK: - Compare Tokens Tests
  
  @Suite("Compare Tokens")
  struct CompareTokensTests {
    
    @Test("Returns empty changes for identical token sets")
    func identicalSets() async {
      await withDependencies {
        $0.fileClient = .testValue
      } operation: {
        let service = ComparisonService()
        
        let tokens = [
          TokenNode(name: "token1", type: .token, path: "Colors/token1"),
          TokenNode(name: "token2", type: .token, path: "Colors/token2")
        ]
        
        let changes = await service.compareTokens(oldTokens: tokens, newTokens: tokens)
        
        #expect(changes.added.isEmpty)
        #expect(changes.removed.isEmpty)
        #expect(changes.modified.isEmpty)
      }
    }
    
    @Test("Detects added tokens")
    func detectsAdded() async {
      await withDependencies {
        $0.fileClient = .testValue
      } operation: {
        let service = ComparisonService()
        
        let oldTokens = [
          TokenNode(name: "token1", type: .token, path: "Colors/token1")
        ]
        
        let newTokens = [
          TokenNode(name: "token1", type: .token, path: "Colors/token1"),
          TokenNode(name: "token2", type: .token, path: "Colors/token2")
        ]
        
        let changes = await service.compareTokens(oldTokens: oldTokens, newTokens: newTokens)
        
        #expect(changes.added.count == 1)
        #expect(changes.added.first?.path == "Colors/token2")
        #expect(changes.removed.isEmpty)
      }
    }
    
    @Test("Detects removed tokens")
    func detectsRemoved() async {
      await withDependencies {
        $0.fileClient = .testValue
      } operation: {
        let service = ComparisonService()
        
        let oldTokens = [
          TokenNode(name: "token1", type: .token, path: "Colors/token1"),
          TokenNode(name: "token2", type: .token, path: "Colors/token2")
        ]
        
        let newTokens = [
          TokenNode(name: "token1", type: .token, path: "Colors/token1")
        ]
        
        let changes = await service.compareTokens(oldTokens: oldTokens, newTokens: newTokens)
        
        #expect(changes.removed.count == 1)
        #expect(changes.removed.first?.path == "Colors/token2")
        #expect(changes.added.isEmpty)
      }
    }
    
    @Test("Detects modified tokens - color change")
    func detectsModified() async {
      await withDependencies {
        $0.fileClient = .testValue
      } operation: {
        let service = ComparisonService()
        
        let oldTokens = [
          TokenNode(
            name: "bg-primary",
            type: .token,
            path: "Colors/bg-primary",
            modes: TokenThemes(
              legacy: TokenThemes.Appearance(
                light: TokenValue(hex: "#FF0000", primitiveName: "Red"),
                dark: nil
              ),
              newBrand: nil
            )
          )
        ]
        
        let newTokens = [
          TokenNode(
            name: "bg-primary",
            type: .token,
            path: "Colors/bg-primary",
            modes: TokenThemes(
              legacy: TokenThemes.Appearance(
                light: TokenValue(hex: "#00FF00", primitiveName: "Green"),
                dark: nil
              ),
              newBrand: nil
            )
          )
        ]
        
        let changes = await service.compareTokens(oldTokens: oldTokens, newTokens: newTokens)
        
        #expect(changes.modified.count == 1)
        #expect(changes.modified.first?.tokenPath == "Colors/bg-primary")
        #expect(changes.modified.first?.colorChanges.count == 1)
        #expect(changes.modified.first?.colorChanges.first?.oldColor == "#FF0000")
        #expect(changes.modified.first?.colorChanges.first?.newColor == "#00FF00")
      }
    }
    
    @Test("Handles nested token hierarchies")
    func handlesNestedHierarchies() async {
      await withDependencies {
        $0.fileClient = .testValue
      } operation: {
        let service = ComparisonService()
        
        let oldTokens = [
          TokenNode(
            name: "Colors",
            type: .group,
            path: "Colors",
            children: [
              TokenNode(name: "token1", type: .token, path: "Colors/token1"),
              TokenNode(name: "token2", type: .token, path: "Colors/token2")
            ]
          )
        ]
        
        let newTokens = [
          TokenNode(
            name: "Colors",
            type: .group,
            path: "Colors",
            children: [
              TokenNode(name: "token1", type: .token, path: "Colors/token1"),
              TokenNode(name: "token3", type: .token, path: "Colors/token3")
            ]
          )
        ]
        
        let changes = await service.compareTokens(oldTokens: oldTokens, newTokens: newTokens)
        
        #expect(changes.added.count == 1)
        #expect(changes.added.first?.name == "token3")
        #expect(changes.removed.count == 1)
        #expect(changes.removed.first?.name == "token2")
      }
    }
    
    @Test("Detects multiple color changes in same token")
    func multipleColorChanges() async {
      await withDependencies {
        $0.fileClient = .testValue
      } operation: {
        let service = ComparisonService()
        
        let oldTokens = [
          TokenNode(
            name: "bg-brand",
            type: .token,
            path: "Colors/bg-brand",
            modes: TokenThemes(
              legacy: TokenThemes.Appearance(
                light: TokenValue(hex: "#FF0000", primitiveName: "Red"),
                dark: TokenValue(hex: "#880000", primitiveName: "DarkRed")
              ),
              newBrand: nil
            )
          )
        ]
        
        let newTokens = [
          TokenNode(
            name: "bg-brand",
            type: .token,
            path: "Colors/bg-brand",
            modes: TokenThemes(
              legacy: TokenThemes.Appearance(
                light: TokenValue(hex: "#00FF00", primitiveName: "Green"),
                dark: TokenValue(hex: "#008800", primitiveName: "DarkGreen")
              ),
              newBrand: nil
            )
          )
        ]
        
        let changes = await service.compareTokens(oldTokens: oldTokens, newTokens: newTokens)
        
        #expect(changes.modified.count == 1)
        #expect(changes.modified.first?.colorChanges.count == 2)
      }
    }
  }
  
  // MARK: - Comparison Changes Tests
  
  @Suite("Comparison Changes Model")
  struct ComparisonChangesTests {
    
    @Test("Can add replacement suggestion")
    func addReplacementSuggestion() {
      var changes = ComparisonChanges(added: [], removed: [], modified: [])
      
      changes.addReplacementSuggestion(
        removedTokenPath: "Colors/old-token",
        suggestedTokenPath: "Colors/new-token"
      )
      
      #expect(changes.replacementSuggestions.count == 1)
      #expect(changes.getSuggestion(for: "Colors/old-token")?.suggestedTokenPath == "Colors/new-token")
    }
    
    @Test("Replaces existing suggestion for same token")
    func replacesExistingSuggestion() {
      var changes = ComparisonChanges(added: [], removed: [], modified: [])
      
      changes.addReplacementSuggestion(
        removedTokenPath: "Colors/old-token",
        suggestedTokenPath: "Colors/new-token-1"
      )
      changes.addReplacementSuggestion(
        removedTokenPath: "Colors/old-token",
        suggestedTokenPath: "Colors/new-token-2"
      )
      
      #expect(changes.replacementSuggestions.count == 1)
      #expect(changes.getSuggestion(for: "Colors/old-token")?.suggestedTokenPath == "Colors/new-token-2")
    }
    
    @Test("Can remove replacement suggestion")
    func removeReplacementSuggestion() {
      var changes = ComparisonChanges(added: [], removed: [], modified: [])
      
      changes.addReplacementSuggestion(
        removedTokenPath: "Colors/old-token",
        suggestedTokenPath: "Colors/new-token"
      )
      changes.removeReplacementSuggestion(for: "Colors/old-token")
      
      #expect(changes.replacementSuggestions.isEmpty)
      #expect(changes.getSuggestion(for: "Colors/old-token") == nil)
    }
    
    @Test("Can accept auto suggestion")
    func acceptAutoSuggestion() {
      var changes = ComparisonChanges(added: [], removed: [], modified: [])
      changes.autoSuggestions = [
        AutoSuggestion(
          removedTokenPath: "Colors/old",
          suggestedTokenPath: "Colors/new",
          confidence: 0.85,
          matchFactors: AutoSuggestion.MatchFactors(
            pathSimilarity: 0.9,
            nameSimilarity: 0.8,
            colorSimilarity: 0.95
          )
        )
      ]
      
      changes.acceptAutoSuggestion(for: "Colors/old")
      
      #expect(changes.replacementSuggestions.count == 1)
      #expect(changes.getSuggestion(for: "Colors/old")?.suggestedTokenPath == "Colors/new")
    }
    
    @Test("Can reject auto suggestion")
    func rejectAutoSuggestion() {
      var changes = ComparisonChanges(added: [], removed: [], modified: [])
      changes.autoSuggestions = [
        AutoSuggestion(
          removedTokenPath: "Colors/old",
          suggestedTokenPath: "Colors/new",
          confidence: 0.85,
          matchFactors: AutoSuggestion.MatchFactors(
            pathSimilarity: 0.9,
            nameSimilarity: 0.8,
            colorSimilarity: 0.95
          )
        )
      ]
      
      changes.rejectAutoSuggestion(for: "Colors/old")
      
      #expect(changes.autoSuggestions.isEmpty)
      #expect(changes.getAutoSuggestion(for: "Colors/old") == nil)
    }
  }
}
