import SwiftUI

// MARK: - Token Badge

struct TokenBadge: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color)
      .clipShape(RoundedRectangle(cornerRadius: 4))
  }
}

// MARK: - Color Square Preview

struct ColorSquarePreview: View {
  let color: Color
  let size: CGFloat

  init(color: Color, size: CGFloat = 20) {
    self.color = color
    self.size = size
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(color)
      .frame(width: size, height: size)
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
      )
  }
}

// MARK: - Color Square With Popover

struct ColorSquareWithPopover: View {
  let value: TokenValue
  let label: String
  @State private var showPopover = false

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(Color(hex: value.hex))
      .frame(width: 20, height: 20)
      .overlay(
        Text(label)
          .font(.caption2)
          .fontWeight(.bold)
          .foregroundStyle(.white)
          .shadow(color: .black, radius: 1, x: 0, y: 0)
      )
      .onTapGesture {
        showPopover.toggle()
      }
      .popover(isPresented: $showPopover, arrowEdge: .top) {
        ColorDetailPopover(value: value)
      }
  }
}

// MARK: - Color Detail Popover

struct ColorDetailPopover: View {
  let value: TokenValue

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Détails de la couleur")
        .font(.headline)
        .fontWeight(.semibold)

      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 6)
          .fill(Color(hex: value.hex))
          .frame(width: 50, height: 50)
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
          )

        VStack(alignment: .leading, spacing: 6) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Hex")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            Text(value.hex)
              .font(.body)
              .fontWeight(.medium)
              .textSelection(.enabled)
          }

          VStack(alignment: .leading, spacing: 2) {
            Text("Primitive")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            Text(value.primitiveName)
              .font(.caption)
              .fontWeight(.medium)
              .textSelection(.enabled)
          }
        }
        Spacer()
      }
    }
    .padding()
    .frame(width: 320)
  }
}

// MARK: - Compact Color Preview (4 colors grid)

struct CompactColorPreview: View {
  let modes: TokenThemes
  let shouldShowLabels: Bool

  init(modes: TokenThemes, shouldShowLabels: Bool = true) {
    self.modes = modes
    self.shouldShowLabels = shouldShowLabels
  }

  var body: some View {
    HStack(spacing: 6) {
      // Legacy colors
      if let legacy = modes.legacy {
        VStack(spacing: 3) {
          Text("Legacy")
            .font(.caption2)
            .foregroundStyle(.secondary)

          HStack(spacing: 3) {
            if let light = legacy.light {
              ColorSquareWithPopover(value: light, label: "L")
            }
            if let dark = legacy.dark {
              ColorSquareWithPopover(value: dark, label: "D")
            }
          }
        }
      }

      // New Brand colors
      if let newBrand = modes.newBrand {
        VStack(spacing: 3) {
          Text("New Brand")
            .font(.caption2)
            .foregroundStyle(.secondary)

          HStack(spacing: 3) {
            if let light = newBrand.light {
              ColorSquareWithPopover(value: light, label: "L")
            }
            if let dark = newBrand.dark {
              ColorSquareWithPopover(value: dark, label: "D")
            }
          }
        }
      }
    }
  }
}

extension View {
  func controlRoundedBackground() -> some View {
    self
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(nsColor: .controlBackgroundColor))
      )
  }
}

// MARK: - Token Info Header

struct TokenInfoHeader: View {
  let name: String
  let path: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(name)
        .font(.subheadline)
        .fontWeight(.medium)

      Text(path)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Summary Card

struct SummaryCard: View {
  let title: String
  let count: Int
  let color: Color
  let icon: String
  let onTap: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.largeTitle)
        .foregroundStyle(color)

      Text("\(count)")
        .font(.title)
        .fontWeight(.bold)
        .foregroundStyle(color)

      Text(title)
        .font(.headline)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, minHeight: 120)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(0.3), lineWidth: 1)
        )
    )
    .onTapGesture { onTap() }
  }
}

// MARK: - File Info Card

struct FileInfoCard: View {
  let title: String
  let metadata: TokenMetadata?
  let color: Color

  var body: some View {
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
}

// MARK: - Color Change Row

struct ColorChangeRow: View {
  let change: ColorChange

  var body: some View {
    HStack(spacing: 8) {
      Text("\(change.brandName) • \(change.theme):")
        .font(.caption)
        .fontWeight(.medium)
        .frame(width: 100, alignment: .leading)

      // Ancienne couleur
      HStack(spacing: 4) {
        ColorSquarePreview(color: Color(hex: change.oldColor))
        Text(change.oldColor)
          .font(.caption)
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
    }
  }
}
