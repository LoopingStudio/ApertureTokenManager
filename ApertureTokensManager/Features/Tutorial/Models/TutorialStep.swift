import Foundation

extension TutorialFeature {
  public enum TutorialStep: Int, CaseIterable, Equatable, Sendable {
    case welcome = 0
    case exportFigma = 1
    case importTokens = 2
    case setAsBase = 3
    case compareAnalyze = 4
    case exportXcode = 5

    var title: String {
      switch self {
      case .welcome: "Bienvenue"
      case .exportFigma: "Exporter depuis Figma"
      case .importTokens: "Importer les tokens"
      case .setAsBase: "Définir comme base"
      case .compareAnalyze: "Comparer & Analyser"
      case .exportXcode: "Exporter vers Xcode"
      }
    }

    var subtitle: String {
      switch self {
      case .welcome: "Découvrez Aperture Tokens Manager"
      case .exportFigma: "Étape 1 sur 5"
      case .importTokens: "Étape 2 sur 5"
      case .setAsBase: "Étape 3 sur 5"
      case .compareAnalyze: "Étape 4 sur 5"
      case .exportXcode: "Étape 5 sur 5"
      }
    }

    var icon: String {
      switch self {
      case .welcome: "sparkles"
      case .exportFigma: "arrow.down.doc"
      case .importTokens: "square.and.arrow.down"
      case .setAsBase: "checkmark.seal"
      case .compareAnalyze: "doc.text.magnifyingglass"
      case .exportXcode: "square.and.arrow.up"
      }
    }

    var color: String {
      switch self {
      case .welcome: "purple"
      case .exportFigma: "pink"
      case .importTokens: "blue"
      case .setAsBase: "orange"
      case .compareAnalyze: "green"
      case .exportXcode: "teal"
      }
    }

    var description: String {
      switch self {
      case .welcome:
        """
        Aperture Tokens Manager vous permet de gérer vos design tokens depuis Figma jusqu'à Xcode.
        
        Ce tutoriel vous guide à travers les 5 étapes du workflow complet.
        """
      case .exportFigma:
        """
        1. Installez le plugin "Multibrand Token Exporter" depuis la communauté Figma
        
        2. Ouvrez votre fichier Figma contenant les variables
        
        3. Lancez le plugin via Menu → Plugins → Multibrand Token Exporter
        
        4. Sélectionnez les collections à exporter et cliquez sur "Export JSON"
        
        5. Enregistrez le fichier .json sur votre Mac
        """
      case .importTokens:
        """
        1. Ouvrez l'onglet "Importer"
        
        2. Glissez-déposez votre fichier JSON
           ou cliquez sur "Sélectionner un fichier"
        
        3. Explorez vos tokens dans l'arborescence
           Utilisez Cmd+F pour rechercher
        
        4. Activez/désactivez les tokens selon vos besoins
        """
      case .setAsBase:
        """
        1. Après l'import, cliquez sur "Définir comme base"
        
        2. Ce fichier devient votre référence
           Il apparaît sur la page d'Accueil
        
        3. Vous pourrez le comparer aux futures versions
        
        4. La base est persistée entre les sessions
        """
      case .compareAnalyze:
        """
        Comparer (onglet "Comparer")
        • Chargez une ancienne et nouvelle version
        • Visualisez les ajouts, suppressions, modifications
        • Consultez les suggestions de remplacement
        
        Analyser (onglet "Analyser")
        • Scannez vos projets Swift
        • Identifiez les tokens utilisés
        • Détectez les tokens orphelins
        """
      case .exportXcode:
        """
        1. Depuis l'Accueil ou l'onglet Importer
        
        2. Cliquez sur "Exporter vers Xcode"
        
        3. Configurez les filtres d'export
           • Exclure les tokens #primitifs
           • Exclure les états _hover
           • Exclure le groupe Utility
        
        4. Choisissez le dossier de destination
        
        5. Récupérez Colors.xcassets + Aperture+Colors.swift
        """
      }
    }

    var isLast: Bool {
      self == TutorialStep.allCases.last
    }

    var isFirst: Bool {
      self == TutorialStep.allCases.first
    }
  }
}
