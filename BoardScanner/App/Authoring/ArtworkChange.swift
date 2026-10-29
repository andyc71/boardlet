import Foundation

enum ArtworkChange: Sendable {
    case unchanged
    case remove
    case replace(Data)
}
