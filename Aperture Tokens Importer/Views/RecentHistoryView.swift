import SwiftUI

// MARK: - Import History View

struct ImportHistoryView: View {
  let history: [ImportHistoryEntry]
  let onEntryTapped: (ImportHistoryEntry) -> Void
  let onRemove: (UUID) -> Void
  let onClear: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Imports récents", systemImage: "clock.arrow.circlepath")
          .font(.headline)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        if !history.isEmpty {
          Button("Effacer") { onClear() }
            .font(.caption)
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
        }
      }
      
      if history.isEmpty {
        Text("Aucun import récent")
          .font(.caption)
          .foregroundStyle(.tertiary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)
      } else {
        ScrollView {
          VStack(spacing: 6) {
            ForEach(history) { entry in
              ImportHistoryRow(
                entry: entry,
                onTap: { onEntryTapped(entry) },
                onRemove: { onRemove(entry.id) }
              )
            }
          }
        }
        .frame(maxHeight: 180)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
  }
}

// MARK: - Import History Row

struct ImportHistoryRow: View {
  let entry: ImportHistoryEntry
  let onTap: () -> Void
  let onRemove: () -> Void
  @State private var isHovering = false
  
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "doc.fill")
        .font(.title3)
        .foregroundStyle(.purple)
      
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(entry.fileName)
            .font(.subheadline)
            .fontWeight(.medium)
            .lineLimit(1)
          
          if let exportDate = entry.metadata?.exportedAt {
            Text("(\(exportDate.toShortDate()))")
              .font(.caption2)
              .foregroundStyle(.purple.opacity(0.8))
          }
        }
        
        HStack(spacing: 8) {
          Label(entry.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
            .font(.caption2)
            .foregroundStyle(.secondary)
          
          if let metadata = entry.metadata {
            Text("v\(metadata.version)")
              .font(.caption2)
              .foregroundStyle(.tertiary)
          }
        }
      }
      
      Spacer()
      
      if isHovering {
        Button {
          onRemove()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .transition(.opacity)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
    )
    .contentShape(Rectangle())
    .onTapGesture { onTap() }
    .onHover { isHovering = $0 }
  }
}

// MARK: - Comparison History View

struct ComparisonHistoryView: View {
  let history: [ComparisonHistoryEntry]
  let onEntryTapped: (ComparisonHistoryEntry) -> Void
  let onRemove: (UUID) -> Void
  let onClear: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Comparaisons récentes", systemImage: "clock.arrow.circlepath")
          .font(.headline)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        if !history.isEmpty {
          Button("Effacer") { onClear() }
            .font(.caption)
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
        }
      }
      
      if history.isEmpty {
        Text("Aucune comparaison récente")
          .font(.caption)
          .foregroundStyle(.tertiary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)
      } else {
        ScrollView {
          VStack(spacing: 6) {
            ForEach(history) { entry in
              ComparisonHistoryRow(
                entry: entry,
                onTap: { onEntryTapped(entry) },
                onRemove: { onRemove(entry.id) }
              )
            }
          }
        }
        .frame(maxHeight: 200)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
  }
}

// MARK: - Comparison History Row

struct ComparisonHistoryRow: View {
  let entry: ComparisonHistoryEntry
  let onTap: () -> Void
  let onRemove: () -> Void
  @State private var isHovering = false
  
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "doc.text.magnifyingglass")
        .font(.title3)
        .foregroundStyle(.blue)
      
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
          fileVersionLabel(entry.oldFile, color: .blue)
          Image(systemName: "arrow.right")
            .font(.caption2)
            .foregroundStyle(.secondary)
          fileVersionLabel(entry.newFile, color: .green)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        
        HStack(spacing: 8) {
          Label(entry.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
            .font(.caption2)
            .foregroundStyle(.secondary)
          
          summaryBadges
        }
      }
      
      Spacer()
      
      if isHovering {
        Button {
          onRemove()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .transition(.opacity)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
    )
    .contentShape(Rectangle())
    .onTapGesture { onTap() }
    .onHover { isHovering = $0 }
  }
  
  private var summaryBadges: some View {
    HStack(spacing: 4) {
      if entry.summary.addedCount > 0 {
        summaryBadge(count: entry.summary.addedCount, color: .green)
      }
      if entry.summary.removedCount > 0 {
        summaryBadge(count: entry.summary.removedCount, color: .red)
      }
      if entry.summary.modifiedCount > 0 {
        summaryBadge(count: entry.summary.modifiedCount, color: .orange)
      }
    }
  }
  
  private func summaryBadge(count: Int, color: Color) -> some View {
    Text("+\(count)")
      .font(.caption2)
      .fontWeight(.medium)
      .foregroundStyle(color)
      .padding(.horizontal, 4)
      .padding(.vertical, 1)
      .background(color.opacity(0.15))
      .clipShape(RoundedRectangle(cornerRadius: 3))
  }
  
  private func fileVersionLabel(_ file: FileSnapshot, color: Color) -> some View {
    HStack(spacing: 4) {
      Text(file.fileName)
        .lineLimit(1)
      if let exportDate = file.metadata?.exportedAt {
        Text("(\(exportDate.toShortDate()))")
          .font(.caption2)
          .foregroundStyle(color.opacity(0.8))
      }
    }
  }
}
