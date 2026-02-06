import ComposableArchitecture
import Foundation

extension AnalysisFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .analysisCompleted(let report):
      state.isAnalyzing = false
      state.report = report
      state.analysisError = nil
      return .none
      
    case .analysisFailed(let error):
      state.isAnalyzing = false
      state.analysisError = error
      return .none
      
    case .directoryPicked(let url, let bookmarkData):
      let directory = ScanDirectory(
        name: url.lastPathComponent,
        url: url,
        bookmarkData: bookmarkData
      )
      
      // Éviter les doublons
      state.$directoriesToScan.withLock { directories in
        if !directories.contains(where: { $0.url == url }) {
          directories.append(directory)
        }
      }
      return .none
    }
  }
}
