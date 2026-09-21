import Foundation
import UIKit

struct BoardRenderColor: Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    @MainActor
    init(_ color: UIColor) {
        let resolved = color.resolvedColor(with: UITraitCollection.current)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if !resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            var white: CGFloat = 0
            resolved.getWhite(&white, alpha: &alpha)
            red = white
            green = white
            blue = white
        }
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

struct BoardRenderItem: Sendable {
    let imageData: Data
    let title: String?
    let borderColor: BoardRenderColor?
}

struct BoardRenderStyle: Sendable {
    let pageTitleVisible: Bool
    let pageTitleColor: BoardRenderColor
    let pageTitleBold: Bool
    let pageTitleHeightFraction: Double
    let cardTitleColor: BoardRenderColor
    let cardTitleBold: Bool
    let cardTitleHeightFraction: Double
    let cardTitleAtTop: Bool
    let cellFillColor: BoardRenderColor
    let marginFraction: Double
    let gridColor: BoardRenderColor
    let gridWidth: Double
    let borderWidth: Double
}

struct BoardRenderSnapshot: Sendable {
    let title: String
    let items: [BoardRenderItem]
    let columns: Int
    let rows: Int
    let fixedCardAspectRatio: Double?
    let pageWidth: Double
    let pageHeight: Double
    let repeatSingleItem: Bool
    let style: BoardRenderStyle
}

struct RenderedBoardPage: Sendable {
    let index: Int
    let pngData: Data
}

enum BoardRendererError: Error, LocalizedError {
    case invalidPageSize
    case invalidGrid
    case invalidImage
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidPageSize: "The board page size is invalid."
        case .invalidGrid: "The board grid is invalid."
        case .invalidImage: "A board image could not be decoded."
        case .imageEncodingFailed: "A rendered board page could not be encoded."
        }
    }
}

