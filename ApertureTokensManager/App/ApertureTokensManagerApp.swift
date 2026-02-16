import Combine
import SwiftUI
import ComposableArchitecture

import Sparkle

// MARK: - Sparkle Environment Key

private struct UpdaterKey: EnvironmentKey {
  static let defaultValue: SPUUpdater? = nil
}

extension EnvironmentValues {
  var updater: SPUUpdater? {
    get { self[UpdaterKey.self] }
    set { self[UpdaterKey.self] = newValue }
  }
}

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
  @Published var canCheckForUpdates = false

  init(updater: SPUUpdater) {
    updater.publisher(for: \.canCheckForUpdates)
      .assign(to: &$canCheckForUpdates)
  }
}

// This is the view for the Check for Updates menu item
// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
struct CheckForUpdatesView: View {
  @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
  private let updater: SPUUpdater

  init(updater: SPUUpdater) {
    self.updater = updater
    self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
  }

  var body: some View {
    Button {
      updater.checkForUpdates()
    } label: {
      Label("Check for Updates…", systemImage: "arrow.triangle.2.circlepath")
    }
    .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
  }
}

@main
struct ApertureTokensManagerApp: App {
  private let updaterController: SPUStandardUpdaterController
  @State private var store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }
  
  init() {
    updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
  }
  
  var body: some Scene {
    WindowGroup {
      AppView(store: store)
        .environment(\.updater, updaterController.updater)
        .frame(minWidth: 900, minHeight: 650)
    }
    .commands {
      // MARK: - App Menu
      CommandGroup(after: .appInfo) {
        CheckForUpdatesView(updater: updaterController.updater)
        
        Divider()
        
        Button {
          store.send(.settingsButtonTapped)
        } label: {
          Label("Settings…", systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Button {
          store.send(.tutorialButtonTapped)
        } label: {
          Label("Tutorial", systemImage: "questionmark.circle")
        }
      }
      
      // MARK: - File Menu
      CommandGroup(after: .newItem) {
        Button {
          store.send(.menu(.importTokens))
        } label: {
          Label("Import Tokens…", systemImage: "square.and.arrow.down")
        }
        .keyboardShortcut("o", modifiers: .command)
        
        Button {
          store.send(.menu(.exportToXcode))
        } label: {
          Label("Export to Xcode…", systemImage: "square.and.arrow.up")
        }
        .keyboardShortcut("e", modifiers: .command)
        .disabled(!store.canExport)
      }
      
      // MARK: - Edit Menu (Filters)
      CommandMenu("Filters") {
        Toggle(isOn: Binding(
          get: { store.tokenFilters.excludeTokensStartingWithHash },
          set: { _ in store.send(.menu(.toggleFilterHash)) }
        )) {
          Label("Exclude Tokens Starting with #", systemImage: "number")
        }
        
        Toggle(isOn: Binding(
          get: { store.tokenFilters.excludeTokensEndingWithHover },
          set: { _ in store.send(.menu(.toggleFilterHover)) }
        )) {
          Label("Exclude Tokens Ending with _hover", systemImage: "cursorarrow.motionlines")
        }
        
        Toggle(isOn: Binding(
          get: { store.tokenFilters.excludeUtilityGroup },
          set: { _ in store.send(.menu(.toggleFilterUtility)) }
        )) {
          Label("Exclude Utility Group", systemImage: "folder.badge.minus")
        }
      }
      
      // MARK: - View Menu (Navigation)
      CommandGroup(after: .toolbar) {
        Divider()
        
        Button {
          store.send(.tabSelected(.home))
        } label: {
          Label("Home", systemImage: "house")
        }
        .keyboardShortcut("1", modifiers: .command)
        
        Button {
          store.send(.tabSelected(.analysis))
        } label: {
          Label("Analyser", systemImage: "magnifyingglass")
        }
        .keyboardShortcut("2", modifiers: .command)
        
        Button {
          store.send(.tabSelected(.compare))
        } label: {
          Label("Comparer", systemImage: "arrow.left.arrow.right")
        }
        .keyboardShortcut("3", modifiers: .command)
        
        Button {
          store.send(.tabSelected(.importer))
        } label: {
          Label("Importer", systemImage: "square.and.arrow.down")
        }
        .keyboardShortcut("4", modifiers: .command)
      }
      
      // MARK: - Help Menu
      CommandGroup(replacing: .help) {
        Link(destination: TutorialConstants.figmaPluginURL) {
          Label("Figma Plugin", systemImage: "puzzlepiece.extension")
        }
        
        Link(destination: URL(string: "https://loopingstudio.github.io/ApertureTokensManager/")!) {
          Label("Documentation", systemImage: "book")
        }
        
        Link(destination: URL(string: "https://github.com/LoopingStudio/ApertureTokensManager/issues/new")!) {
          Label("Report an Issue…", systemImage: "exclamationmark.bubble")
        }
      }
    }
    .defaultSize(width: 1100, height: 750)
  }
}
