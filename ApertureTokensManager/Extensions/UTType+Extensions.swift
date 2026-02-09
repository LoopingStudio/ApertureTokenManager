import UniformTypeIdentifiers

extension UTType {
  /// Markdown file type (.md)
  static let markdown = UTType("net.daringfireball.markdown") ?? .plainText
}
