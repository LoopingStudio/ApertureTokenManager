import SwiftUI

struct OverviewView: View {
  let changes: ComparisonChanges
  let oldFileMetadata: TokenMetadata?
  let newFileMetadata: TokenMetadata?
  let onTabTapped: (CompareFeature.ComparisonTab) -> Void
  
  @State private var showTitle = false
  @State private var showFileInfo = false
  @State private var showCards = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Résumé des changements")
        .font(.title2)
        .fontWeight(.semibold)
        .opacity(showTitle ? 1 : 0)
        .offset(y: showTitle ? 0 : -10)
      
      fileInfoSection
        .opacity(showFileInfo ? 1 : 0)
        .offset(y: showFileInfo ? 0 : 15)
      
      summaryCardsGrid
        .opacity(showCards ? 1 : 0)
        .offset(y: showCards ? 0 : 20)
      
      Spacer()
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.3)) {
        showTitle = true
      }
      withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
        showFileInfo = true
      }
      withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
        showCards = true
      }
    }
  }
  
  // MARK: - File Info Section
  
  private var fileInfoSection: some View {
    HStack(spacing: 20) {
      fileInfoCard(title: "Ancienne Version", metadata: oldFileMetadata, color: .blue)
      
      Image(systemName: "arrow.right")
        .font(.title2)
        .foregroundStyle(.secondary)
      
      fileInfoCard(title: "Nouvelle Version", metadata: newFileMetadata, color: .green)
    }
    .padding(.bottom, 8)
  }
  
  private func fileInfoCard(title: String, metadata: TokenMetadata?, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .foregroundStyle(color)
      
      if let metadata = metadata {
        VStack(alignment: .leading, spacing: 4) {
          Text("Exporté le: \(formatFrenchDate(metadata.exportedAt))")
            .font(.caption)
            .foregroundStyle(.primary)
          
          Text("Version: \(metadata.version)")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text("Générateur: \(metadata.generator)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      } else {
        Text("Pas de métadonnées")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(color.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(color.opacity(0.3), lineWidth: 1)
        )
    )
  }
  
  private func formatFrenchDate(_ dateString: String) -> String {
    let inputFormatter = DateFormatter()
    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "fr_FR")
    outputFormatter.dateStyle = .medium
    outputFormatter.timeStyle = .short
    
    let formats = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      "yyyy-MM-dd"
    ]
    
    for format in formats {
      inputFormatter.dateFormat = format
      if let date = inputFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
      }
    }
    
    return dateString
  }
  
  // MARK: - Summary Cards
  
  private var summaryCardsGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
      SummaryCard(
        title: "Tokens Ajoutés",
        count: changes.added.count,
        color: .green,
        icon: "plus.circle.fill",
        index: 0,
        onTap: { onTabTapped(.added) }
      )
      SummaryCard(
        title: "Tokens Supprimés",
        count: changes.removed.count,
        color: .red,
        icon: "minus.circle.fill",
        index: 1,
        onTap: { onTabTapped(.removed) }
      )
      SummaryCard(
        title: "Tokens Modifiés",
        count: changes.modified.count,
        color: .orange,
        icon: "pencil.circle.fill",
        index: 2,
        onTap: { onTabTapped(.modified) }
      )
    }
  }
}

// MARK: - Summary Card

private struct SummaryCard: View {
  let title: String
  let count: Int
  let color: Color
  let icon: String
  let index: Int
  let onTap: () -> Void
  
  @State private var isVisible = false
  @State private var isHovering = false
  @State private var isPressed = false
  @State private var iconBounce = false
  
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.largeTitle)
        .foregroundStyle(color)
        .scaleEffect(iconBounce ? 1.15 : 1.0)
        .rotationEffect(.degrees(iconBounce ? -5 : 0))
      
      Text("\(count)")
        .font(.title)
        .fontWeight(.bold)
        .foregroundStyle(color)
        .contentTransition(.numericText())
      
      Text(title)
        .font(.headline)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, minHeight: 120)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(isHovering ? 0.15 : 0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(isHovering ? 0.5 : 0.3), lineWidth: isHovering ? 2 : 1)
        )
        .shadow(color: isHovering ? color.opacity(0.2) : .clear, radius: 8)
    )
    .scaleEffect(isPressed ? 0.96 : (isHovering ? 1.03 : 1.0))
    .opacity(isVisible ? 1 : 0)
    .offset(y: isVisible ? 0 : 15)
    .animation(.easeOut(duration: 0.2), value: isHovering)
    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    .onHover { hovering in
      isHovering = hovering
      if hovering {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
          iconBounce = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            iconBounce = false
          }
        }
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
    .onTapGesture {
      withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) {
        isPressed = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
          isPressed = false
        }
        onTap()
      }
    }
    .onAppear {
      let delay = Double(index) * 0.08
      withAnimation(.easeOut(duration: 0.35).delay(delay)) {
        isVisible = true
      }
    }
  }
}
