import UIKit
import SwiftUI
import SharedSwiftUI
import SettingsFramework

/// All distances are in physical page points (72 points/inch). Raster resolution
/// affects only the context transform, never font fitting or page breaks.
struct BoardRenderStyle: Hashable {
    let cardTitleFontColor: Color
    let cardTitleFontBold: Bool
    let cardTitleFontHeightPercentage: CGFloat
    let cardTitlePosition: TopBottomPosition
    let cellFillColor: Color
    let marginPercentage: CGFloat
    let fitzgeraldBordersEnabled: Bool
    let fitzgeraldBorderWidth: CGFloat
    let gridlinesColor: Color
    let gridlinesWidth: CGFloat
    let pageTitleVisible: Bool
    let pageTitleBoldFont: Bool
    let pageTitleColor: Color
    let pageTitleHeightPercentage: CGFloat

    init(_ options: CollageFormatting) {
        cardTitleFontColor = options.cardTitleFontColor
        cardTitleFontBold = options.cardTitleFontBold
        cardTitleFontHeightPercentage = options.cardTitleFontHeightPercentage
        cardTitlePosition = options.cardTitlePosition
        cellFillColor = options.cellFillColor
        marginPercentage = options.marginPercentage
        fitzgeraldBordersEnabled = options.fitzgeraldBordersEnabled
        // Preserve the existing printed widths, expressed at 72 rather than 300 dpi.
        fitzgeraldBorderWidth = options.fitzgeraldBorderWidth * 72 / 300
        gridlinesColor = options.gridlinesColor
        gridlinesWidth = options.gridlinesWidth * 72 / 300
        pageTitleVisible = options.pageTitleVisible
        pageTitleBoldFont = options.pageTitleBoldFont
        pageTitleColor = options.pageTitleColor
        pageTitleHeightPercentage = options.pageTitleHeightPercentage
    }
}

struct BoardPageGeometry {
    let pageSize: CGSize
    let columns: Int
    let rows: Int
    let titleRect: CGRect
    let footerRect: CGRect
    let footerTextRect: CGRect
    let gridRect: CGRect
    let cellSize: CGSize

    /// The renderer and PDF context use 72 physical points per inch.
    var cellSizeInMillimetres: CGSize {
        let millimetresPerPoint: CGFloat = 25.4 / 72
        return CGSize(
            width: cellSize.width * millimetresPerPoint,
            height: cellSize.height * millimetresPerPoint
        )
    }

    static let attributionFont = UIFont.systemFont(ofSize: 5.76, weight: .light)
    static var attributionAttributes: [NSAttributedString.Key: Any] {
        [.font: attributionFont, .foregroundColor: UIColor.darkGray]
    }

    init(pageSize: CGSize, layout: PageLayout, title: String?, style: BoardRenderStyle, attribution: String?) {
        self.pageSize = pageSize
        columns = max(layout.width, 1)
        rows = max(layout.height, 1)
        let titleHeight = title?.isEmpty == false && style.pageTitleVisible
            ? pageSize.height * style.pageTitleHeightPercentage : 0
        titleRect = CGRect(x: 0, y: 0, width: pageSize.width, height: titleHeight)
        let textWidth = max(1, pageSize.width - 11.52)
        let textHeight = attribution.flatMap { text -> CGFloat? in
            guard !text.isEmpty else { return nil }
            return ceil((text as NSString).boundingRect(
                with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: Self.attributionAttributes, context: nil).height)
        } ?? 0
        let footerHeight = textHeight > 0 ? textHeight + 1.92 + 14.4 : 0
        footerRect = CGRect(x: 0, y: pageSize.height - footerHeight, width: pageSize.width, height: footerHeight)
        footerTextRect = CGRect(x: 5.76, y: footerRect.minY + 1.92, width: textWidth, height: textHeight)
        let available = CGSize(width: pageSize.width, height: max(1, pageSize.height - titleHeight - footerHeight))
        cellSize = PageLayout.cardSize(pageSize: available, pageLayout: PageLayout(
            width: columns, height: rows, fixedCardAspectRatio: layout.fixedCardAspectRatio))
        let gridSize = CGSize(width: cellSize.width * CGFloat(columns), height: cellSize.height * CGFloat(rows))
        gridRect = CGRect(x: (pageSize.width - gridSize.width) / 2,
                          y: titleHeight + (available.height - gridSize.height) / 2,
                          width: gridSize.width, height: gridSize.height)
    }

