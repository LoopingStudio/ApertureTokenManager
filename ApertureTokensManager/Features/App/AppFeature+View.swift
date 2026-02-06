import SwiftUI
import ComposableArchitecture

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>
  
  var body: some View {
    TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
      DashboardView(store: store.scope(state: \.dashboard, action: \.dashboard))
        .tabItem {
          Label("Dashboard", systemImage: "square.stack.3d.up")
        }
        .tag(AppFeature.Tab.dashboard)
      
      ApertureTokensView(store: store.scope(state: \.token, action: \.token))
        .tabItem {
          Label("Importer", systemImage: "square.and.arrow.down")
        }
        .tag(AppFeature.Tab.importer)
      
      CompareView(store: store.scope(state: \.compare, action: \.compare))
        .tabItem {
          Label("Comparer", systemImage: "doc.text.magnifyingglass")
        }
        .tag(AppFeature.Tab.compare)
      
      AnalysisView(store: store.scope(state: \.analysis, action: \.analysis))
        .tabItem {
          Label("Analyser", systemImage: "chart.bar.doc.horizontal")
        }
        .tag(AppFeature.Tab.analysis)
    }
    .frame(minWidth: 800, minHeight: 600)
  }
}

#Preview {
  AppView(
    store: Store(initialState: AppFeature.State()) {
      AppFeature()
    }
  )
}
