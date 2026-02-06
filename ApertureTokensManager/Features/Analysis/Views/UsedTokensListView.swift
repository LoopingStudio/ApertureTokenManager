import SwiftUI

struct UsedTokensListView: View {
  let tokens: [UsedToken]
  let selectedToken: UsedToken?
  let onTokenTapped: (UsedToken?) -> Void
  
  var body: some View {
    HSplitView {
      // Token List
      ScrollView {
        LazyVStack(spacing: 4) {
          ForEach(tokens) { token in
            TokenRow(
              token: token,
              isSelected: selectedToken?.id == token.id,
              onTap: { onTokenTapped(token) }
            )
          }
        }
        .padding(8)
      }
      .frame(minWidth: 300)
      
      // Detail View
      if let selected = selectedToken {
        TokenDetailPanel(token: selected)
          .frame(minWidth: 400)
      } else {
        emptyDetail
          .frame(minWidth: 400)
      }
    }
  }
  
  @ViewBuilder
  private var emptyDetail: some View {
    VStack(spacing: 12) {
      Image(systemName: "doc.text.magnifyingglass")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      
      Text("Sélectionnez un token")
        .font(.headline)
        .foregroundStyle(.secondary)
      
      Text("pour voir ses occurrences")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Token Row

private struct TokenRow: View {
  let token: UsedToken
  let isSelected: Bool
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(token.enumCase)
            .font(.system(.body, design: .monospaced))
            .fontWeight(.medium)
          
          if let path = token.originalPath {
            Text(path)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        
        Spacer()
        
        Text("\(token.usageCount)")
          .font(.system(.caption, design: .rounded, weight: .bold))
          .foregroundStyle(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(usageCountColor)
          .clipShape(Capsule())
      }
      .padding(10)
      .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay {
        if isSelected {
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.accentColor, lineWidth: 2)
        }
      }
    }
    .buttonStyle(.plain)
  }
  
  private var usageCountColor: Color {
    switch token.usageCount {
    case 0...2: return .orange
    case 3...10: return .green
    default: return .blue
    }
  }
}

// MARK: - Token Detail Panel

private struct TokenDetailPanel: View {
  let token: UsedToken
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header
      VStack(alignment: .leading, spacing: 8) {
        Text(token.enumCase)
          .font(.title2)
          .fontWeight(.bold)
          .font(.system(.title2, design: .monospaced))
        
        if let path = token.originalPath {
          Text(path)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        
        HStack {
          Label("\(token.usageCount) occurrences", systemImage: "number")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Spacer()
        }
      }
      .padding()
      .background(Color(.controlBackgroundColor).opacity(0.5))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      
      // Usages List
      Text("Occurrences")
        .font(.headline)
      
      ScrollView {
        LazyVStack(spacing: 8) {
          ForEach(token.usages) { usage in
            UsageRow(usage: usage)
          }
        }
      }
    }
    .padding()
  }
}

// MARK: - Usage Row

private struct UsageRow: View {
  let usage: TokenUsage
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Image(systemName: "doc.text")
          .foregroundStyle(.blue)
        
        Text(fileName)
          .font(.subheadline)
          .fontWeight(.medium)
        
        Text(":\(usage.lineNumber)")
          .font(.caption)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        Text(usage.matchType)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color(.controlBackgroundColor))
          .clipShape(Capsule())
      }
      
      Text(usage.lineContent)
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .truncationMode(.tail)
      
      Text(usage.filePath)
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .padding(10)
    .background(Color(.controlBackgroundColor))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
  
  private var fileName: String {
    URL(fileURLWithPath: usage.filePath).lastPathComponent
  }
}

// MARK: - Preview

#if DEBUG
#Preview {
  UsedTokensListView(
    tokens: [
      UsedToken(
        enumCase: "bgBrandSolid",
        originalPath: "Background/Brand/solid",
        usages: [
          TokenUsage(filePath: "/Users/dev/App/ContentView.swift", lineNumber: 42, lineContent: ".foregroundColor(.bgBrandSolid)", matchType: "."),
          TokenUsage(filePath: "/Users/dev/App/SettingsView.swift", lineNumber: 18, lineContent: "theme.color(.bgBrandSolid)", matchType: "theme.color")
        ]
      ),
      UsedToken(
        enumCase: "fgPrimary",
        originalPath: "Foreground/Primary",
        usages: [
          TokenUsage(filePath: "/Users/dev/App/Components/Button.swift", lineNumber: 10, lineContent: ".fgPrimary", matchType: ".")
        ]
      )
    ],
    selectedToken: nil,
    onTokenTapped: { _ in }
  )
  .frame(width: 800, height: 500)
}
#endif
