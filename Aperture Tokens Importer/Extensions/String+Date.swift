import Foundation

extension String {
  public var formatFrenchDate: String {
    // Try to parse common date formats and convert to French format
    let inputFormatter = DateFormatter()
    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "fr_FR")
    outputFormatter.dateStyle = .medium
    outputFormatter.timeStyle = .short

    // Try different input formats
    let formats = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      "yyyy-MM-dd"
    ]

    for format in formats {
      inputFormatter.dateFormat = format
      if let date = inputFormatter.date(from: self) {
        return outputFormatter.string(from: date)
      }
    }

    // If no format matches, return original string
    return self
  }
  
  /// Converts date string to short format (dd/MM/yy)
  func toShortDate() -> String {
    let inputFormatter = DateFormatter()
    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "fr_FR")
    outputFormatter.dateFormat = "dd/MM/yy"
    
    let formats = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      "yyyy-MM-dd"
    ]
    
    for format in formats {
      inputFormatter.dateFormat = format
      if let date = inputFormatter.date(from: self) {
        return outputFormatter.string(from: date)
      }
    }
    
    return self
  }
}
