import SwiftUI

/// Card d'action interactive avec icône, titre, sous-titre et effet hover
/// Utilisée pour les actions rapides dans le Dashboard et ailleurs
struct ActionCard: View {
  let title: String
  let subtitle: String
  let icon: String
  let color: Color
  let action: () -> Void
  
  @State private var isHovering = false
  @State private var isPressed = false
  @State private var iconBounce = false
  
  var body: some View {
    Button(action: handleButtonTapped) {
      cardContent
    }
    .buttonStyle(.plain)
    .scaleEffect(isPressed ? 0.97 : (isHovering ? 1.01 : 1.0))
    .shadow(color: isHovering ? color.opacity(0.12) : .clear, radius: 6)
    .animation(.easeOut(duration: 0.2), value: isHovering)
    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    .pointerOnHover { hovering in handleHover(hovering) }
  }
  
  @ViewBuilder
  private var cardContent: some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      iconCircle
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
          .foregroundStyle(.primary)
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      chevronIndicator
    }
    .padding(UIConstants.Spacing.medium)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(cardBackground)
  }
  
  @ViewBuilder
  private var iconCircle: some View {
    ZStack {
      Circle()
        .fill(color.opacity(0.15))
        .frame(width: 44, height: 44)
      
      Image(systemName: icon)
        .font(.title3)
        .foregroundStyle(color)
        .scaleEffect(iconBounce ? 1.15 : 1.0)
    }
  }
  
  @ViewBuilder
  private var chevronIndicator: some View {
    Image(systemName: "chevron.right")
      .font(.caption)
      .foregroundStyle(.tertiary)
      .offset(x: isHovering ? 3 : 0)
      .animation(.easeOut(duration: 0.2), value: isHovering)
  }
  
  @ViewBuilder
  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
      .fill(color.opacity(isHovering ? 0.12 : 0.06))
      .overlay(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
          .stroke(color.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1)
      )
  }
  
  private func handleButtonTapped() {
    withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) {
      isPressed = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
        isPressed = false
      }
      action()
    }
  }
  
  private func handleHover(_ hovering: Bool) {
    isHovering = hovering
    guard hovering else { return }
    bounceIcon()
  }
  
  private func bounceIcon() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
      iconBounce = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        iconBounce = false
      }
    }
  }
}

#if DEBUG
#Preview("ActionCard") {
  VStack(spacing: 16) {
    ActionCard(
      title: "Exporter vers Xcode",
      subtitle: "Générer XCAssets + Swift",
      icon: "square.and.arrow.up.fill",
      color: .blue
    ) {
      print("Export tapped")
    }
    
    ActionCard(
      title: "Comparer avec un nouvel import",
      subtitle: "Détecter les changements",
      icon: "doc.text.magnifyingglass",
      color: .green
    ) {
      print("Compare tapped")
    }
  }
  .padding()
  .frame(width: 400)
}
#endif
