import SwiftUI
import ComposableArchitecture

@ViewAction(for: AnalysisFeature.self)
struct AnalysisView: View {
  @Bindable var store: StoreOf<AnalysisFeature>
  @Namespace private var tabNamespace

  var body: some View {
    VStack(spacing: 0) {
      header
      if store.report != nil {
        analysisContent
      } else {
        configurationArea
      }
    }
    .animation(.easeInOut, value: store.report != nil)
    .animation(.easeInOut(duration: 0.25), value: store.selectedTab)
    .onAppear { send(.onAppear) }
  }

  // MARK: - Header

  @ViewBuilder
  private var header: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Analyse d'Utilisation")
          .font(.title)
          .fontWeight(.bold)

        Spacer()

        if store.report != nil {
          Button("Nouvelle Analyse") { send(.clearResultsTapped) }
            .controlSize(.small)
            .transition(.asymmetric(
              insertion: .scale(scale: 0.9).combined(with: .opacity),
              removal: .opacity
            ))
        }
      }

      if let error = store.analysisError {
        Text(error)
          .foregroundStyle(.red)
          .font(.caption)
      }

      Divider()
    }
    .padding()
  }

  // MARK: - Configuration Area

  @ViewBuilder
  private var configurationArea: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 24) {
          // Instructions
          if !store.hasTokensLoaded {
            warningCard(
              icon: "exclamationmark.triangle.fill",
              title: "Aucun Design System chargé",
              message: "Chargez d'abord un fichier de tokens dans l'onglet Dashboard pour pouvoir analyser son utilisation.",
              color: .orange
            )
          }
          
          // Directories Section
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Dossiers à analyser")
                .font(.headline)
              
              Spacer()
              
              Button {
                send(.addDirectoryTapped)
              } label: {
                Label("Ajouter un dossier", systemImage: "folder.badge.plus")
              }
              .controlSize(.small)
            }
            
            if store.directoriesToScan.isEmpty {
              emptyDirectoriesCard
            } else {
              directoriesList
            }
          }
          .padding()
          .background(Color(.controlBackgroundColor).opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          
          // Export Filters Section (readonly, shared with TokenFeature)
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Filtres d'export appliqués")
                .font(.headline)
              
              Spacer()
              
              Text("Configurer dans l'onglet Importer")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Text("Seuls les tokens qui seraient exportés sont analysés")
              .font(.caption)
              .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
              FilterBadge(
                label: "Exclure Utility",
                isActive: store.tokenFilters.excludeUtilityGroup,
                color: .orange
              )
              
              FilterBadge(
                label: "Exclure #tokens",
                isActive: store.tokenFilters.excludeTokensStartingWithHash,
                color: .purple
              )
              
              FilterBadge(
                label: "Exclure hover",
                isActive: store.tokenFilters.excludeTokensEndingWithHover,
                color: .blue
              )
            }
          }
          .padding()
          .background(Color(.controlBackgroundColor).opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 12))
          
          // Options Section
          VStack(alignment: .leading, spacing: 12) {
            Text("Options de scan")
              .font(.headline)
            
            Toggle("Ignorer les fichiers de test", isOn: $store.config.ignoreTestFiles)
            Toggle("Ignorer les fichiers de preview", isOn: $store.config.ignorePreviewFiles)
            
            Divider()
            
            Toggle(isOn: $store.config.ignoreTokenDeclarationFiles) {
              VStack(alignment: .leading, spacing: 2) {
                Text("Ignorer les fichiers de déclaration")
                Text("Aperture+Colors.swift, Colors.swift, etc.")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .padding()
          .background(Color(.controlBackgroundColor).opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .frame(maxWidth: 600)
      }
      
      // Start Button (fixed at bottom)
      if store.canStartAnalysis {
        VStack {
          Divider()
          Button {
            send(.startAnalysisTapped)
          } label: {
            if store.isAnalyzing {
              ProgressView()
                .controlSize(.small)
                .padding(.horizontal, 8)
            }
            Text(store.isAnalyzing ? "Analyse en cours..." : "Lancer l'analyse")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .disabled(store.isAnalyzing)
          .padding()
        }
        .background(.bar)
      }
    }
  }
  
  @ViewBuilder
  private var emptyDirectoriesCard: some View {
    VStack(spacing: 8) {
      Image(systemName: "folder")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      
      Text("Aucun dossier sélectionné")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      
      Text("Ajoutez les dossiers de vos projets Swift qui utilisent le design system")
        .font(.caption)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
    .background(Color(.controlBackgroundColor).opacity(0.3))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
  
  @ViewBuilder
  private var directoriesList: some View {
    VStack(spacing: 8) {
      ForEach(store.directoriesToScan) { directory in
        HStack {
          Image(systemName: "folder.fill")
            .foregroundStyle(.blue)
          
          VStack(alignment: .leading, spacing: 2) {
            Text(directory.name)
              .font(.subheadline)
              .fontWeight(.medium)
            
            Text(directory.url.path)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.middle)
          }
          
          Spacer()
          
          Button {
            send(.removeDirectory(directory.id))
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
      }
    }
  }
  
  @ViewBuilder
  private func warningCard(icon: String, title: String, message: String, color: Color) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundStyle(color)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
    }
    .padding()
    .background(color.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  // MARK: - Analysis Content

  @ViewBuilder
  private var analysisContent: some View {
    VStack(spacing: 0) {
      tabs
      Divider()
      if let report = store.report {
        tabContent(for: store.selectedTab, report: report)
          .padding()
          .id(store.selectedTab)
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.selectedTab)
  }

  // MARK: - Tabs

  @ViewBuilder
  private var tabs: some View {
    HStack {
      ForEach(AnalysisFeature.AnalysisTab.allCases, id: \.self) { tab in
        Button {
          send(.tabTapped(tab))
        } label: {
          VStack(spacing: 4) {
            Text(tab.rawValue)
              .font(.headline)
              .foregroundStyle(store.selectedTab == tab ? .primary : .secondary)

            if let report = store.report {
              Text(countForTab(tab, report: report))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .contentShape(.rect)
          .background {
            if store.selectedTab == tab {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
                .matchedGeometryEffect(id: "activeTab", in: tabNamespace)
            }
          }
          .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
      }

      Spacer()
    }
    .padding(.horizontal)
  }

  private func countForTab(_ tab: AnalysisFeature.AnalysisTab, report: TokenUsageReport) -> String {
    switch tab {
    case .overview: "Résumé"
    case .used: "\(report.usedTokens.count)"
    case .orphaned: "\(report.orphanedTokens.count)"
    }
  }

  // MARK: - Tab Content

  @ViewBuilder
  private func tabContent(for tab: AnalysisFeature.AnalysisTab, report: TokenUsageReport) -> some View {
    switch tab {
    case .overview:
      UsageOverviewView(report: report, onTabTapped: { send(.tabTapped($0)) })

    case .used:
      UsedTokensListView(
        tokens: report.usedTokens,
        selectedToken: store.selectedUsedToken,
        onTokenTapped: { send(.usedTokenTapped($0)) }
      )

    case .orphaned:
      OrphanedTokensListView(
        tokens: report.orphanedTokens,
        expandedCategories: store.expandedOrphanCategories,
        onToggleCategory: { send(.toggleOrphanCategory($0)) }
      )
    }
  }
}

// MARK: - Filter Badge

private struct FilterBadge: View {
  let label: String
  let isActive: Bool
  let color: Color
  
  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
        .font(.caption2)
      Text(label)
        .font(.caption)
    }
    .foregroundStyle(isActive ? color : .secondary)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(isActive ? color.opacity(0.15) : Color(.controlBackgroundColor))
    .clipShape(Capsule())
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Configuration") {
  AnalysisView(
    store: Store(initialState: .initial) {
      AnalysisFeature()
    }
  )
  .frame(width: 900, height: 600)
}
#endif
