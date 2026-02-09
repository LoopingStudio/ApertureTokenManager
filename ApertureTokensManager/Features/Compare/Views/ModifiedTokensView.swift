import SwiftUI

struct ModifiedTokensView: View {
  let modifications: [TokenModification]
  let newVersionTokens: [TokenNode]?
  var searchText: String = ""
  
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(modifications) { modification in
          ModifiedTokenListItem(modification: modification, newVersionTokens: newVersionTokens, searchText: searchText)
        }
      }
    }
  }
}

// MARK: - Modified Token List Item

struct ModifiedTokenListItem: View {
  let modification: TokenModification
  let newVersionTokens: [TokenNode]?
  var searchText: String = ""
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      headerSection
      changesSection
    }
    .controlRoundedBackground()
  }
  
  private var headerSection: some View {
    HStack {
      TokenInfoHeader(name: modification.tokenName, path: modification.tokenPath, searchText: searchText)
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
        colorChangeRow(change: change)
      }
    }
  }
  
  private func colorChangeRow(change: ColorChange) -> some View {
    let delta = ColorDeltaCalculator.calculateDelta(oldHex: change.oldColor, newHex: change.newColor)
    
    return HStack(spacing: 8) {
      Text("\(change.brandName) • \(change.theme):")
        .font(.caption)
        .fontWeight(.medium)
        .frame(width: 100, alignment: .leading)
      
      // Ancienne couleur
      HStack(spacing: 4) {
        ColorSquarePreview(color: Color(hex: change.oldColor))
        Text(change.oldColor)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Image(systemName: "arrow.right")
        .font(.caption)
        .foregroundStyle(.secondary)
      
      // Nouvelle couleur
      HStack(spacing: 4) {
        ColorSquarePreview(color: Color(hex: change.newColor))
        Text(change.newColor)
          .font(.caption)
      }
      
      Spacer()
      
      // Delta info
      ColorDeltaBadge(delta: delta)
    }
  }
}

// MARK: - Color Delta Badge

struct ColorDeltaBadge: View {
  let delta: ColorDelta
  @State private var showPopover = false
  
  var body: some View {
    Button {
      showPopover.toggle()
    } label: {
      HStack(spacing: 4) {
        Circle()
          .fill(delta.classification.color)
          .frame(width: 6, height: 6)
        
        Text(delta.classification.rawValue)
          .font(.caption2)
          .foregroundStyle(delta.classification.color)
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(
        Capsule()
          .fill(delta.classification.color.opacity(0.15))
      )
    }
    .buttonStyle(.plain)
    .popover(isPresented: $showPopover) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Détail du changement")
          .font(.headline)
        
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
          deltaRow(label: "Luminosité", value: delta.lightnessDelta, suffix: "%")
          deltaRow(label: "Saturation", value: delta.saturationDelta, suffix: "%")
          deltaRow(label: "Teinte", value: delta.hueDelta, suffix: "°")
        }
        
        Divider()
        
        HStack {
          Text("Impact global:")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Spacer()
          
          Text("\(Int(delta.magnitude))%")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(delta.classification.color)
        }
      }
      .padding()
      .frame(width: 220)
    }
  }
  
  @ViewBuilder
  private func deltaRow(label: String, value: Double, suffix: String) -> some View {
    HStack {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 80, alignment: .leading)
      
      Spacer()
      
      HStack(spacing: 2) {
        if value > 0 {
          Image(systemName: "arrow.up")
            .font(.caption2)
            .foregroundStyle(.orange)
        } else if value < 0 {
          Image(systemName: "arrow.down")
            .font(.caption2)
            .foregroundStyle(.blue)
        }
        
        Text("\(value > 0 ? "+" : "")\(Int(value))\(suffix)")
          .font(.caption)
          .monospacedDigit()
          .foregroundStyle(abs(value) >= 5 ? .primary : .secondary)
      }
    }
  }
}
