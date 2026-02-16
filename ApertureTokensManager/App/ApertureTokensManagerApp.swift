import Combine
import SwiftUI
import ComposableArchitecture

import Sparkle

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

    // Create our view model for our CheckForUpdatesView
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
    // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
    // This is where you can also pass an updater delegate if you need one
    updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
  }
  
  var body: some Scene {
    WindowGroup {
      AppView(store: store)
        .frame(minWidth: 900, minHeight: 650)
    }
    .commands {
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
    }
    .defaultSize(width: 1100, height: 750)
  }
}
