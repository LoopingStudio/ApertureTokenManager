import Foundation
import Testing

@testable import ApertureTokensManager

@Suite("Fuzzy Matching Helpers Tests")
struct FuzzyMatchingHelpersTests {
  
  // MARK: - Levenshtein Distance Tests
  
  @Suite("Levenshtein Distance")
  struct LevenshteinTests {
    
    @Test("Identical strings have distance 0")
    func identicalStrings() {
      let distance = FuzzyMatchingHelpers.levenshteinDistance("hello", "hello")
      #expect(distance == 0)
    }
    
    @Test("Empty strings have distance equal to other string length")
    func emptyStrings() {
      #expect(FuzzyMatchingHelpers.levenshteinDistance("", "hello") == 5)
      #expect(FuzzyMatchingHelpers.levenshteinDistance("hello", "") == 5)
      #expect(FuzzyMatchingHelpers.levenshteinDistance("", "") == 0)
    }
    
    @Test("Single character difference")
    func singleCharDifference() {
      #expect(FuzzyMatchingHelpers.levenshteinDistance("cat", "bat") == 1)
      #expect(FuzzyMatchingHelpers.levenshteinDistance("cat", "cart") == 1)
      #expect(FuzzyMatchingHelpers.levenshteinDistance("cat", "ca") == 1)
    }
    
    @Test("Case insensitive comparison")
    func caseInsensitive() {
      #expect(FuzzyMatchingHelpers.levenshteinDistance("Hello", "hello") == 0)
      #expect(FuzzyMatchingHelpers.levenshteinDistance("WORLD", "world") == 0)
    }
    
    @Test("Similarity returns value between 0 and 1")
    func similarityRange() {
      let similarity = FuzzyMatchingHelpers.levenshteinSimilarity("background", "foreground")
      #expect(similarity >= 0.0 && similarity <= 1.0)
    }
    
    @Test("Identical strings have similarity 1.0")
    func identicalSimilarity() {
      let similarity = FuzzyMatchingHelpers.levenshteinSimilarity("token", "token")
      #expect(similarity == 1.0)
    }
  }
  
  // MARK: - Hex Color Similarity Tests
  
  @Suite("Hex Color Similarity")
  struct ColorSimilarityTests {
    
    @Test("Identical colors have similarity 1.0")
    func identicalColors() {
      let similarity = FuzzyMatchingHelpers.hexColorSimilarity("#FF0000", "#FF0000")
      #expect(similarity == 1.0)
    }
    
    @Test("Black and white have low similarity")
    func blackAndWhite() {
      let similarity = FuzzyMatchingHelpers.hexColorSimilarity("#000000", "#FFFFFF")
      #expect(similarity < 0.1)
    }
    
    @Test("Similar shades have high similarity")
    func similarShades() {
      // Red 500 vs Red 600 - similar but not identical
      let similarity = FuzzyMatchingHelpers.hexColorSimilarity("#EF4444", "#DC2626")
      #expect(similarity > 0.85, "Similar red shades should have similarity > 0.85, got \(similarity)")
    }
    
    @Test("Different colors have low similarity")
    func differentColors() {
      // Red vs Blue
      let similarity = FuzzyMatchingHelpers.hexColorSimilarity("#FF0000", "#0000FF")
      #expect(similarity < 0.5)
    }
    
    @Test("Handles hex with or without hash")
    func hexWithoutHash() {
      let withHash = FuzzyMatchingHelpers.hexColorSimilarity("#FF0000", "#FF0000")
      let withoutHash = FuzzyMatchingHelpers.hexColorSimilarity("FF0000", "FF0000")
      #expect(withHash == withoutHash)
    }
  }
  
  // MARK: - Path Similarity Tests
  
  @Suite("Path Similarity")
  struct PathSimilarityTests {
    
    @Test("Identical paths have high similarity")
    func identicalPaths() {
      let similarity = FuzzyMatchingHelpers.computePathSimilarity(
        "Colors/Background/Surface/Default",
        "Colors/Background/Surface/Default"
      )
      #expect(similarity == 1.0)
    }
    
    @Test("Similar paths have high similarity")
    func similarPaths() {
      let similarity = FuzzyMatchingHelpers.computePathSimilarity(
        "Colors/Background/Surface/Default",
        "Colors/Background/Surface/Primary"
      )
      #expect(similarity > 0.8)
    }
    