/// UIKit rendering is serialized away from the main actor. Inputs and outputs are
/// immutable values so views never share mutable editor state with the renderer.
actor BoardRenderer {
    func render(_ snapshot: BoardRenderSnapshot) throws -> [RenderedBoardPage] {
        guard snapshot.pageWidth > 0, snapshot.pageHeight > 0 else {
            throw BoardRendererError.invalidPageSize
        }
        guard snapshot.columns > 0, snapshot.rows > 0 else {
            throw BoardRendererError.invalidGrid
        }

        var items = snapshot.items
        if snapshot.repeatSingleItem, let item = items.first, items.count == 1 {
            items = Array(repeating: item, count: snapshot.columns * snapshot.rows)
        }
        if items.isEmpty {
            items = [BoardRenderItem(imageData: Data(), title: nil, borderColor: nil)]
        }

        let countPerPage = snapshot.columns * snapshot.rows
        return try stride(from: 0, to: items.count, by: countPerPage).enumerated().map { pageIndex, start in
            let end = min(start + countPerPage, items.count)
            let pageItems = Array(items[start..<end])
            return RenderedBoardPage(
                index: pageIndex,
                pngData: try renderPage(pageItems, snapshot: snapshot)
            )
        }
    }

    func renderPDF(_ snapshot: BoardRenderSnapshot) throws -> Data {
        let pages = try render(snapshot)
        let pageRect = CGRect(
            x: 0,
            y: 0,
            width: snapshot.pageWidth,
            height: snapshot.pageHeight
        )
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Boardlet",
            kCGPDFContextAuthor as String: "meetmyfamily.org",
            kCGPDFContextTitle as String: "Choice Board"
        ]
        return UIGraphicsPDFRenderer(bounds: pageRect, format: format).pdfData { context in
            for page in pages {
                guard let image = UIImage(data: page.pngData) else { continue }
                context.beginPage()
                image.draw(in: pageRect)
            }
        }
    }

    private func renderPage(
        _ items: [BoardRenderItem],
        snapshot: BoardRenderSnapshot
    ) throws -> Data {
        let pageSize = CGSize(width: snapshot.pageWidth, height: snapshot.pageHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: pageSize, format: format)
        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext
            context.setFillColor(snapshot.style.cellFillColor.uiColor.cgColor)
            context.fill(CGRect(origin: .zero, size: pageSize))

            var gridFrame = CGRect(origin: .zero, size: pageSize)
            if snapshot.style.pageTitleVisible, !snapshot.title.isEmpty {
                let titleHeight = pageSize.height * snapshot.style.pageTitleHeightFraction
                draw(
                    snapshot.title,
                    in: CGRect(x: 0, y: 0, width: pageSize.width, height: titleHeight),
                    color: snapshot.style.pageTitleColor.uiColor,
                    bold: snapshot.style.pageTitleBold
                )
                gridFrame.origin.y = titleHeight
                gridFrame.size.height -= titleHeight
            }

            var cardWidth = gridFrame.width / CGFloat(snapshot.columns)
            var cardHeight = gridFrame.height / CGFloat(snapshot.rows)
            if let fixedRatio = snapshot.fixedCardAspectRatio {
                if snapshot.columns == 1 {
                    cardWidth = cardHeight / fixedRatio
                } else if snapshot.rows == 1 {
                    cardHeight = cardWidth / fixedRatio
                }
            }

            let occupiedWidth = cardWidth * CGFloat(snapshot.columns)
            let occupiedHeight = cardHeight * CGFloat(snapshot.rows)
            let gridOrigin = CGPoint(
                x: gridFrame.minX + ((gridFrame.width - occupiedWidth) / 2),
                y: gridFrame.minY + ((gridFrame.height - occupiedHeight) / 2)
            )

            for (index, item) in items.enumerated() {
                let row = index / snapshot.columns
                let column = index % snapshot.columns
                let cell = CGRect(
                    x: gridOrigin.x + CGFloat(column) * cardWidth,
                    y: gridOrigin.y + CGFloat(row) * cardHeight,
                    width: cardWidth,
                    height: cardHeight
                )
                draw(item, in: cell, style: snapshot.style, context: context)
            }

            context.setStrokeColor(snapshot.style.gridColor.uiColor.cgColor)
            context.setLineWidth(snapshot.style.gridWidth)
            for row in 0...snapshot.rows {
                let y = gridOrigin.y + CGFloat(row) * cardHeight
                context.strokeLineSegments(between: [
                    CGPoint(x: gridOrigin.x, y: y),
                    CGPoint(x: gridOrigin.x + occupiedWidth, y: y)
                ])
            }
            for column in 0...snapshot.columns {
                let x = gridOrigin.x + CGFloat(column) * cardWidth
                context.strokeLineSegments(between: [
                    CGPoint(x: x, y: gridOrigin.y),
                    CGPoint(x: x, y: gridOrigin.y + occupiedHeight)
                ])
            }
        }
        guard let data = image.pngData() else {
            throw BoardRendererError.imageEncodingFailed
        }
        return data
    }

    private func draw(
        _ item: BoardRenderItem,
        in cell: CGRect,
        style: BoardRenderStyle,
        context: CGContext
    ) {
        let margin = cell.width * style.marginFraction
        var content = cell.insetBy(dx: margin, dy: margin)

        if let borderColor = item.borderColor {
            context.setStrokeColor(borderColor.uiColor.cgColor)
            context.setLineWidth(style.borderWidth)
            context.stroke(content)
            content = content.insetBy(dx: margin, dy: margin)
        }

        var imageFrame = content
        if let title = item.title, !title.isEmpty {
            var labelHeight = max(5, content.height * style.cardTitleHeightFraction)
            let spacing = labelHeight * 0.5
            let descriptor = UIFont.systemFont(
                ofSize: 30,
                weight: style.cardTitleBold ? .bold : .regular
            ).fontDescriptor
            let font = UIFont.fontFittingText(
                title,
                in: CGSize(width: content.width, height: labelHeight),
                fontDescriptor: descriptor,
                option: .fillContainer
            ) ?? UIFont.systemFont(ofSize: labelHeight, weight: style.cardTitleBold ? .bold : .regular)
            labelHeight = max(labelHeight, font.pointSize)
            let labelFrame: CGRect
            if style.cardTitleAtTop {
                labelFrame = CGRect(x: content.minX, y: content.minY, width: content.width, height: labelHeight)
                imageFrame.origin.y += labelHeight + spacing
            } else {
                labelFrame = CGRect(x: content.minX, y: content.maxY - labelHeight, width: content.width, height: labelHeight)
            }
            imageFrame.size.height -= labelHeight + spacing
            draw(title, in: labelFrame, color: style.cardTitleColor.uiColor, font: font)
        }

        guard let image = UIImage(data: item.imageData), image.size.width > 0, image.size.height > 0 else {
            return
        }
        let widthDifference = abs(imageFrame.width - image.size.width)
        let heightDifference = abs(imageFrame.height - image.size.height)
        var size: CGSize
        if widthDifference < heightDifference {
            size = fittedSize(for: image.size, width: imageFrame.width)
            if size.height > imageFrame.height {
                size = fittedSize(for: image.size, height: imageFrame.height)
            }
        } else {
            size = fittedSize(for: image.size, height: imageFrame.height)
            if size.width > imageFrame.width {
                size = fittedSize(for: image.size, width: imageFrame.width)
            }
        }
        let frame = CGRect(
            x: imageFrame.midX - size.width / 2,
            y: imageFrame.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        image.draw(in: frame)
    }

    private func fittedSize(for imageSize: CGSize, width: CGFloat) -> CGSize {
        let multiplier = imageSize.width / width
        return CGSize(width: width, height: imageSize.height / multiplier)
    }

    private func fittedSize(for imageSize: CGSize, height: CGFloat) -> CGSize {
        let multiplier = imageSize.height / height
        return CGSize(width: imageSize.width / multiplier, height: height)
    }

    private func draw(_ text: String, in frame: CGRect, color: UIColor, bold: Bool) {
        let inset = frame.insetBy(dx: frame.height * 0.2, dy: frame.height * 0.2)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail
        let descriptor = UIFont.systemFont(ofSize: 60, weight: bold ? .bold : .regular).fontDescriptor
        let font = UIFont.fontFittingText(
            text,
            in: inset.size,
            fontDescriptor: descriptor,
            option: .fillContainer
        ) ?? UIFont.systemFont(ofSize: max(5, inset.height), weight: bold ? .bold : .regular)
        text.draw(
            with: inset,
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph],
            context: nil
        )
    }

    private func draw(_ text: String, in frame: CGRect, color: UIColor, font: UIFont) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        text.draw(
            with: frame,
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph],
            context: nil
        )
    }
}

