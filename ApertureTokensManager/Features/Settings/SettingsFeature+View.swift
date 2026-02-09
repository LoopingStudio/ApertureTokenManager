import ComposableArchitecture
import SwiftUI

// MARK: - Settings View

@ViewAction(for: SettingsFeature.self)
struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationSplitView {
      sidebarContent
    } detail: {
      detailContent
    }
    .frame(minWidth: 700, minHeight: 450)
    .onAppear { send(.onAppear) }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Fermer") {
          dismiss()
        }
      }
    }
    .alert("Réinitialiser toutes les données ?", isPresented: $store.showResetConfirmation) {
      Button("Annuler", role: .cancel) {
        send(.dismissResetConfirmation)
      }
      Button("Réinitialiser", role: .destructive) {
        send(.confirmResetAllData)
      }
    } message: {
      Text("Cette action supprimera la base de design system, les historiques, les filtres et les paramètres. Cette action est irréversible.")
    }
  }
  
  // MARK: - Sidebar
  
  @ViewBuilder
  private var sidebarContent: some View {
    List(selection: $store.selectedSection.sending(\.view.sectionSelected)) {
      ForEach(SettingsFeature.SettingsSection.allCases, id: \.self) { section in
        Label {
          Text(section.rawValue)
        } icon: {
          sectionIcon(for: section)
        }
        .tag(section)
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("Paramètres")
  }
  
  @ViewBuilder
  private func sectionIcon(for section: SettingsFeature.SettingsSection) -> some View {
    switch section {
    case .export:
      Image(systemName: "square.and.arrow.up")
    case .history:
      Image(systemName: "clock.arrow.circlepath")
    case .data:
      Image(systemName: "folder")
    case .logs:
      Image(systemName: "doc.text.magnifyingglass")
    case .about:
      Image(systemName: "info.circle")
    }
  }
  
  // MARK: - Detail
  
  @ViewBuilder
  private var detailContent: some View {
    switch store.selectedSection {
    case .export:
      exportSection
    case .history:
      historySection
    case .data:
      dataSection
    case .logs:
      logsSection
    case .about:
      aboutSection
    }
  }
  
  // MARK: - Section Header
  
  @ViewBuilder
  private func sectionHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.title2)
        .fontWeight(.semibold)
      
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 8)
  }
  
  // MARK: - Export Section
  
  @ViewBuilder
  private var exportSection: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader(
          title: "Filtres d'export",
          subtitle: "Ces filtres s'appliquent lors de l'export vers Xcode. Les tokens correspondants seront exclus des fichiers générés."
        )
        
        GroupBox("Filtres par pattern") {
          VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $store.tokenFilters.excludeTokensStartingWithHash) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Exclure tokens commençant par #")
                Text("Exclut les tokens primitifs (ex: #blue-500)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            
            Divider()
            
            Toggle(isOn: $store.tokenFilters.excludeTokensEndingWithHover) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Exclure tokens finissant par _hover")
                Text("Exclut les états hover des tokens")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .padding(.vertical, 8)
        }
        
        GroupBox("Filtres par groupe") {
          Toggle(isOn: $store.tokenFilters.excludeUtilityGroup) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Exclure groupe Utility")
              Text("Exclut le groupe utilitaire complet")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 8)
        }
      }
      .padding()
    }
  }
  
  // MARK: - History Section
  
  @ViewBuilder
  private var historySection: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader(
          title: "Historique",
          subtitle: "Configurez le nombre d'entrées conservées dans l'historique des imports et comparaisons."
        )
        
        GroupBox("Configuration") {
          Stepper(value: $store.appSettings.maxHistoryEntries, in: 5...50, step: 5) {
            HStack {
              Text("Entrées maximum")
              Spacer()
              Text("\(store.appSettings.maxHistoryEntries)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
          }
          .padding(.vertical, 8)
        }
        
        GroupBox("Statistiques actuelles") {
          VStack(spacing: 12) {
            HStack {
              Text("Imports")
              Spacer()
              Text("\(store.importHistory.count)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack {
              Text("Comparaisons")
              Spacer()
              Text("\(store.comparisonHistory.count)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 8)
        }
      }
      .padding()
    }
  }
  
  // MARK: - Data Section
  
  @ViewBuilder
  private var dataSection: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader(
          title: "Gestion des données",
          subtitle: "Gérez les données stockées par l'application."
        )
        
        GroupBox("Stockage") {
          Button {
            send(.openDataFolderButtonTapped)
          } label: {
            Label("Ouvrir le dossier de données", systemImage: "folder")
          }
          .buttonStyle(.glass(.regular))
          .padding(.vertical, 8)
        }
        
        GroupBox("Réinitialisation") {
          VStack(alignment: .leading, spacing: 12) {
            Text("Réinitialiser toutes les données")
              .font(.headline)
            
            Text("Cette action supprimera :")
              .font(.caption)
              .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
              Label("Base de design system", systemImage: "paintpalette")
              Label("Historique des imports", systemImage: "clock.arrow.circlepath")
              Label("Historique des comparaisons", systemImage: "arrow.left.arrow.right")
              Label("Dossiers d'analyse", systemImage: "folder.badge.gearshape")
              Label("Filtres d'export", systemImage: "line.3.horizontal.decrease.circle")
              Label("Paramètres de l'application", systemImage: "gear")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Button(role: .destructive) {
              send(.resetAllDataButtonTapped)
            } label: {
              Label("Réinitialiser", systemImage: "trash")
            }
            .buttonStyle(.glass(.regular.tint(.red)))
          }
          .padding(.vertical, 8)
        }
      }
      .padding()
    }
  }
  
  // MARK: - Logs Section
  
  @ViewBuilder
  private var logsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          sectionHeader(
            title: "Journal d'activité",
            subtitle: "Consultez les événements et actions récentes de l'application."
          )
          
          Spacer()
          
          Text("\(store.logCount) entrées")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        HStack(spacing: 8) {
          Button {
            send(.refreshLogsButtonTapped)
          } label: {
            Label("Actualiser", systemImage: "arrow.clockwise")
          }
          .buttonStyle(.glass(.regular))
          .disabled(store.isLoadingLogs)
          
          Button {
            send(.clearLogsButtonTapped)
          } label: {
            Label("Vider", systemImage: "trash")
          }
          .buttonStyle(.glass(.regular.tint(.red)))
          .disabled(store.logEntries.isEmpty)
          
          Button {
            send(.exportLogsButtonTapped)
          } label: {
            Label("Exporter", systemImage: "square.and.arrow.up")
          }
          .buttonStyle(.glass(.regular.tint(.blue)))
          .disabled(store.logEntries.isEmpty || store.isExportingLogs)
        }
      }
      .padding()
      
      Divider()
      
      // Log List
      if store.isLoadingLogs {
        ProgressView("Chargement des logs...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if store.logEntries.isEmpty {
        ContentUnavailableView {
          Label("Aucun log", systemImage: "doc.text")
        } description: {
          Text("Les logs apparaîtront ici au fur et à mesure de l'utilisation de l'application.")
        }
        .frame(maxHeight: .infinity)
      } else {
        ScrollViewReader { proxy in
          List(store.logEntries) { entry in
            LogEntryRow(entry: entry)
              .id(entry.id)
          }
          .listStyle(.plain)
          .onAppear {
            if let lastEntry = store.logEntries.last {
              proxy.scrollTo(lastEntry.id, anchor: .bottom)
            }
          }
        }
      }
    }
  }
  
  // MARK: - About Section
  
  @ViewBuilder
  private var aboutSection: some View {
    VStack(spacing: 24) {
      Spacer()
      
      Image(systemName: "paintpalette.fill")
        .font(.system(size: 64))
        .foregroundStyle(.tint)
      
      Text("Aperture Tokens Manager")
        .font(.title)
        .fontWeight(.bold)
      
      Text("Version 1.0.0")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      
      Divider()
        .frame(width: 200)
      
      VStack(spacing: 8) {
        Text("Gérez vos design tokens Figma")
        Text("Importez, comparez, analysez et exportez")
      }
      .font(.body)
      .foregroundStyle(.secondary)
      
      Spacer()
      
      Text("© 2026 Picta")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
  let entry: LogEntry
  
  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      // Level indicator
      Text(entry.level.emoji)
        .font(.system(size: 12))
      
      // Timestamp
      Text(formattedTime)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .frame(width: 80, alignment: .leading)
      
      // Feature badge
      Text(entry.feature)
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(featureColor.opacity(0.2))
        .foregroundStyle(featureColor)
        .clipShape(Capsule())
      
      // Message
      Text(entry.message)
        .font(.caption.monospaced())
        .foregroundStyle(messageColor)
        .lineLimit(2)
      
      Spacer()
    }
    .padding(.vertical, 2)
  }
  
  private var formattedTime: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: entry.timestamp)
  }
  
  private var featureColor: Color {
    switch entry.feature.lowercased() {
    case "import": return .blue
    case "compare": return .purple
    case "analysis": return .orange
    case "export": return .green
    case "file": return .cyan
    case "home": return .indigo
    default: return .gray
    }
  }
  
  private var messageColor: Color {
    switch entry.level {
    case .error: return .red
    case .warning: return .orange
    case .success: return .green
    case .debug: return .secondary
    case .info: return .primary
    }
  }
}

// MARK: - Preview

#if DEBUG
#Preview {
  SettingsView(
    store: Store(initialState: SettingsFeature.State.initial) {
      SettingsFeature()
    }
  )
}
#endif
