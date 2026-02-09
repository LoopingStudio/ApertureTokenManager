import SwiftUI

struct AddedTokensView: View {
  let tokens: [TokenSummary]
  var searchText: String = ""

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(tokens) { token in
          AddedTokenListItem(token: token, searchText: searchText)
        }
      }
    }
  }
}

// MARK: - Added Token List Item

struct AddedTokenListItem: View {
  let token: TokenSummary
  var searchText: String = ""

  var body: some View {
    HStack(spacing: 12) {
      TokenInfoHeader(name: token.name, path: token.path, searchText: searchText)
      Spacer()
      if let modes = token.modes {
        CompactColorPreview(modes: modes)
      }
      TokenBadge(text: "AJOUTÉ", color: .green)
    }
    .controlRoundedBackground()
  }
}
