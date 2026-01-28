import SwiftUI
import ComposableArchitecture

@main
struct ApertureTokensImporterApp: App {
  var body: some Scene {
    WindowGroup {
      TabView {
        ApertureTokensView(
          store: Store(initialState: .initial) {
            TokenFeature()
          }
        )
        .tabItem {
          Label("Importer", systemImage: "square.and.arrow.down")
        }
        
        CompareView(
          store: Store(initialState: .initial) {
            CompareFeature()
          }
        )
        .tabItem {
          Label("Comparer", systemImage: "doc.text.magnifyingglass")
        }
      }
      .frame(minWidth: 800, minHeight: 600)
    }
  }
}
