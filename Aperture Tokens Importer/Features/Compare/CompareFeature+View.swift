import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers

@ViewAction(for: CompareFeature.self)
struct CompareView: View {
  @Bindable var store: StoreOf<CompareFeature>

  var body: some View {
    VStack(spacing: 0) {
      header
      if store.changes != nil {
        comparisonContent
      } else {
        fileSelectionArea
      }
    }
    .animation(.easeInOut, value: store.isOldFileLoaded && store.isNewFileLoaded)
  }

  // MARK: - Header

  private var header: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Comparaison de Tokens")
          .font(.title)
          .fontWeight(.bold)

        Spacer()

        if store.changes != nil {
          Button("Nouvelle Comparaison") { send(.resetComparison) }
            .controlSize(.small)
          Button("Exporter pour Notion") { send(.exportToNotionTapped) }
            .controlSize(.small)
            .buttonStyle(.borderedProminent)
        }
      }

      if let error = store.loadingError {
        Text(error)
          .foregroundStyle(.red)
          .font(.caption)
      }

      Divider()
    }
    .padding()
  }

  // MARK: - File Selection Area

  private var fileSelectionArea: some View {
    VStack(spacing: 24) {
      HStack(spacing: 24) {
        DropZone(
          title: "Ancienne Version",
          subtitle: "Glissez le fichier JSON de l'ancienne version ici",
          isLoaded: store.isOldFileLoaded,
          isLoading: store.isLoadingOldFile,
          primaryColor: .blue,
          onDrop: { providers in
            guard let provider = providers.first else { return false }
            send(.fileDroppedWithProvider(.old, provider))
            return true
          },
          onSelectFile: { send(.selectFileTapped(.old)) },
          onRemove: store.isOldFileLoaded ? { send(.removeFile(.old)) } : nil,
          metadata: store.oldFileMetadata
        )

        VStack(spacing: 8) {
          Image(systemName: "arrow.right")
            .font(.title2)
            .foregroundStyle(.secondary)

          if store.isOldFileLoaded && store.isNewFileLoaded {
            Button {
              send(.switchFiles)
            } label: {
              Image(systemName: "arrow.left.arrow.right")
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Échanger les fichiers")
          }
        }
        .frame(width: 32)

        DropZone(
          title: "Nouvelle Version",
          subtitle: "Glissez le fichier JSON de la nouvelle version ici",
          isLoaded: store.isNewFileLoaded,
          isLoading: store.isLoadingNewFile,
          primaryColor: .green,
          onDrop: { providers in
            guard let provider = providers.first else { return false }
            send(.fileDroppedWithProvider(.new, provider))
            return true
          },
          onSelectFile: { send(.selectFileTapped(.new)) },
          onRemove: store.isNewFileLoaded ? { send(.removeFile(.new)) } : nil,
          metadata: store.newFileMetadata
        )
      }
      .overlay(alignment: .bottom) {
        if store.isOldFileLoaded && store.isNewFileLoaded {
          Button("Comparer les fichiers") {
            send(.compareButtonTapped)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .offset(y: 48)
          .transition(.push(from: .top).combined(with: .opacity))
        }
      }
    }
    .padding()
    .frame(maxHeight: .infinity)
  }

  // MARK: - Comparison Content

  private var comparisonContent: some View {
    VStack(spacing: 0) {
      tabs
      Divider()
      if let changes = store.changes {
        tabContent(for: store.selectedTab, changes: changes)
          .padding()
      }
    }
  }

  // MARK: - Tabs

  private var tabs: some View {
    HStack {
      ForEach(CompareFeature.ComparisonTab.allCases, id: \.self) { tab in
        Button(action: { send(.tabTapped(tab)) }) {
          VStack(spacing: 4) {
            Text(tab.rawValue)
              .font(.headline)
              .foregroundStyle(store.selectedTab == tab ? .primary : .secondary)

            if let changes = store.changes {
              Text(countForTab(tab, changes: changes))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .contentShape(.rect)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(store.selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
          )
          .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
      }

      Spacer()
    }
    .padding(.horizontal)
  }

  private func countForTab(_ tab: CompareFeature.ComparisonTab, changes: ComparisonChanges) -> String {
    switch tab {
    case .overview: "Résumé"
    case .added: "\(changes.added.count)"
    case .removed: "\(changes.removed.count)"
    case .modified: "\(changes.modified.count)"
    }
  }

  // MARK: - Tab Content

  @ViewBuilder
  private func tabContent(for tab: CompareFeature.ComparisonTab, changes: ComparisonChanges) -> some View {
    switch tab {
    case .overview:
      OverviewView(
        changes: changes,
        oldFileMetadata: store.oldFileMetadata,
        newFileMetadata: store.newFileMetadata,
        onTabTapped: { send(.tabTapped($0)) }
      )

    case .added:
      AddedTokensView(tokens: changes.added)

    case .removed:
      RemovedTokensView(
        tokens: changes.removed,
        changes: store.changes,
        newVersionTokens: store.newVersionTokens,
        onSuggestReplacement: { removedPath, replacementPath in
          send(.suggestReplacement(removedTokenPath: removedPath, replacementTokenPath: replacementPath))
        }
      )

    case .modified:
      ModifiedTokensView(
        modifications: changes.modified,
        newVersionTokens: store.newVersionTokens
      )
    }
  }
}