extension PageLayoutState {
    func renderPages(isForPrinting: Bool, maxScreenWidth: CGFloat = .infinity) async throws -> [CollageItem] {
        let snapshot = try makeRenderSnapshot(
            isForPrinting: isForPrinting,
            maxScreenWidth: maxScreenWidth
        )
        let pages = try await boardRenderer.render(snapshot)
        let collageItems = try pages.map { page in
            guard let image = UIImage(data: page.pngData) else {
                throw BoardRendererError.invalidImage
            }
            return CollageItem(image: image, index: page.index)
        }
        if !isForPrinting, generateTopicThumbnail, let firstImage = collageItems.first?.image {
            applyGeneratedTopicThumbnail(firstImage)
        }
        return collageItems
    }

    func createShareableItemsAsync(format: ExportCollageFormat) async throws -> [Any] {
        let snapshot = try makeRenderSnapshot(isForPrinting: true, maxScreenWidth: .infinity)
        switch format {
        case .image:
            let pages = try await boardRenderer.render(snapshot)
            return try pages.map { page in
                guard let image = UIImage(data: page.pngData) else {
                    throw BoardRendererError.invalidImage
                }
                return image
            }
        case .pdf:
            let data = try await boardRenderer.renderPDF(snapshot)
            deleteTempFiles()
            let fileName = createUniqueFilename(baseName: "Choice Board", fileExtension: "pdf")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: url, options: .atomic)
            tempPDF = url
            if AppSettings.keepPDFs {
                createArchive(of: url)
            }
            return [url]
        }
    }

    private func makeRenderSnapshot(
        isForPrinting: Bool,
        maxScreenWidth: CGFloat
    ) throws -> BoardRenderSnapshot {
        let pagePixels: CGSize
        if isForPrinting {
            pagePixels = pageMeasurements2.convertWithDPI(300)
        } else {
            pagePixels = pageMeasurements2.convertToScreenMeasurements(.maxWidth(maxScreenWidth))
        }

        let items = try photoBrowserData.photoItems.map { item -> BoardRenderItem in
            guard let imageData = item.image.pngData() else {
                throw BoardRendererError.imageEncodingFailed
            }
            let borderColor = item.fitzgeraldKey == .none
                ? nil
                : BoardRenderColor(item.fitzgeraldKey.color)
            return BoardRenderItem(imageData: imageData, title: item.title, borderColor: borderColor)
        }
        let formatting = topic.formatting
        let style = BoardRenderStyle(
            pageTitleVisible: formatting.pageTitleVisible,
            pageTitleColor: BoardRenderColor(formatting.pageTitleColor.toUIColor() ?? .black),
            pageTitleBold: formatting.pageTitleBoldFont,
            pageTitleHeightFraction: formatting.pageTitleHeightPercentage,
            cardTitleColor: BoardRenderColor(formatting.cardTitleFontColor.toUIColor() ?? .black),
            cardTitleBold: formatting.cardTitleFontBold,
            cardTitleHeightFraction: formatting.cardTitleFontHeightPercentage,
            cardTitleAtTop: formatting.cardTitlePosition == .top,
            cellFillColor: BoardRenderColor(formatting.cellFillColor.toUIColor() ?? .white),
            marginFraction: formatting.marginPercentage,
            gridColor: BoardRenderColor(formatting.gridlinesColor.toUIColor() ?? .black),
            gridWidth: formatting.gridlinesWidth,
            borderWidth: formatting.fitzgeraldBorderWidth
        )
        return BoardRenderSnapshot(
            title: title,
            items: items,
            columns: pageLayout.width,
            rows: pageLayout.height,
            fixedCardAspectRatio: pageLayout.fixedCardAspectRatio.map(Double.init),
            pageWidth: Double(pagePixels.width),
            pageHeight: Double(pagePixels.height),
            repeatSingleItem: repeatSinglePhoto,
            style: style
        )
    }
}
