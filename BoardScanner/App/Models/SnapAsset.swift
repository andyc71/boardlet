import Foundation

struct SnapAsset: Codable, Sendable {
    var data: Data
    var previewPNG: Data?
    /// Optional for compatibility with existing version-2 documents.
    var previewFailure: String? = nil
}
