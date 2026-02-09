import Foundation

/// Formateur pour exporter les rapports d'analyse en différents formats
public enum AnalysisReportFormatter {
  
  // MARK: - Markdown Format
  
  /// Génère un rapport Markdown complet
  public static func formatAsMarkdown(_ report: TokenUsageReport) -> String {
    var lines: [String] = []
    
    // Header
    lines.append("# Rapport d'Analyse des Tokens")
    lines.append("")
    lines.append("Généré le \(report.analyzedAt.formatted(date: .long, time: .shortened))")
    lines.append("")
    
    // Statistics
    lines.append("## Résumé")
    lines.append("")
    lines.append("| Métrique | Valeur |")
    lines.append("|----------|--------|")
    lines.append("| Tokens analysés | \(report.statistics.totalTokens) |")
    lines.append("| Tokens utilisés | \(report.statistics.usedCount) (\(String(format: "%.0f", report.statistics.usagePercentage))%) |")
    lines.append("| Tokens orphelins | \(report.statistics.orphanedCount) (\(String(format: "%.0f", report.statistics.orphanedPercentage))%) |")
    lines.append("| Occurrences totales | \(report.statistics.totalUsages) |")
    lines.append("| Fichiers scannés | \(report.statistics.filesScanned) |")
    lines.append("")
    
    // Scanned directories
    lines.append("## Dossiers analysés")
    lines.append("")
    for directory in report.scannedDirectories {
      lines.append("- **\(directory.name)** - \(directory.filesScanned) fichiers")
    }
    lines.append("")
    
    // Used tokens
    if !report.usedTokens.isEmpty {
      lines.append("## Tokens utilisés (\(report.usedTokens.count))")
      lines.append("")
      
      let sortedUsed = report.usedTokens.sorted { $0.usageCount > $1.usageCount }
      
      lines.append("| Token | Usages | Fichiers |")
      lines.append("|-------|--------|----------|")
      
      for token in sortedUsed {
        let uniqueFiles = Set(token.usages.map { URL(fileURLWithPath: $0.filePath).lastPathComponent }).count
        lines.append("| `\(token.enumCase)` | \(token.usageCount) | \(uniqueFiles) |")
      }
      lines.append("")
    }
    
    // Orphaned tokens
    if !report.orphanedTokens.isEmpty {
      lines.append("## Tokens orphelins (\(report.orphanedTokens.count))")
      lines.append("")
      lines.append("Ces tokens ne sont pas utilisés dans les dossiers analysés.")
      lines.append("")
      
      let grouped = Dictionary(grouping: report.orphanedTokens, by: \.category)
      let sortedCategories = grouped.keys.sorted()
      
      for category in sortedCategories {
        guard let tokens = grouped[category] else { continue }
        
        lines.append("### \(category) (\(tokens.count))")
        lines.append("")
        
        for token in tokens.sorted(by: { $0.enumCase < $1.enumCase }) {
          lines.append("- `\(token.enumCase)`")
        }
        lines.append("")
      }
    }
    
    // Footer
    lines.append("---")
    lines.append("*Généré par Aperture Tokens Manager*")
    
    return lines.joined(separator: "\n")
  }
  
  // MARK: - CSV Format
  
  /// Génère un CSV des tokens utilisés avec leurs occurrences
  public static func formatUsedAsCSV(_ report: TokenUsageReport) -> String {
    var lines: [String] = []
    
    // Header
    lines.append("Token,Path,Usages,Fichiers")
    
    let sortedUsed = report.usedTokens.sorted { $0.usageCount > $1.usageCount }
    
    for token in sortedUsed {
      let uniqueFiles = Set(token.usages.map { URL(fileURLWithPath: $0.filePath).lastPathComponent }).count
      let path = token.originalPath ?? ""
      lines.append("\"\(token.enumCase)\",\"\(path)\",\(token.usageCount),\(uniqueFiles)")
    }
    
    return lines.joined(separator: "\n")
  }
  
  /// Génère un CSV des tokens orphelins
  public static func formatOrphanedAsCSV(_ report: TokenUsageReport) -> String {
    var lines: [String] = []
    
    // Header
    lines.append("Token,Path,Catégorie")
    
    let sorted = report.orphanedTokens.sorted { $0.enumCase < $1.enumCase }
    
    for token in sorted {
      let path = token.originalPath ?? ""
      lines.append("\"\(token.enumCase)\",\"\(path)\",\"\(token.category)\"")
    }
    
    return lines.joined(separator: "\n")
  }
}
