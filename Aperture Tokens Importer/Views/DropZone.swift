import SwiftUI
import UniformTypeIdentifiers

struct DropZone: View {
  let title: String
  let subtitle: String
  let isLoaded: Bool
  let isLoading: Bool
  let hasError: Bool
  let errorMessage: String?
  let primaryColor: Color
  let onDrop: ([NSItemProvider]) -> Bool
  let onSelectFile: () -> Void
  let onRemove: (() -> Void)?
  let metadata: TokenMetadata?
  
  @State private var isHovering = false
  
  init(
    title: String,
    subtitle: String,
    isLoaded: Bool = false,
    isLoading: Bool = false,
    hasError: Bool = false,
    errorMessage: String? = nil,
    primaryColor: Color = .blue,
    onDrop: @escaping ([NSItemProvider]) -> Bool,
    onSelectFile: @escaping () -> Void,
    onRemove: (() -> Void)? = nil,
    metadata: TokenMetadata? = nil
  ) {
    self.title = title
    self.subtitle = subtitle
    self.isLoaded = isLoaded
    self.isLoading = isLoading
    self.hasError = hasError
    self.errorMessage = errorMessage
    self.primaryColor = primaryColor
    self.onDrop = onDrop
    self.onSelectFile = onSelectFile
    self.onRemove = onRemove
    self.metadata = metadata
  }
  
  var body: some View {
    VStack(spacing: 16) {
      VStack(spacing: 12) {
        iconView
        
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
        
        statusView
        
        if let metadata = metadata {
          metadataView(metadata)
        }
      }
      
      if !isLoaded && !isLoading {
        Button("Sélectionner fichier") {
          onSelectFile()
        }
        .controlSize(.small)
      }
      
      if isLoaded, let onRemove = onRemove {
        Button("Supprimer") {
          onRemove()
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
      }
    }
    .frame(maxWidth: .infinity, minHeight: 200)
    .padding()
    .background(backgroundView)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovering = hovering
      }
      if hovering && !isLoaded {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
    .onTapGesture {
      if !isLoaded {
        onSelectFile()
      }
    }
    .onDrop(of: [UTType.json], isTargeted: nil) { providers in
      onDrop(providers)
    }
  }
  
  @ViewBuilder
  private var iconView: some View {
    if isLoading {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle())
        .scaleEffect(1.2)
    } else if hasError {
      Image(systemName: "exclamationmark.circle.fill")
        .font(.largeTitle)
        .foregroundStyle(.red)
    } else if isLoaded {
      Image(systemName: "checkmark.circle.fill")
        .font(.largeTitle)
        .foregroundStyle(.green)
    } else {
      Image(systemName: "doc.text")
        .font(.largeTitle)
        .foregroundStyle(primaryColor)
    }
  }
  
  @ViewBuilder
  private var statusView: some View {
    if isLoading {
      Text("Chargement en cours...")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else if hasError {
      VStack(spacing: 4) {
        Text("Erreur de chargement")
          .font(.caption)
          .foregroundStyle(.red)
        
        if let errorMessage = errorMessage {
          Text(errorMessage)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
    } else if isLoaded {
      Text("Fichier chargé")
        .font(.caption)
        .foregroundStyle(.green)
    } else {
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }
  
  private func metadataView(_ metadata: TokenMetadata) -> some View {
    VStack(spacing: 2) {
      Text("Exporté le")
        .font(.caption2)
        .foregroundStyle(.tertiary)
      
      Text(metadata.exportedAt.formatFrenchDate)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      Text("Version \(metadata.version)")
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Capsule()
        .fill(Color.secondary.opacity(0.1))
    )
  }
  
  @ViewBuilder
  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(backgroundColor)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(borderColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
      )
  }
  
  private var backgroundColor: Color {
    if hasError {
      return Color.red.opacity(0.1)
    } else if isLoaded {
      return Color.green.opacity(0.1)
    } else if isHovering {
      return primaryColor.opacity(0.15)
    } else {
      return primaryColor.opacity(0.1)
    }
  }
  
  private var borderColor: Color {
    if hasError {
      return .red
    } else if isLoaded {
      return .green
    } else if isHovering {
      return primaryColor
    } else {
      return primaryColor.opacity(0.6)
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    // État normal
    DropZone(
      title: "Fichier de tokens",
      subtitle: "Glissez votre fichier JSON ici",
      primaryColor: .purple,
      onDrop: { _ in true },
      onSelectFile: { }
    )
    
    // État chargé avec métadonnées
    DropZone(
      title: "Ancienne Version",
      subtitle: "Fichier chargé",
      isLoaded: true,
      primaryColor: .blue,
      onDrop: { _ in true },
      onSelectFile: { },
      metadata: TokenMetadata(
        exportedAt: "2026-01-28 14:30:00",
        timestamp: 1738068600,
        version: "1.2.3",
        generator: "Figma"
      )
    )
    
    // État d'erreur
    DropZone(
      title: "Nouvelle Version",
      subtitle: "Glissez le fichier ici",
      hasError: true,
      errorMessage: "Format de fichier invalide",
      primaryColor: .blue,
      onDrop: { _ in true },
      onSelectFile: { }
    )
    
    // État de chargement
    DropZone(
      title: "Fichier en cours",
      subtitle: "Traitement...",
      isLoading: true,
      primaryColor: .green,
      onDrop: { _ in true },
      onSelectFile: { }
    )
  }
  .padding()
  .frame(width: 400)
}
