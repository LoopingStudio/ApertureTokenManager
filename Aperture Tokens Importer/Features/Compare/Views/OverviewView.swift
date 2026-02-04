import SwiftUI

struct OverviewView: View {
  let changes: ComparisonChanges
  let oldFileMetadata: TokenMetadata?
  let newFileMetadata: TokenMetadata?
  let onTabTapped: (CompareFeature.ComparisonTab) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Résumé des changements")
        .font(.title2)
        .fontWeight(.semibold)
      fileInfoSection
      summaryCardsGrid
      Spacer()
    }
  }
  
  private var fileInfoSection: some View {
    HStack(spacing: 20) {
      FileInfoCard(title: "Ancienne Version", metadata: oldFileMetadata, color: .blue)

      Image(systemName: "arrow.right")
        .font(.title2)
        .foregroundStyle(.secondary)
      
      FileInfoCard(title: "Nouvelle Version", metadata: newFileMetadata, color: .green)
    }
    .padding(.bottom, 8)
  }
  
  private var summaryCardsGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
      SummaryCard(title: "Tokens Ajoutés", count: changes.added.count, color: .green, icon: "plus.circle.fill") {
        onTabTapped(.added)
      }
      SummaryCard(title: "Tokens Supprimés", count: changes.removed.count, color: .red, icon: "minus.circle.fill") {
        onTabTapped(.removed)
      }
      SummaryCard(title: "Tokens Modifiés", count: changes.modified.count, color: .orange, icon: "pencil.circle.fill") {
        onTabTapped(.modified)
      }
    }
  }
}
