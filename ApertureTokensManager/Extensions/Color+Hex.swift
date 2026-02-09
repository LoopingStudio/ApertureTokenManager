import SwiftUI

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r, g, b, a: UInt64
    switch hex.count {
    case 3: (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
    case 6: (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
    case 8: (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF) // RGBA (Figma format)
    default: (r, g, b, a) = (1, 1, 1, 0)
    }
    self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
  }
}

// MARK: - Color Delta

/// Represents the difference between two colors in HSL space
public struct ColorDelta: Equatable, Sendable {
  /// Hue difference in degrees (-180 to +180)
  public let hueDelta: Double
  /// Saturation difference in percentage (-100 to +100)
  public let saturationDelta: Double
  /// Lightness difference in percentage (-100 to +100)
  public let lightnessDelta: Double
  /// Overall perceptual difference (0 to 100)
  public let magnitude: Double
  
  /// Classification of the change magnitude
  public var classification: Classification {
    if magnitude < 5 { return .minimal }
    if magnitude < 15 { return .subtle }
    if magnitude < 30 { return .moderate }
    return .major
  }
  
  public enum Classification: String, Sendable {
    case minimal = "Minimal"
    case subtle = "Subtil"
    case moderate = "Modéré"
    case major = "Majeur"
    
    public var color: Color {
      switch self {
      case .minimal: return .gray
      case .subtle: return .blue
      case .moderate: return .orange
      case .major: return .red
      }
    }
  }
  
  /// Human-readable description of the main change
  public var description: String {
    var changes: [String] = []
    
    // Lightness changes
    if abs(lightnessDelta) >= 5 {
      let direction = lightnessDelta > 0 ? "+" : ""
      changes.append("Luminosité \(direction)\(Int(lightnessDelta))%")
    }
    
    // Saturation changes
    if abs(saturationDelta) >= 5 {
      let direction = saturationDelta > 0 ? "+" : ""
      changes.append("Saturation \(direction)\(Int(saturationDelta))%")
    }
    
    // Hue changes (only if significant)
    if abs(hueDelta) >= 10 {
      let direction = hueDelta > 0 ? "+" : ""
      changes.append("Teinte \(direction)\(Int(hueDelta))°")
    }
    
    if changes.isEmpty {
      return "Changement minimal"
    }
    
    return changes.joined(separator: ", ")
  }
}

// MARK: - Color Delta Calculation

public enum ColorDeltaCalculator {
  
  /// Calculate the delta between two hex colors
  public static func calculateDelta(oldHex: String, newHex: String) -> ColorDelta {
    let oldHSL = hexToHSL(oldHex)
    let newHSL = hexToHSL(newHex)
    
    // Calculate hue delta (handle wraparound at 360°)
    var hueDelta = newHSL.h - oldHSL.h
    if hueDelta > 180 { hueDelta -= 360 }
    if hueDelta < -180 { hueDelta += 360 }
    
    let saturationDelta = (newHSL.s - oldHSL.s) * 100
    let lightnessDelta = (newHSL.l - oldHSL.l) * 100
    
    // Calculate perceptual magnitude (weighted)
    // Lightness changes are most noticeable, then saturation, then hue
    let magnitude = sqrt(
      pow(lightnessDelta * 1.5, 2) +
      pow(saturationDelta * 1.0, 2) +
      pow(hueDelta / 3.6 * 0.8, 2) // Normalize hue to 0-100 scale
    )
    
    return ColorDelta(
      hueDelta: hueDelta,
      saturationDelta: saturationDelta,
      lightnessDelta: lightnessDelta,
      magnitude: min(magnitude, 100)
    )
  }
  
  /// Convert hex color to HSL
  private static func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double) {
    let rgb = hexToRGB(hex)
    return rgbToHSL(r: rgb.r, g: rgb.g, b: rgb.b)
  }
  
  /// Convert hex to RGB (0-1 range)
  private static func hexToRGB(_ hex: String) -> (r: Double, g: Double, b: Double) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    
    let r, g, b: Double
    switch hex.count {
    case 3:
      r = Double((int >> 8) * 17) / 255
      g = Double((int >> 4 & 0xF) * 17) / 255
      b = Double((int & 0xF) * 17) / 255
    case 6:
      r = Double(int >> 16) / 255
      g = Double(int >> 8 & 0xFF) / 255
      b = Double(int & 0xFF) / 255
    case 8:
      r = Double(int >> 24) / 255
      g = Double(int >> 16 & 0xFF) / 255
      b = Double(int >> 8 & 0xFF) / 255
    default:
      r = 0; g = 0; b = 0
    }
    return (r, g, b)
  }
  
  /// Convert RGB to HSL
  private static func rgbToHSL(r: Double, g: Double, b: Double) -> (h: Double, s: Double, l: Double) {
    let maxC = max(r, g, b)
    let minC = min(r, g, b)
    let l = (maxC + minC) / 2
    
    if maxC == minC {
      return (0, 0, l) // Achromatic
    }
    
    let d = maxC - minC
    let s = l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC)
    
    var h: Double
    switch maxC {
    case r: h = (g - b) / d + (g < b ? 6 : 0)
    case g: h = (b - r) / d + 2
    default: h = (r - g) / d + 4
    }
    h *= 60
    
    return (h, s, l)
  }
}
