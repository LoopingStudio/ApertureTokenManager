import SwiftUI

// MARK: - Import History View

struct ImportHistoryView: View {
  let history: [ImportHistoryEntry]
  let onEntryTapped: (ImportHistoryEntry) -> Void
  let onRemove: (UUID) -> Void
  let onClear: () -> Void
  
  var body: some View {
    HistorySection(
      title: "Imports récents",
      icon: "clock.arrow.circlepath",
      isEmpty: history.isEmpty,
      emptyMessage: "Aucun import récent",
      maxHeight: 180,
      onClear: onClear
    ) {
      VStack(spacing: 6) {
        ForEach(Array(history.enumerated()), id: \.element.id) { index, entry in
          ImportHistoryRow(entry: entry) {
            onEntryTapped(entry)
          } onRemove: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
              onRemove(entry.id)
            }
          }
          .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.9))
          ))
          .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05), value: history.count)
        }
      }
    }
  }
}

// MARK: - Import History Row

struct ImportHistoryRow: View {
  let entry: ImportHistoryEntry
  let onTap: () -> Void
  let onRemove: () -> Void
  
  var body: some View {
    HistoryRow {
      Image(systemName: "doc.fill")
        .font(.title3)
        .foregroundStyle(.purple)
    } content: {
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
          
          if entry.tokenCount > 0 {
            Text("\(entry.tokenCount) tokens")
              .font(.caption2)
              .foregroundStyle(.tertiary)
          }
        }
      }
    } onTap: {
      onTap()
    } onRemove: {
      onRemove()
    }
  }
}

// MARK: - Comparison History View

struct ComparisonHistoryView: View {
  let history: [ComparisonHistoryEntry]
  let onEntryTapped: (ComparisonHistoryEntry) -> Void
  let onRemove: (UUID) -> Void
  let onClear: () -> Void
  
  var body: some View {
    HistorySection(
      title: "Comparaisons récentes",
      icon: "clock.arrow.circlepath",
      isEmpty: history.isEmpty,
      emptyMessage: "Aucune comparaison récente",
      maxHeight: 200,
      onClear: onClear
    ) {
      VStack(spacing: 6) {
        ForEach(Array(history.enumerated()), id: \.element.id) { index, entry in
          ComparisonHistoryRow(entry: entry) {
            onEntryTapped(entry)
          } onRemove: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
              onRemove(entry.id)
            }
          }
          .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.9))
          ))
          .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05), value: history.count)
        }
      }
    }
  }
}

// MARK: - Comparison History Row

struct ComparisonHistoryRow: View {
  let entry: ComparisonHistoryEntry
  let onTap: () -> Void
  let onRemove: () -> Void
  
  var body: some View {
    HistoryRow {
      Image(systemName: "doc.text.magnifyingglass")
        .font(.title3)
        .foregroundStyle(.blue)
    } content: {
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
    } onTap: {
      onTap()
    } onRemove: {
      onRemove()
    }
  }
  
  @ViewBuilder
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
  
  @ViewBuilder
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
  
  @ViewBuilder
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

// MARK: - Previews

#if DEBUG
#Preview("Import History") {
  ImportHistoryView(
    history: PreviewData.importHistoryEntries,
    onEntryTapped: { _ in },
    onRemove: { _ in },
    onClear: { }
  )
  .frame(width: 400)
  .padding()
}

#Preview("Import History - Empty") {
  ImportHistoryView(
    history: [],
    onEntryTapped: { _ in },
    onRemove: { _ in },
    onClear: { }
  )
  .frame(width: 400)
  .padding()
}

#Preview("Comparison History") {
  ComparisonHistoryView(
    history: PreviewData.comparisonHistoryEntries,
    onEntryTapped: { _ in },
    onRemove: { _ in },
    onClear: { }
  )
  .frame(width: 500)
  .padding()
}

#Preview("Comparison History - Empty") {
  ComparisonHistoryView(
    history: [],
    onEntryTapped: { _ in },
    onRemove: { _ in },
    onClear: { }
  )
  .frame(width: 500)
  .padding()
}
#endif
