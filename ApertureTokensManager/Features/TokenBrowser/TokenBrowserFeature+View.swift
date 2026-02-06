import SwiftUI
import ComposableArchitecture

@ViewAction(for: TokenBrowserFeature.self)
struct TokenBrowserView: View {
  let store: StoreOf<TokenBrowserFeature>
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      browserContent
    }
    .frame(minWidth: 700, idealWidth: 900, minHeight: 500, idealHeight: 600)
  }
  
  private var header: some View {
    HStack {
      Image(systemName: "paintpalette.fill")
        .font(.title2)
        .foregroundStyle(.purple)
      
      VStack(alignment: .leading, spacing: 2) {
        Text("Tokens du Design System")
          .font(.title3)
          .fontWeight(.semibold)
        
        HStack(spacing: 8) {
          Text("Version \(store.metadata.version)")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text("•")
            .foregroundStyle(.tertiary)
          
          Text("\(store.tokenCount) tokens")
            .font(.caption)
            .foregroundStyle(.purple)
        }
      }
      
      Spacer()
      
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .keyboardShortcut(.escape, modifiers: [])
    }
    .padding()
  }
  
  private var browserContent: some View {
    HSplitView {
      tokenListView
        .frame(minWidth: 250, idealWidth: 300)
      
      tokenDetailView
        .frame(minWidth: 300)
    }
  }
  
  private var tokenListView: some View {
    List {
      ForEach(store.tokens, id: \.id) { node in
        ReadOnlyNodeTreeView(
          node: node,
          selectedNodeId: store.selectedNode?.id,
          expandedNodes: store.expandedNodes,
          onSelect: { send(.selectNode($0)) },
          onExpand: { send(.toggleNode($0)) }
        )
      }
    }
    .listStyle(.sidebar)
  }
  
  @ViewBuilder
  private var tokenDetailView: some View {
    if let selectedNode = store.selectedNode {
      TokenDetailView(node: selectedNode)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      ContentUnavailableView(
        "Sélectionnez un token",
        systemImage: "paintbrush",
        description: Text("Choisissez un token dans la liste pour voir ses détails")
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Token Browser") {
  TokenBrowserView(
    store: Store(initialState: TokenBrowserFeature.State(
      tokens: PreviewData.rootNodes,
      metadata: PreviewData.metadata
    )) {
      TokenBrowserFeature()
    }
  )
  .frame(width: 800, height: 500)
}

#Preview("Token Browser - With Selection") {
  TokenBrowserView(
    store: Store(initialState: TokenBrowserFeature.State(
      tokens: PreviewData.rootNodes,
      metadata: PreviewData.metadata,
      selectedNode: PreviewData.singleToken,
      expandedNodes: [PreviewData.colorsGroup.id, PreviewData.brandGroup.id]
    )) {
      TokenBrowserFeature()
    }
  )
  .frame(width: 800, height: 500)
}
#endif
