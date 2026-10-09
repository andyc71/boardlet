//
//  CollageFactory.swift
//  SimpleCollageMaker
//
//  Created by Andy on 19/09/2021.
//  Copyright © 2021 Aj. All rights reserved.
//

import SwiftUI
import LogFramework
import SharedSwiftUI
import SettingsFramework

class CollageFactory {

    static func createCollage(from images: [PhotoItem], gridSize: PageLayoutType = PageLayoutType(width: 3, height: 3),
                              pageSize: CGSize = CGSize(width: 2100, height: 3000), pageTitle: String?,
                              options: CollageFormatting, attribution: String? = nil,
                              canonicalPageSize: CGSize? = nil) -> UIImage? {
        guard pageSize.width > 0, pageSize.height > 0 else { return nil }
        let canonical = canonicalPageSize ?? CGSize(width: 595.28, height: 595.28 * pageSize.height / pageSize.width)
        let style = BoardRenderStyle(options)
        let geometry = BoardPageGeometry(pageSize: canonical, layout: gridSize,
                                         title: pageTitle, style: style, attribution: attribution)
        let rendered = render(size: canonical, scale: pageSize.width / canonical.width) { context in
            (style.cellFillColor.toUIColor() ?? .white).setFill()
            context.fill(CGRect(origin: .zero, size: canonical))
            for (slot, photo) in images.prefix(geometry.columns * geometry.rows).enumerated() {
                context.saveGState()
                let rect = geometry.cellRect(slot: slot)
                context.translateBy(x: rect.minX, y: rect.minY)
                drawCard(BoardCardSnapshot(photo), size: geometry.cellSize, context: context, options: style)
                context.restoreGState()
            }
            drawPageDecoration(geometry: geometry, title: pageTitle, attribution: attribution, style: style, context: context)
        }
        // Preserve the public page-image contract: size is the requested pixel size.
        return rendered.cgImage.map { UIImage(cgImage: $0) }
    }

