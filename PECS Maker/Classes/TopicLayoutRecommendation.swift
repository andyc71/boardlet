import Foundation

/// Screen-based topic card sizes, independent of paper and print settings.
enum TopicLayoutRecommendation: String, CaseIterable, Identifiable {
    case compactSquare, compactTall, largeSquare, largeTall

    var id: String { rawValue }

    var aspectRatio: CGFloat {
        switch self {
        case .compactSquare, .largeSquare: return 1
        case .compactTall, .largeTall: return 5.0 / 7.0
        }
    }

    func cardSize(accessibility: Bool = false) -> CGSize {
        let width: CGFloat
        switch self {
        case .compactSquare, .compactTall: width = accessibility ? 180 : 100
        case .largeSquare, .largeTall: width = accessibility ? 220 : 140
        }
        return CGSize(width: width, height: width / aspectRatio)
    }

    func columns(in viewportWidth: CGFloat, accessibility: Bool = false) -> Int {
        Self.columns(in: viewportWidth, preferredWidth: cardSize(accessibility: accessibility).width)
    }
    func cardSize(in viewportWidth: CGFloat, accessibility: Bool = false) -> CGSize {
        Self.fittedCardSize(in: viewportWidth,
                           columns: columns(in: viewportWidth, accessibility: accessibility),
                           aspectRatio: aspectRatio)
    }

    static func columns(in viewportWidth: CGFloat, preferredWidth: CGFloat) -> Int {
        max(1, Int((max(0, viewportWidth - 40) + 12) / (preferredWidth + 12)))
    }

    static func fittedCardSize(in viewportWidth: CGFloat, columns: Int, aspectRatio: CGFloat) -> CGSize {
        ScreenCardGridGeometry.fillingWidth(viewportWidth, columns: columns, rows: 1,
                                             cardAspectRatio: aspectRatio).cardSize
    }
}
