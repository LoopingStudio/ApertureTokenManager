import Foundation
import Testing

@testable import ApertureTokensManager

@Suite("Token Helpers Tests")
struct TokenHelpersTests {
  
  // MARK: - Test Data Helpers
  
  private func makeToken(name: String, path: String) -> TokenNode {
    TokenNode(name: name, type: .token, path: path)
  }
  
  private func makeGroup(name: String, path: String, children: [TokenNode]) -> TokenNode {
    TokenNode(name: name, type: .group, path: path, children: children)
  }
  
  // MARK: - Flatten Tokens Tests
  
  @Suite("Flatten Tokens")
  struct FlattenTokensTests {
    
    @Test("Returns empty array for empty input")
    func emptyInput() {
      let result = TokenHelpers.flattenTokens([])
      #expect(result.isEmpty)
    }
    
    @Test("Returns tokens from flat list")
    func flatList() {
      let tokens = [
        TokenNode(name: "token1", type: .token, path: "token1"),
        TokenNode(name: "token2", type: .token, path: "token2")
      ]
      
      let result = TokenHelpers.flattenTokens(tokens)
      
      #expect(result.count == 2)
      #expect(result[0].name == "token1")
      #expect(result[1].name == "token2")
    }
    
    @Test("Excludes groups from result")
    func excludesGroups() {
      let tokens = [
        TokenNode(name: "group1", type: .group, path: "group1"),
        TokenNode(name: "token1", type: .token, path: "token1")
      ]
      
      let result = TokenHelpers.flattenTokens(tokens)
      
      #expect(result.count == 1)
      #expect(result[0].name == "token1")
    }
    
    @Test("Flattens nested hierarchy")
    func nestedHierarchy() {
      let tokens = [
        TokenNode(
          name: "Colors",
          type: .group,
          path: "Colors",
          children: [
            TokenNode(
              name: "Background",
              type: .group,
              path: "Colors/Background",
              children: [
                TokenNode(name: "bg-primary", type: .token, path: "Colors/Background/bg-primary"),
                TokenNode(name: "bg-secondary", type: .token, path: "Colors/Background/bg-secondary")
              ]
            ),
            TokenNode(name: "fg-text", type: .token, path: "Colors/fg-text")
          ]
        )
      ]
      
      let result = TokenHelpers.flattenTokens(tokens)
      
      #expect(result.count == 3)
      #expect(result.contains { $0.name == "bg-primary" })
      #expect(result.contains { $0.name == "bg-secondary" })
      #expect(result.contains { $0.name == "fg-text" })
    }
  }
  
  // MARK: - Flatten All Nodes Tests
  
  @Suite("Flatten All Nodes")
  struct FlattenAllNodesTests {
    
    @Test("Returns empty array for empty input")
    func emptyInput() {
      let result = TokenHelpers.flattenAllNodes([])
      #expect(result.isEmpty)
    }
    
    @Test("Includes both groups and tokens")
    func includesGroupsAndTokens() {
      let tokens = [
        TokenNode(
          name: "Colors",
          type: .group,
          path: "Colors",
          children: [
            TokenNode(name: "bg-primary", type: .token, path: "Colors/bg-primary")
          ]
        )
      ]
      
      let result = TokenHelpers.flattenAllNodes(tokens)
      
      #expect(result.count == 2)
      #expect(result.contains { $0.name == "Colors" && $0.type == .group })
      #expect(result.contains { $0.name == "bg-primary" && $0.type == .token })
    }
    
    @Test("Preserves order: parent before children")
    func preservesOrder() {
      let tokens = [
        TokenNode(
          name: "Parent",
          type: .group,
          path: "Parent",
          children: [
            TokenNode(name: "Child", type: .token, path: "Parent/Child")
          ]
        )
      ]
      
      let result = TokenHelpers.flattenAllNodes(tokens)
      
      #expect(result.count == 2)
      #expect(result[0].name == "Parent")
      #expect(result[1].name == "Child")
    }
  }
  
  // MARK: - Count Leaf Tokens Tests
  
  @Suite("Count Leaf Tokens")
  struct CountLeafTokensTests {
    
