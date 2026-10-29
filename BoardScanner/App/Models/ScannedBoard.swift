import Foundation

struct ScannedBoard: Codable, Sendable {
    var version = 1
    var title = "My choice board"
    var columns: Int
    var rows: Int
    var cards: [ScannedCard]
    var sourcePNG: Data
    var method: String

    func validate() throws {
        guard version == 1, (1...12).contains(columns), (1...12).contains(rows),
              cards.count == rows * columns, sourcePNG.count <= 40_000_000,
              Set(cards.map(\.id)).count == cards.count,
              Set(cards.map { $0.row * columns + $0.column }).count == cards.count else {
            throw ScanError.invalidBoard
        }
        for card in cards {
            guard (0..<rows).contains(card.row), (0..<columns).contains(card.column),
                  card.bounds.isUnitRect, card.pictureBounds.isUnitRect,
                  card.bounds.insetBy(dx: -0.001, dy: -0.001).contains(card.pictureBounds),
                  card.imagePNG.count <= 10_000_000, card.confidence.isFinite else {
                throw ScanError.invalidBoard
            }
        }
    }
}

extension CGRect {
    /// All pipeline geometry uses normalized, top-left coordinates, including persisted crops.
    var isUnitRect: Bool {
        [minX, minY, width, height].allSatisfy(\.isFinite) && width > 0 && height > 0
        && minX >= 0 && minY >= 0 && maxX <= 1.00001 && maxY <= 1.00001
    }

    static func fromVision(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: 1 - rect.maxY, width: rect.width, height: rect.height)
    }
}
