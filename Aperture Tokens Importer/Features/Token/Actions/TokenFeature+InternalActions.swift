import ComposableArchitecture
import Foundation

extension TokenFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .fileLoadingStarted:
      state.isLoading = true
      state.loadingError = false
      state.errorMessage = nil
      return .none
      
    case .fileLoadingFailed(let message):
      state.isLoading = false
      state.loadingError = true
      state.errorMessage = message
      return .none
      
    case .loadFile(let url):
      return .run { send in
        do {
          let tokenExport = try await tokenClient.loadJSON(url)
          await send(.internal(.exportLoaded(tokenExport)))
        } catch {
          print("Erreur chargement: \(error)")
          await send(.internal(.fileLoadingFailed("Erreur de chargement du fichier JSON")))
        }
      }
      
    case .exportLoaded(let tokenExport):
      state.isLoading = false
      state.loadingError = false
      state.errorMessage = nil
      state.rootNodes = tokenExport.tokens
      state.isFileLoaded = true
      state.metadata = tokenExport.metadata
      state.allNodes = buildFlatNodeList(tokenExport.tokens)
      state.selectedNode = tokenExport.tokens.first
      return .none
      
    case .applyFilters:
      applyFiltersToNodes(state: &state)
      return .none
    }
  }
  
  // Helper pour construire une liste plate de tous les nœuds
  private func buildFlatNodeList(_ nodes: [TokenNode]) -> [TokenNode] {
    var result: [TokenNode] = []
    
    func addNodesRecursively(_ nodes: [TokenNode]) {
      for node in nodes {
        result.append(node)
        if let children = node.children {
          addNodesRecursively(children)
        }
      }
    }
    
    addNodesRecursively(nodes)
    return result
  }
  
  // Fonction pour appliquer les filtres aux nœuds
  func applyFiltersToNodes(state: inout State) {
    applyFiltersRecursively(nodes: &state.rootNodes, excludeStartingWithHash: state.excludeTokensStartingWithHash, excludeEndingWithHover: state.excludeTokensEndingWithHover)
    // Reconstruire la liste plate après filtrage
    state.allNodes = buildFlatNodeList(state.rootNodes)
  }
  
  private func applyFiltersRecursively(nodes: inout [TokenNode], excludeStartingWithHash: Bool, excludeEndingWithHover: Bool) {
    for i in 0..<nodes.count {
      // Appliquer les filtres aux enfants d'abord
      if nodes[i].children != nil {
        applyFiltersRecursively(nodes: &nodes[i].children!, excludeStartingWithHash: excludeStartingWithHash, excludeEndingWithHover: excludeEndingWithHover)
      }
      
      // Appliquer les filtres au nœud courant s'il s'agit d'un token
      if nodes[i].type == .token {
        var newIsEnabled = true // Commencer par activé par défaut
        
        // Appliquer les filtres seulement si ils sont activés
        if excludeStartingWithHash && nodes[i].name.hasPrefix("#") {
          newIsEnabled = false
        }
        if excludeEndingWithHover && nodes[i].name.hasSuffix("_hover") {
          newIsEnabled = false
        }
        
        // Mettre à jour l'état enabled seulement si nécessaire
        if nodes[i].isEnabled != newIsEnabled {
          nodes[i] = TokenNode(
            id: nodes[i].id,
            name: nodes[i].name,
            type: nodes[i].type,
            path: nodes[i].path,
            modes: nodes[i].modes,
            children: nodes[i].children,
            isEnabled: newIsEnabled
          )
        }
      }
    }
  }
}
