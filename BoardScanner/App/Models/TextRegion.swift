import Foundation

struct TextRegion: Sendable {
    let text: String
    let confidence: Float
    let bounds: CGRect
}
