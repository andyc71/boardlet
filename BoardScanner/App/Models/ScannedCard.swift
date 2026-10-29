import Foundation

struct ScannedCard: Codable, Identifiable, Sendable {
    var id = UUID()
    var row: Int
    var column: Int
    var label: String
    var message: String? = nil
    var confidence: Float
    var bounds: CGRect
    var pictureBounds: CGRect
    var imagePNG: Data
    var needsReview: Bool
    var included = true
    /// Optional for backwards compatibility with existing version-1 documents.
    var isEmpty: Bool? = nil
}
