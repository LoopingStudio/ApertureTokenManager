import SwiftUI

struct RemovedTokensView: View {
  let tokens: [TokenSummary]
  let changes: ComparisonChanges?
  let newVersionTokens: [TokenNode]?
  let onSuggestReplacement: (String, String?) -> Void
  
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(tokens) { token in
          RemovedTokenListItem(
            token: token,
            changes: changes,
            newVersionTokens: newVersionTokens,
            onSuggestReplacement: onSuggestReplacement
          )
        }
      }
    }
  }
}

// MARK: - Removed Token List Item

struct RemovedTokenListItem: View {
  let token: TokenSummary
  let changes: ComparisonChanges?
  let newVersionTokens: [TokenNode]?
  let onSuggestReplacement: (String, String?) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        TokenInfoHeader(name: token.name, path: token.path)

        ReplacementSection(
          removedToken: token,
          changes: changes,
          newVersionTokens: newVersionTokens,
          onSuggestReplacement: onSuggestReplacement
        )
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 8) {
        if let modes = token.modes {
          VStack(alignment: .trailing, spacing: 4) {
            Text("Couleurs supprimées")
              .font(.caption2)
              .foregroundStyle(.secondary)
            CompactColorPreview(modes: modes)
          }
        }

        if let suggestion = changes?.getSuggestion(for: token.path),
           let suggestedToken = TokenHelpers.findTokenByPath(suggestion.suggestedTokenPath, in: newVersionTokens),
           let modes = suggestedToken.modes {

          VStack(alignment: .trailing, spacing: 4) {
            Text("Nouvelles couleurs")
              .font(.caption2)
              .foregroundStyle(.green)
              .fontWeight(.medium)

            CompactColorPreview(modes: modes, shouldShowLabels: false)
          }
          .padding(.top, 6)
        }
      }

      TokenBadge(text: "SUPPRIMÉ", color: .red)
    }
    .controlRoundedBackground()
  }
}

// MARK: - Replacement Section

struct ReplacementSection: View {
  let removedToken: TokenSummary
  let changes: ComparisonChanges?
  let newVersionTokens: [TokenNode]?
  let onSuggestReplacement: (String, String?) -> Void
  
  var body: some View {
    HStack(spacing: 6) {
      if let suggestion = changes?.getSuggestion(for: removedToken.path) {
        existingSuggestionView(suggestion: suggestion)
      } else {
        suggestionMenuView
      }
    }
  }
  
  private func existingSuggestionView(suggestion: ReplacementSuggestion) -> some View {
    HStack(spacing: 4) {
      Text("→")
        .font(.caption2)
        .foregroundStyle(.secondary)
      
      Text(suggestion.suggestedTokenPath)
        .font(.caption)
        .foregroundStyle(.green)
        .lineLimit(1)
      
      Button("×") {
        onSuggestReplacement(removedToken.path, nil)
      }
      .font(.caption2)
      .foregroundStyle(.red)
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(.green.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 4))
  }
  
  @ViewBuilder
  private var suggestionMenuView: some View {
    if let newTokens = newVersionTokens {
      let allNewTokens = TokenHelpers.flattenTokens(newTokens)
      
      Menu {
        ForEach(allNewTokens, id: \.path) { newToken in
          Button(newToken.name) {
            onSuggestReplacement(
              removedToken.path,
              newToken.path ?? newToken.name
            )
          }
        }
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "plus")
          Text("Suggérer")
        }
        .font(.caption)
        .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(.blue.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 4))
    }
  }
}
