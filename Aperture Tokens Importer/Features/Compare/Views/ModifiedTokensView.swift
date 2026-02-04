import SwiftUI

struct ModifiedTokensView: View {
  let modifications: [TokenModification]
  let newVersionTokens: [TokenNode]?
  
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(modifications) { modification in
          ModifiedTokenListItem(modification: modification, newVersionTokens: newVersionTokens)
        }
      }
    }
  }
}

// MARK: - Modified Token List Item

struct ModifiedTokenListItem: View {
  let modification: TokenModification
  let newVersionTokens: [TokenNode]?
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      headerSection
      changesSection
    }
    .controlRoundedBackground()
  }
  
  private var headerSection: some View {
    HStack {
      TokenInfoHeader(name: modification.tokenName, path: modification.tokenPath)
      Spacer()
      if let newToken = TokenHelpers.findTokenByPath(modification.tokenPath, in: newVersionTokens),
         let modes = newToken.modes {
        CompactColorPreview(modes: modes)
      }
      TokenBadge(text: "MODIFIÉ", color: .orange)
    }
  }
  
  private var changesSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(modification.colorChanges) { change in
        ColorChangeRow(change: change)
      }
    }
  }
}