    static func render(size: CGSize, scale: CGFloat, draw: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(scale, 0.01)
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in draw(renderer.cgContext) }
    }

    static func renderCard(_ card: BoardCardSnapshot, size: CGSize, style: BoardRenderStyle, scale: CGFloat) -> UIImage {
        render(size: size, scale: scale) { drawCard(card, size: size, context: $0, options: style) }
    }

    static func renderPageDecoration(geometry: BoardPageGeometry, title: String?, attribution: String?,
                                     style: BoardRenderStyle, scale: CGFloat) -> UIImage {
        render(size: geometry.pageSize, scale: scale) {
            drawPageDecoration(geometry: geometry, title: title, attribution: attribution, style: style, context: $0)
        }
    }

    /// Rasterize only the title/footer strip for the screen; gridlines are vectors.
    static func renderDecorationRegion(_ rect: CGRect, geometry: BoardPageGeometry,
                                       title: String?, attribution: String?, style: BoardRenderStyle,
                                       scale: CGFloat) -> UIImage? {
        guard rect.width > 0, rect.height > 0 else { return nil }
        return render(size: rect.size, scale: scale) { context in
            context.translateBy(x: -rect.minX, y: -rect.minY)
            drawPageDecoration(geometry: geometry, title: title, attribution: attribution, style: style, context: context)
        }
    }

    static func drawPageDecoration(geometry: BoardPageGeometry, title: String?, attribution: String?,
                                  style: BoardRenderStyle, context: CGContext) {
        if let title, geometry.titleRect.height > 0 {
            drawPageTitle(context: context, title: title, titleRect: geometry.titleRect,
                          titleMargin: geometry.titleRect.height * 0.2, options: style)
        }
        context.setStrokeColor((style.gridlinesColor.toUIColor() ?? .black).cgColor)
        context.setLineWidth(style.gridlinesWidth)
        for line in geometry.gridLines {
            context.strokeLineSegments(between: [line.0, line.1])
        }
        if let attribution, geometry.footerRect.height > 0 {
            context.setFillColor(UIColor.white.cgColor)
            context.fill(geometry.footerRect)
            (attribution as NSString).draw(with: geometry.footerTextRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: BoardPageGeometry.attributionAttributes, context: nil)
        }
    }

    static func drawCard(_ card: BoardCardSnapshot, size cellSize: CGSize, context: CGContext, options: BoardRenderStyle) {
        let cellOrigin = CGPoint.zero
        let image = card.image
        context.saveGState()
        defer { context.restoreGState() }
        context.clip(to: CGRect(origin: .zero, size: cellSize))
        context.setFillColor((options.cellFillColor.toUIColor() ?? .white).cgColor)
        context.fill(CGRect(origin: .zero, size: cellSize))
        //Put a margin on in the cell
        let margin: CGFloat = cellSize.width * options.marginPercentage
        let newCellOrigin = CGPoint(x: cellOrigin.x + margin, y: cellOrigin.y + margin)
        let newCellSize = CGSize(width: cellSize.width-(2*margin), height: cellSize.height-(2*margin))
        var newCellRect = CGRect(origin: newCellOrigin, size: newCellSize)

        //If we need to draw a border, do that now.
        if options.fitzgeraldBordersEnabled && card.fitzgeraldKey != .none {

            //Draw the cell frame

            let borderColor = card.fitzgeraldKey.color

            let borderRect = newCellRect

            context.setLineWidth(options.fitzgeraldBorderWidth)
            context.setStrokeColor(borderColor.cgColor)
            context.stroke(borderRect)

            newCellRect = CGRect(x: newCellRect.minX + margin,
                               y: newCellRect.minY + margin,
                               width: newCellRect.width - (2 * margin),
                               height: newCellRect.height - (2 * margin))
        }

        //Start off with the asssumption that the photo fills the cell.
        var photoRect = newCellRect

        //If we have labels, calcluate the rect for the title and shrink
        //the photo rect accordingly
        if let labelText = card.title {

            if labelText.count > 0 {

                let labelHeightPercent = options.cardTitleFontHeightPercentage
                var labelHeight = newCellRect.height * labelHeightPercent
                if labelHeight < 1.2 { labelHeight = 1.2 }

                let labelWidth = photoRect.width
                let labelSpacing = labelHeight * 0.5

                let descriptor = UIFont.systemFont(ofSize: 30, weight: options.cardTitleFontBold ? .bold : .regular).fontDescriptor

                guard let labelFont = UIFont.fontFittingText(labelText, in: CGSize(width: labelWidth, height: labelHeight), fontDescriptor: descriptor, option: .fillContainer) else {
                    logger.logError(.general, "Unable to create font for collage label with max height of \(labelHeight)")
                    return
                }

                if labelHeight < labelFont.pointSize {
                    labelHeight = labelFont.pointSize
                }

                let labelSize = CGSize(width: labelWidth, height: labelHeight)
                let labelAndPhotoRects = calcLabelAndPhotoRects(cellRect: newCellRect, labelSize: labelSize, labelSpacing: labelSpacing, labelPosition: options.cardTitlePosition)
                let labelRect = labelAndPhotoRects.labelRect
                photoRect = labelAndPhotoRects.photoRect


                let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center

                let attrs = [
                    NSAttributedString.Key.font: labelFont,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.foregroundColor: options.cardTitleFontColor.toUIColor() ?? UIColor.black
                ] as [NSAttributedString.Key : Any]

                labelText.draw(with: labelRect, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            }
        }

        guard image.size.width > 0, image.size.height > 0,
              photoRect.width > 0, photoRect.height > 0 else { return }
        let fit = min(photoRect.width / image.size.width, photoRect.height / image.size.height)
        let size = CGSize(width: image.size.width * fit, height: image.size.height * fit)
        image.draw(in: CGRect(x: photoRect.midX - size.width / 2, y: photoRect.midY - size.height / 2,
                              width: size.width, height: size.height))
    }

    static func drawPageTitle(context: CGContext, title: String, titleRect: CGRect, titleMargin: CGFloat, options: BoardRenderStyle) {

        // Create title area with margin
        let titleDrawRect = CGRect(
            x: titleRect.minX + titleMargin,
            y: titleRect.minY + titleMargin,
            width: titleRect.width - (2 * titleMargin),
            height: titleRect.height - (2 * titleMargin)
        )

        // Create font descriptor
        let descriptor = UIFont.systemFont(ofSize: 60, weight: options.pageTitleBoldFont ? .bold : .regular).fontDescriptor

        // Get font that fits the available space
        guard let titleFont = UIFont.fontFittingText(title, in: titleDrawRect.size, fontDescriptor: descriptor, option: .fillContainer) else {
            logger.logError(.general, "Unable to create font for page title")
            return
        }

        // Set up paragraph style for center alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        //paragraphStyle.alignment = options.pageTitleAlignment.toNSTextAlignment()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        // Create attributes for the title
        let titleAttributes = [
            NSAttributedString.Key.font: titleFont,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: options.pageTitleColor.toUIColor() ?? UIColor.black
        ] as [NSAttributedString.Key : Any]

        // Draw the title
        title.draw(with: titleDrawRect, options: .usesLineFragmentOrigin, attributes: titleAttributes, context: nil)
    }

    static func calcLabelAndPhotoRects(cellRect: CGRect, labelSize: CGSize, labelSpacing: CGFloat, labelPosition: TopBottomPosition) -> (labelRect: CGRect, photoRect: CGRect) {
        switch labelPosition {
        case .bottom:
            let labelRect = CGRect(x: cellRect.minX,
                                   y: cellRect.maxY - labelSize.height,
                                   width: labelSize.width,
                                   height: labelSize.height)

            let photoRect = CGRect(x: cellRect.minX,
                                   y: cellRect.minY,
                                   width: cellRect.width,
                                   height: cellRect.height - (labelSize.height + labelSpacing))
            return (labelRect, photoRect)

        case .top:
            let labelRect = CGRect(x: cellRect.minX,
                                   y: cellRect.minY,
                                   width: labelSize.width,
                                   height: labelSize.height)

            let photoRect = CGRect(x: cellRect.minX,
                                   y: labelRect.maxY + labelSpacing,
                                   width: cellRect.width,
                                   height: cellRect.height - (labelSize.height + labelSpacing))
            return (labelRect, photoRect)
        }
    }

}
