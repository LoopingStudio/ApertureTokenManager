import SwiftUI
import ComposableArchitecture

@ViewAction(for: DashboardFeature.self)
struct DashboardView: View {
  @Bindable var store: StoreOf<DashboardFeature>
  
  @State private var showHeader = false
  @State private var showStats = false
  @State private var showActions = false
  @State private var showEmptyContent = false
  @State private var iconPulse = false
  
  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      
      if let base = store.designSystemBase {
        designSystemBaseContent(base)
      } else {
        emptyBaseContent
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .sheet(item: $store.scope(state: \.tokenBrowser, action: \.tokenBrowser)) { browserStore in
      TokenBrowserView(store: browserStore)
    }
  }
  
  // MARK: - Header
  
  @ViewBuilder
  private var header: some View {
    HStack {
      Text("Dashboard")
        .font(.title)
        .fontWeight(.bold)
      
      Spacer()
      
      if store.designSystemBase != nil {
        Menu {
          Button(action: { send(.openFileButtonTapped) }) {
            Label("Afficher dans le Finder", systemImage: "folder")
          }
          Divider()
          Button(role: .destructive, action: { send(.clearBaseButtonTapped) }) {
            Label("Supprimer la base", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.title2)
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
      }
    }
    .padding()
  }
  
  // MARK: - Empty State
  
  @ViewBuilder
  private var emptyBaseContent: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      ZStack {
        Circle()
          .fill(Color.purple.opacity(0.1))
          .frame(width: 120, height: 120)
          .scaleEffect(iconPulse ? 1.1 : 1.0)
        
        Image(systemName: "square.stack.3d.up.slash")
          .font(.system(size: 48))
          .foregroundStyle(.purple.opacity(0.6))
      }
      .opacity(showEmptyContent ? 1 : 0)
      .scaleEffect(showEmptyContent ? 1 : 0.8)
      
      VStack(spacing: UIConstants.Spacing.small) {
        Text("Aucun Design System défini")
          .font(.title2)
          .fontWeight(.semibold)
        
        Text("Importez un fichier de tokens et définissez-le comme base\npour accéder au dashboard.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .opacity(showEmptyContent ? 1 : 0)
      .offset(y: showEmptyContent ? 0 : 10)
      
      Button {
        send(.goToImportTapped)
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "arrow.right.circle.fill")
            .foregroundStyle(.purple)
          Text("Utilisez l'onglet Importer pour charger un Design System")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          Capsule()
            .fill(Color.purple.opacity(0.1))
        )
        .opacity(showEmptyContent ? 1 : 0)
        .offset(y: showEmptyContent ? 0 : 15)
      }
      .buttonStyle(.plain)
    }
    .padding(UIConstants.Spacing.extraLarge)
    .frame(maxHeight: .infinity)
    .onAppear {
      withAnimation(.easeOut(duration: 0.5)) {
        showEmptyContent = true
      }
      withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
        iconPulse = true
      }
    }
  }
  
  // MARK: - Design System Base Content
  
  @ViewBuilder
  private func designSystemBaseContent(_ base: DesignSystemBase) -> some View {
    ScrollView {
      VStack(spacing: UIConstants.Spacing.large) {
        headerCard(base)
          .opacity(showHeader ? 1 : 0)
          .offset(y: showHeader ? 0 : -15)
        
        statsSection(base)
          .opacity(showStats ? 1 : 0)
          .offset(y: showStats ? 0 : 15)
        
        actionsSection
          .opacity(showActions ? 1 : 0)
          .offset(y: showActions ? 0 : 20)
        
        Spacer(minLength: 20)
      }
      .padding(UIConstants.Spacing.large)
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.35)) {
        showHeader = true
      }
      withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
        showStats = true
      }
      withAnimation(.easeOut(duration: 0.45).delay(0.2)) {
        showActions = true
      }
    }
  }
  
  @ViewBuilder
  private func headerCard(_ base: DesignSystemBase) -> some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      ZStack {
        Circle()
          .fill(Color.green.opacity(0.15))
          .frame(width: 56, height: 56)
        
        Image(systemName: "checkmark.seal.fill")
          .font(.title)
          .foregroundStyle(.green)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text("Design System Actif")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
              Capsule()
                .fill(Color.green.opacity(0.15))
            )
        }
        
        Text(base.fileName)
          .font(.title3)
          .fontWeight(.semibold)
          .lineLimit(1)
        
        if !base.metadata.version.isEmpty {
          Text("Version \(base.metadata.version)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      
      Spacer()
    }
    .padding(UIConstants.Spacing.medium)
    .background(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
        .fill(Color.green.opacity(0.08))
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
            .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    )
  }
  
  @ViewBuilder
  private func statsSection(_ base: DesignSystemBase) -> some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      StatCard(
        title: "Tokens",
        value: "\(base.tokenCount)",
        subtitle: "dans le design system",
        color: .blue,
        icon: "paintpalette.fill",
        action: { send(.tokenCountTapped) }
      )
      .staggeredAppear(index: 0)
      
      StatCard(
        title: "Défini le",
        value: base.setAt.formatted(date: .abbreviated, time: .omitted),
        subtitle: "comme base de référence",
        color: .orange,
        icon: "calendar"
      )
      .staggeredAppear(index: 1)
      
      StatCard(
        title: "Exporté",
        value: base.metadata.exportedAt.toShortDate(),
        subtitle: "par \(base.metadata.generator)",
        color: .purple,
        icon: "arrow.up.doc.fill"
      )
      .staggeredAppear(index: 2)
    }
  }
  
  @ViewBuilder
  private var actionsSection: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
      Text("Actions rapides")
        .font(.headline)
        .foregroundStyle(.secondary)
      
      HStack(spacing: UIConstants.Spacing.medium) {
        ExportActionCard(store: store)
          .staggeredAppear(index: 0, duration: 0.4)
        
        ActionCard(
          title: "Comparer avec import",
          subtitle: "Détecter les changements",
          icon: "doc.text.magnifyingglass",
          color: .green
        ) {
          send(.compareWithBaseButtonTapped)
        }
        .staggeredAppear(index: 1, baseDelay: 0.1, duration: 0.4)
      }
    }
  }
}



