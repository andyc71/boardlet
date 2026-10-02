import Foundation

struct PrintSettings: Codable, Equatable, Sendable {
    var paper: Paper = .a4
    var landscape = false
    var columns = 2
    var rows = 3
    var marginFraction = 0.05
    var borderWidth = 1.0
    var borderColor = "#CCD3DB"
    var background = "#FFFFFF"
    var labelColor = "#182435"
    var labelBold = true
    var labelFraction = 0.18
    var labelsAbove = false
    var showLabels = true
    var showTitle = true
    var titleBold = true
    var titleColor = "#182435"
    var titleFraction = 0.06
    var categoryBorders = false
    var categoryBorderWidth = 4.0
    var repeatSingle = false
    var fixedCardAspectRatio: Double?

    var capacity: Int { max(1, columns) * max(1, rows) }
    var sizeMM: CGSize {
        let size = paper.sizeMM
        return landscape ? CGSize(width: size.height, height: size.width) : size
    }
    var sizePoints: CGSize {
        CGSize(width: sizeMM.width * 72 / 25.4, height: sizeMM.height * 72 / 25.4)
    }
    func pageIndices(cardCount: Int) -> [[Int]] {
        guard cardCount > 0 else { return [[]] }
        if repeatSingle, cardCount == 1 { return [Array(repeating: 0, count: capacity)] }
        return stride(from: 0, to: cardCount, by: capacity).map { start in
            Array(start..<min(start + capacity, cardCount))
        }
    }
}

enum Paper: String, Codable, CaseIterable, Sendable {
    case a4 = "A4", a5 = "A5", letter = "US Letter", quarto = "8x10in (UK Quarto)", photo = "10x15cm Photo Paper"
    var sizeMM: CGSize {
        switch self {
        case .a4: CGSize(width: 210, height: 297)
        case .a5: CGSize(width: 148, height: 210)
        case .letter: CGSize(width: 215.9, height: 279.4)
        case .quarto: CGSize(width: 203.2, height: 254)
        case .photo: CGSize(width: 100, height: 150)
        }
    }
}
