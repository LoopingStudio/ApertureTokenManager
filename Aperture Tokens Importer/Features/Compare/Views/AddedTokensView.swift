import SwiftUI

struct AddedTokensView: View {
  let tokens: [TokenSummary]

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(tokens) { token in
          AddedTokenListItem(token: token)
        }
      }
    }
  }
}

// MARK: - Added Token List Item

struct AddedTokenListItem: View {
  let token: TokenSummary

  var body: some View {
    HStack(spacing: 12) {
      TokenInfoHeader(name: token.name, path: token.path)
      Spacer()
      if let modes = token.modes {
        CompactColorPreview(modes: modes)
      }
      TokenBadge(text: "AJOUTÉ", color: .green)
    }
    .controlRoundedBackground()
  }
}