// MARK: - Export Action Card with Popover

private struct ExportActionCard: View {
  @Bindable var store: StoreOf<DashboardFeature>
  
  var body: some View {
    ActionCard(
      title: "Exporter vers Xcode",
      subtitle: "Générer XCAssets + Swift",
      icon: "square.and.arrow.up.fill",
      color: .blue
    ) {
      store.send(.view(.exportButtonTapped))
    }
    .popover(isPresented: $store.isExportPopoverPresented) {
      exportPopoverContent
    }
  }
  
  @ViewBuilder
  private var exportPopoverContent: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
      HStack {
        Image(systemName: "gearshape.fill")
          .foregroundStyle(.blue)
        Text("Filtres d'export")
          .font(.headline)
      }
      
      Divider()
      
      VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
        Toggle(isOn: $store.filters.excludeTokensStartingWithHash) {
          HStack {
            Image(systemName: "number")
              .foregroundStyle(.orange)
              .frame(width: 20)
            Text("Exclure tokens commençant par #")
          }
        }
        .toggleStyle(.checkbox)
        
        Toggle(isOn: $store.filters.excludeTokensEndingWithHover) {
          HStack {
            Image(systemName: "cursorarrow.click")
              .foregroundStyle(.purple)
              .frame(width: 20)
            Text("Exclure tokens finissant par _hover")
          }
        }
        .toggleStyle(.checkbox)
        
        Toggle(isOn: $store.filters.excludeUtilityGroup) {
          HStack {
            Image(systemName: "wrench.fill")
              .foregroundStyle(.gray)
              .frame(width: 20)
            Text("Exclure groupe Utility")
          }
        }
        .toggleStyle(.checkbox)
      }
      .font(.callout)
      
      Divider()
      
      HStack {
        Button("Annuler") {
          store.send(.view(.dismissExportPopover))
        }
        .buttonStyle(.bordered)
        
        Spacer()
        
        Button {
          store.send(.view(.confirmExportButtonTapped))
        } label: {
          Label("Exporter", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding()
    .frame(width: 320)
  }
}



// MARK: - Previews

#Preview("With Base") {
  DashboardView(
    store: Store(initialState: DashboardFeature.State(
      designSystemBase: Shared(wrappedValue: DesignSystemBase(
        fileName: "aperture-tokens-v2.1.0.json",
        bookmarkData: nil,
        metadata: TokenMetadata(
          exportedAt: "2026-01-28 14:30:45",
          timestamp: 1737982245000,
          version: "2.1.0",
          generator: "ApertureExporter Plugin"
        ),
        tokens: PreviewData.rootNodes
      ), .designSystemBase)
    )) {
      DashboardFeature()
    }
  )
  .frame(width: 900, height: 600)
}

#Preview("Empty") {
  DashboardView(
    store: Store(initialState: .initial) {
      DashboardFeature()
    }
  )
  .frame(width: 700, height: 500)
}