    @Test("Different category paths have lower similarity")
    func differentCategories() {
      let similarity = FuzzyMatchingHelpers.computePathSimilarity(
        "Colors/Background/Surface/Default",
        "Colors/Foreground/Text/Default"
      )
      // Still shares "Colors" and "Default", so similarity is moderate
      #expect(similarity < 0.8, "Different categories should have similarity < 0.8, got \(similarity)")
    }
    
    @Test("Empty paths return 0")
    func emptyPaths() {
      #expect(FuzzyMatchingHelpers.computePathSimilarity("", "Colors/Test") == 0.0)
      #expect(FuzzyMatchingHelpers.computePathSimilarity("Colors/Test", "") == 0.0)
    }
  }
  
  // MARK: - Name Similarity Tests
  
  @Suite("Name Similarity")
  struct NameSimilarityTests {
    
    @Test("Identical names return 1.0")
    func identicalNames() {
      let similarity = FuzzyMatchingHelpers.computeNameSimilarity("bg-primary", "bg-primary")
      #expect(similarity == 1.0)
    }
    
    @Test("Case insensitive match returns 1.0")
    func caseInsensitiveMatch() {
      let similarity = FuzzyMatchingHelpers.computeNameSimilarity("BG-Primary", "bg-primary")
      #expect(similarity == 1.0)
    }
    
    @Test("Normalized names with legacy prefix match")
    func normalizedWithPrefix() {
      // "legacy-bg-primary" normalized becomes "bg-primary"
      let similarity = FuzzyMatchingHelpers.computeNameSimilarity("legacy-bg-primary", "bg-primary")
      #expect(similarity >= 0.9)
    }
    
    @Test("Similar names have high similarity")
    func similarNames() {
      let similarity = FuzzyMatchingHelpers.computeNameSimilarity("bg-brand-solid", "bg-brand-subtle")
      // Names share "bg-brand-" prefix, difference is "solid" vs "subtle"
      #expect(similarity > 0.6, "Similar names should have similarity > 0.6, got \(similarity)")
    }
  }
  
  // MARK: - Usage Context Similarity Tests
  
  @Suite("Usage Context Similarity")
  struct UsageContextTests {
    
    @Test("Same usage context has high similarity")
    func sameContext() {
      // Both are background tokens
      let similarity = FuzzyMatchingHelpers.computeUsageContextSimilarity(
        "Colors/Background", "bg-surface",
        "Colors/Background", "bg-primary"
      )
      #expect(similarity > 0.5)
    }
    
    @Test("Different contexts have lower similarity")
    func differentContexts() {
      // Background vs Foreground
      let similarity = FuzzyMatchingHelpers.computeUsageContextSimilarity(
        "Colors/Background", "bg-surface",
        "Colors/Foreground", "fg-text"
      )
      #expect(similarity < 0.5)
    }
    
    @Test("Hover states match")
    func hoverStates() {
      let similarity = FuzzyMatchingHelpers.computeUsageContextSimilarity(
        "Colors/Button", "btn-hover",
        "Colors/Button", "btn-hovered"
      )
      #expect(similarity > 0.5)
    }
    
    @Test("Solid variants match")
    func solidVariants() {
      let similarity = FuzzyMatchingHelpers.computeUsageContextSimilarity(
        "Colors/Brand", "bg-brand-solid",
        "Colors/Brand", "fg-brand-solid"
      )
      // Both have "solid" context
      #expect(similarity > 0.3)
    }
  }
  
  // MARK: - Structure Similarity Tests
  
  @Suite("Structure Similarity")
  struct StructureSimilarityTests {
    
    @Test("Same parent structure has high similarity")
    func sameParent() {
      let similarity = FuzzyMatchingHelpers.computeStructureSimilarity(
        "Colors/Background/Surface/Token1",
        "Colors/Background/Surface/Token2"
      )
      #expect(similarity == 1.0)
    }
    
    @Test("Different parents have lower similarity")
    func differentParents() {
      let similarity = FuzzyMatchingHelpers.computeStructureSimilarity(
        "Colors/Background/Surface/Token",
        "Colors/Foreground/Text/Token"
      )
      #expect(similarity < 0.5)
    }
    
    @Test("Root level tokens have similarity 1.0")
    func rootLevel() {
      let similarity = FuzzyMatchingHelpers.computeStructureSimilarity(
        "Token1",
        "Token2"
      )
      #expect(similarity == 1.0)
    }
  }
}
