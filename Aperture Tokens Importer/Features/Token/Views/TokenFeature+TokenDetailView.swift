import SwiftUI

struct TokenDetailView: View {
  let node: TokenNode
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(node.name)
          .font(.title2)
          .fontWeight(.semibold)
        
        HStack {
          Image(systemName: node.type == .group ? "folder.fill" : "paintbrush.fill")
            .foregroundStyle(node.type == .group ? .blue : .purple)
          Text(node.type == .group ? "Dossier" : "Token")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        if let path = node.path {
          Text("Chemin: \(path)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      
      if node.type == .group {
        // Affichage des tokens enfants pour un groupe
        let childTokens = getAllChildTokens(from: node)
        if !childTokens.isEmpty {
          ScrollView {
            VStack(alignment: .leading, spacing: 12) {
              Text("Tokens (\(childTokens.count))")
                .font(.headline)
                .fontWeight(.medium)
              
              LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(childTokens) { token in
                  tokenRow(token: token)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                      RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                    )
                }
              }
            }
          }
        } else {
          Text("Aucun token dans ce groupe")
            .foregroundStyle(.secondary)
            .italic()
        }
      } else if let modes = node.modes {
        // Affichage des thèmes pour un token individuel
        VStack(alignment: .leading, spacing: 12) {
          Text("Themes")
            .font(.headline)
            .fontWeight(.medium)
          
          HStack(spacing: 12) {
            if let legacy = modes.legacy {
              brandTheme(brandName: Brand.legacy, theme: legacy)
            }
            
            if let newBrand = modes.newBrand {
              brandTheme(brandName: Brand.newBrand, theme: newBrand)
            }
          }
        }
      }
      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
  
  // Fonction pour collecter récursivement tous les tokens enfants
  private func getAllChildTokens(from node: TokenNode) -> [TokenNode] {
    var tokens: [TokenNode] = []
    
    if let children = node.children {
      for child in children {
        if child.type == .token {
          tokens.append(child)
        } else if child.type == .group {
          tokens.append(contentsOf: getAllChildTokens(from: child))
        }
      }
    }
    return tokens
  }
  
  // Vue pour afficher un token dans la liste
  private func tokenRow(token: TokenNode) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(token.name)
          .font(.subheadline)
          .fontWeight(.medium)
        
        if let path = token.path {
          Text(path)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
      
      if let modes = token.modes {
        HStack(spacing: 6) {
          if let legacy = modes.legacy {
            colorPreview(color: Color(hex: legacy.light), size: 24)
          }
          if let newBrand = modes.newBrand {
            colorPreview(color: Color(hex: newBrand.light), size: 24)
          }
        }
      }
    }
  }

  private func colorPreview(color: Color, size: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(color)
      .frame(width: size, height: size)
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
      }
  }

  private func brandTheme(brandName: String, theme: TokenThemes.Appearance) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(brandName)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.primary)

      HStack(spacing: 4) {
        themeSquare(color: Color(hex: theme.light), label: "Light")
        themeSquare(color: Color(hex: theme.dark), label: "Dark")
      }
    }
  }

  private func themeSquare(color: Color, label: String) -> some View {
    VStack(spacing: 2) {
      RoundedRectangle(cornerRadius: 8)
        .fill(color)
        .frame(width: 64, height: 64)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.secondary.opacity(0.3), lineWidth: 1.0)
        )
        .shadow(radius: 1)

      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }
}