    @Test("Returns 0 for empty input")
    func emptyInput() {
      let count = TokenHelpers.countLeafTokens([])
      #expect(count == 0)
    }
    
    @Test("Counts tokens in flat list")
    func flatList() {
      let tokens = [
        TokenNode(name: "token1", type: .token, path: "token1"),
        TokenNode(name: "token2", type: .token, path: "token2"),
        TokenNode(name: "token3", type: .token, path: "token3")
      ]
      
      let count = TokenHelpers.countLeafTokens(tokens)
      
      #expect(count == 3)
    }
    
    @Test("Does not count groups")
    func doesNotCountGroups() {
      let tokens = [
        TokenNode(name: "group1", type: .group, path: "group1"),
        TokenNode(name: "group2", type: .group, path: "group2"),
        TokenNode(name: "token1", type: .token, path: "token1")
      ]
      
      let count = TokenHelpers.countLeafTokens(tokens)
      
      #expect(count == 1)
    }
    
    @Test("Counts tokens in nested hierarchy")
    func nestedHierarchy() {
      let tokens = [
        TokenNode(
          name: "Colors",
          type: .group,
          path: "Colors",
          children: [
            TokenNode(
              name: "Background",
              type: .group,
              path: "Colors/Background",
              children: [
                TokenNode(name: "bg-1", type: .token, path: "Colors/Background/bg-1"),
                TokenNode(name: "bg-2", type: .token, path: "Colors/Background/bg-2")
              ]
            ),
            TokenNode(
              name: "Foreground",
              type: .group,
              path: "Colors/Foreground",
              children: [
                TokenNode(name: "fg-1", type: .token, path: "Colors/Foreground/fg-1")
              ]
            )
          ]
        ),
        TokenNode(name: "standalone", type: .token, path: "standalone")
      ]
      
      let count = TokenHelpers.countLeafTokens(tokens)
      
      #expect(count == 4) // bg-1, bg-2, fg-1, standalone
    }
  }
  
  // MARK: - Find Token By Path Tests
  
  @Suite("Find Token By Path")
  struct FindTokenByPathTests {
    
    @Test("Returns nil for nil input")
    func nilInput() {
      let result = TokenHelpers.findTokenByPath("some/path", in: nil)
      #expect(result == nil)
    }
    
    @Test("Returns nil for empty array")
    func emptyArray() {
      let result = TokenHelpers.findTokenByPath("some/path", in: [])
      #expect(result == nil)
    }
    
    @Test("Finds token at root level")
    func findsAtRoot() {
      let tokens = [
        TokenNode(name: "token1", type: .token, path: "Colors/token1"),
        TokenNode(name: "token2", type: .token, path: "Colors/token2")
      ]
      
      let result = TokenHelpers.findTokenByPath("Colors/token2", in: tokens)
      
      #expect(result != nil)
      #expect(result?.name == "token2")
    }
    
    @Test("Finds token in nested hierarchy")
    func findsInNested() {
      let tokens = [
        TokenNode(
          name: "Colors",
          type: .group,
          path: "Colors",
          children: [
            TokenNode(
              name: "Background",
              type: .group,
              path: "Colors/Background",
              children: [
                TokenNode(name: "bg-primary", type: .token, path: "Colors/Background/bg-primary")
              ]
            )
          ]
        )
      ]
      
      let result = TokenHelpers.findTokenByPath("Colors/Background/bg-primary", in: tokens)
      
      #expect(result != nil)
      #expect(result?.name == "bg-primary")
    }
    
    @Test("Returns nil when path not found")
    func notFound() {
      let tokens = [
        TokenNode(name: "token1", type: .token, path: "Colors/token1")
      ]
      
      let result = TokenHelpers.findTokenByPath("Colors/nonexistent", in: tokens)
      
      #expect(result == nil)
    }
    
    @Test("Uses name as fallback when path is nil")
    func usesNameAsFallback() {
      let tokens = [
        TokenNode(name: "token-name", type: .token, path: nil)
      ]
      
      let result = TokenHelpers.findTokenByPath("token-name", in: tokens)
      
      #expect(result != nil)
      #expect(result?.name == "token-name")
    }
  }
}