    var gridLines: [(CGPoint, CGPoint)] {
        var lines = [(CGPoint, CGPoint)]()
        for column in 0...columns {
            let x = gridRect.minX + CGFloat(column) * cellSize.width
            lines.append((CGPoint(x: x, y: gridRect.minY), CGPoint(x: x, y: gridRect.maxY)))
        }
        for row in 0...rows {
            let y = gridRect.minY + CGFloat(row) * cellSize.height
            lines.append((CGPoint(x: gridRect.minX, y: y), CGPoint(x: gridRect.maxX, y: y)))
        }
        return lines
    }

    func cellRect(slot: Int) -> CGRect {
        CGRect(x: gridRect.minX + CGFloat(slot % columns) * cellSize.width,
               y: gridRect.minY + CGFloat(slot / columns) * cellSize.height,
               width: cellSize.width, height: cellSize.height)
    }
}

/// A value snapshot: rendering never reads a mutable PhotoItem across a suspension.
struct BoardCardSnapshot {
    let id: UUID
    let revision: UUID
    let title: String?
    let image: UIImage
    let fitzgeraldKey: FitzgeraldKey
    let isPlaceholder: Bool

    init(_ photo: PhotoItem) {
        id = photo.itemID
        revision = photo.renderRevision
        title = photo.title
        image = photo.image
        fitzgeraldKey = photo.fitzgeraldKey
        isPlaceholder = photo.isPlaceholder
    }
}

struct BoardCardRenderKey: Hashable {
    let id: UUID
    let revision: UUID
    let style: CardStyle
    let width: CGFloat
    let height: CGFloat
    let pixelWidth: Int
    let pixelHeight: Int

    struct CardStyle: Hashable {
        let titleColor: Color
        let bold: Bool
        let height: CGFloat
        let position: TopBottomPosition
        let fill: Color
        let margin: CGFloat
        let borders: Bool
        let borderWidth: CGFloat
        init(_ style: BoardRenderStyle) {
            titleColor = style.cardTitleFontColor
            bold = style.cardTitleFontBold
            height = style.cardTitleFontHeightPercentage
            position = style.cardTitlePosition
            fill = style.cellFillColor
            margin = style.marginPercentage
            borders = style.fitzgeraldBordersEnabled
            borderWidth = style.fitzgeraldBorderWidth
        }
    }

    init(card: BoardCardSnapshot, style: BoardRenderStyle, size: CGSize, scale: CGFloat) {
        id = card.id
        revision = card.revision
        self.style = CardStyle(style)
        width = size.width
        height = size.height
        pixelWidth = max(1, Int(ceil(size.width * scale)))
        pixelHeight = max(1, Int(ceil(size.height * scale)))
    }
}

/// Main-actor ownership serializes UIKit image access and cache mutations. Work is
/// bounded to individual screen-sized cards; callers yield between cache misses.
@MainActor
final class BoardCardRenderCache {
    private var images: [BoardCardRenderKey: UIImage] = [:]
    private var order: [BoardCardRenderKey] = []
    private var byteCount = 0
    private(set) var renderCount = 0

    func image(card: BoardCardSnapshot, style: BoardRenderStyle, size: CGSize, scale: CGFloat) -> UIImage {
        let key = BoardCardRenderKey(card: card, style: style, size: size, scale: scale)
        if let image = images[key] { return image }
        let image = CollageFactory.renderCard(card, size: size, style: style, scale: scale)
        let cost = key.pixelWidth * key.pixelHeight * 4
        while byteCount + cost > 32 * 1024 * 1024, !order.isEmpty {
            let oldest = order.removeFirst()
            if images.removeValue(forKey: oldest) != nil {
                byteCount -= oldest.pixelWidth * oldest.pixelHeight * 4
            }
        }
        images[key] = image
        order.append(key)
        byteCount += cost
        renderCount += 1
        return image
    }
}

/// Page-level identities contain only values; they do not use debug descriptions
/// or PhotoItem equality (which may encode full-resolution images).
struct BoardThumbnailKey: Equatable {
    struct Content: Equatable {
        let id: UUID
        let revision: UUID
    }
    let pageSize: CGSize
    let columns: Int
    let rows: Int
    let fixedAspectRatio: CGFloat?
    let title: String
    let style: BoardRenderStyle
    let attribution: String?
    let repeats: Bool
    let content: [Content]
}

struct BoardDecorationKey: Equatable {
    let pageSize: CGSize
    let gridRect: CGRect
    let columns: Int
    let rows: Int
    let style: BoardRenderStyle
    let title: String
    let attribution: String?
    let scale: CGFloat
}
