import Foundation
import Testing

@testable import ApertureTokensManager

@Suite("Parsing Tests")
struct ParsingTests {
  
  @Test("Parse JSON with new structure")
  func parseNewJSONStructure() throws {
    // Arrange
    let sampleJSON = """
        {
          "metadata": {
            "exportedAt": "2026-02-04T11:52:41.422Z",
            "timestamp": 1770205961422,
            "version": "1.0.0",
            "generator": "Aperture Exporter"
          },
          "tokens": [
            {
              "name": "bg-error-solid",
              "type": "token",
              "path": "Colors/Background/bg-error-solid",
              "modes": {
                "Legacy": {
                  "light": {
                    "hex": "#DC2626",
                    "primitiveName": "UI Colors/Red/600"
                  },
                  "dark": {
                    "hex": "#DC2626", 
                    "primitiveName": "UI Colors/Red/600"
                  }
                },
                "New Brand": {
                  "light": {
                    "hex": "#EF4444",
                    "primitiveName": "UI Colors/Red/500"
                  },
                  "dark": {
                    "hex": "#EF4444",
                    "primitiveName": "UI Colors/Red/500"
                  }
                }
              }
            }
          ]
        }
        """.data(using: .utf8)!

    // Act
    let tokenExport = try JSONDecoder().decode(TokenExport.self, from: sampleJSON)

    // Assert - Metadata
    #expect(tokenExport.metadata.version == "1.0.0")
    #expect(tokenExport.metadata.generator == "Aperture Exporter")

    // Assert - Token
    let token = try #require(tokenExport.tokens.first)
    #expect(token.name == "bg-error-solid")
    #expect(token.type == .token)
    #expect(token.path == "Colors/Background/bg-error-solid")

    // Assert - Modes
    let modes = try #require(token.modes)
    let legacy = try #require(modes.legacy)
    let newBrand = try #require(modes.newBrand)

    // Assert - Legacy
    #expect(legacy.light?.hex == "#DC2626")
    #expect(legacy.light?.primitiveName == "UI Colors/Red/600")
    #expect(legacy.dark?.hex == "#DC2626")
    #expect(legacy.dark?.primitiveName == "UI Colors/Red/600")

    // Assert - New Brand
    #expect(newBrand.light?.hex == "#EF4444")
    #expect(newBrand.light?.primitiveName == "UI Colors/Red/500")
    #expect(newBrand.dark?.hex == "#EF4444")
    #expect(newBrand.dark?.primitiveName == "UI Colors/Red/500")
  }
  
  @Test("Parse JSON with group structure")
  func parseGroupStructure() throws {
    // Arrange
    let sampleJSON = """
        {
          "metadata": {
            "exportedAt": "2026-02-04T11:52:41.422Z",
            "timestamp": 1770205961422,
            "version": "1.0.0",
            "generator": "Aperture Exporter"
          },
          "tokens": [
            {
              "name": "Background",
              "type": "group",
              "path": "Colors/Background",
              "children": [
                {
                  "name": "bg-primary",
                  "type": "token",
                  "path": "Colors/Background/bg-primary",
                  "modes": {
                    "Legacy": {
                      "light": { "hex": "#FFFFFF" },
                      "dark": { "hex": "#000000" }
                    }
                  }
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

    // Act
    let tokenExport = try JSONDecoder().decode(TokenExport.self, from: sampleJSON)

    // Assert
    let group = try #require(tokenExport.tokens.first)
    #expect(group.type == .group)
    #expect(group.name == "Background")
    
    let children = try #require(group.children)
    #expect(children.count == 1)
    
    let childToken = try #require(children.first)
    #expect(childToken.name == "bg-primary")
    #expect(childToken.type == .token)
  }
}
