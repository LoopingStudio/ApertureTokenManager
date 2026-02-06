import SwiftUI

struct UsageOverviewView: View {
  let report: TokenUsageReport
  let onTabTapped: (AnalysisFeature.AnalysisTab) -> Void
  
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Stats Cards
        HStack(spacing: 16) {
          statCard(
            title: "Tokens Utilisés",
            value: "\(report.statistics.usedCount)",
            subtitle: String(format: "%.0f%% du total", report.statistics.usagePercentage),
            color: .green,
            icon: "checkmark.circle.fill"
          ) {
            onTabTapped(.used)
          }
          
          statCard(
            title: "Tokens Orphelins",
            value: "\(report.statistics.orphanedCount)",
            subtitle: String(format: "%.0f%% du total", report.statistics.orphanedPercentage),
            color: .orange,
            icon: "exclamationmark.triangle.fill"
          ) {
            onTabTapped(.orphaned)
          }
          
          statCard(
            title: "Occurrences",
            value: "\(report.statistics.totalUsages)",
            subtitle: "dans \(report.statistics.filesScanned) fichiers",
            color: .blue,
            icon: "doc.text.fill"
          )
        }
        
        // Scanned Directories
        VStack(alignment: .leading, spacing: 12) {
          Text("Dossiers analysés")
            .font(.headline)
          
          ForEach(report.scannedDirectories) { directory in
            HStack {
              Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
              
              Text(directory.name)
                .fontWeight(.medium)
              
              Spacer()
              
              Text("\(directory.filesScanned) fichiers")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
          }
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
        // Top Used Tokens
        if !report.usedTokens.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Tokens les plus utilisés")
                .font(.headline)
              
              Spacer()
              
              Button("Voir tous") {
                onTabTapped(.used)
              }
              .font(.caption)
            }
            
            ForEach(report.usedTokens.prefix(5)) { token in
              HStack {
                Text(token.enumCase)
                  .font(.system(.body, design: .monospaced))
                
                Spacer()
                
                Text("\(token.usageCount) usages")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(Color.green.opacity(0.2))
                  .clipShape(Capsule())
              }
              .padding(8)
              .background(Color(.controlBackgroundColor))
              .clipShape(RoundedRectangle(cornerRadius: 6))
            }
          }
          .padding()
          .background(Color(.controlBackgroundColor).opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        
        // Orphaned Categories Preview
        if !report.orphanedTokens.isEmpty {
          let grouped = Dictionary(grouping: report.orphanedTokens, by: \.category)
          
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Catégories orphelines")
                .font(.headline)
              
              Spacer()
              
              Button("Voir tous") {
                onTabTapped(.orphaned)
              }
              .font(.caption)
            }
            
            ForEach(Array(grouped.keys.sorted().prefix(5)), id: \.self) { category in
              HStack {
                Text(category)
                  .fontWeight(.medium)
                
                Spacer()
                
                Text("\(grouped[category]?.count ?? 0) tokens")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(Color.orange.opacity(0.2))
                  .clipShape(Capsule())
              }
              .padding(8)
              .background(Color(.controlBackgroundColor))
              .clipShape(RoundedRectangle(cornerRadius: 6))
            }
          }
          .padding()
          .background(Color(.controlBackgroundColor).opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        
        // Analysis Info
        HStack {
          Image(systemName: "clock")
            .foregroundStyle(.secondary)
          Text("Analysé le \(report.analyzedAt.formatted(date: .abbreviated, time: .shortened))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
  
  @ViewBuilder
  private func statCard(
    title: String,
    value: String,
    subtitle: String,
    color: Color,
    icon: String,
    action: (() -> Void)? = nil
  ) -> some View {
    Button {
      action?()
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: icon)
            .foregroundStyle(color)
          Spacer()
        }
        
        Text(value)
          .font(.system(size: 32, weight: .bold, design: .rounded))
        
        Text(title)
          .font(.headline)
        
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(color.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .disabled(action == nil)
  }
}

#if DEBUG
#Preview {
  UsageOverviewView(
    report: TokenUsageReport(
      scannedDirectories: [
        ScannedDirectory(name: "MyApp", url: URL(fileURLWithPath: "/"), bookmarkData: nil, filesScanned: 42)
      ],
      usedTokens: [
        UsedToken(enumCase: "bgBrandSolid", originalPath: "Background/Brand/solid", usages: [
          TokenUsage(filePath: "/ContentView.swift", lineNumber: 10, lineContent: ".bgBrandSolid", matchType: ".")
        ])
      ],
      orphanedTokens: [
        OrphanedToken(enumCase: "fgLegacyMuted", originalPath: "Foreground/Legacy/muted")
      ]
    ),
    onTabTapped: { _ in }
  )
  .frame(width: 800, height: 600)
  .padding()
}
#endif
