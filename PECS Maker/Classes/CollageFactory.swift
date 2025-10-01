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

    static func createCollage( from images: [PhotoItem], gridSize: PageLayoutType = PageLayoutType(width: 3, height: 3), pageSize: CGSize = CGSize(width: 2100, height: 3000), pageTitle: String?, options: CollageFormatting
    ) -> UIImage? {

        guard pageSize.width > 0, pageSize.height > 0 else {
            logger.logError(.general, "Invalid page size: \(pageSize)")
            return nil
        }
        
        logger.logDebug(.general, "Page size: \(pageSize)")
        
        UIGraphicsBeginImageContextWithOptions(pageSize, false, 1.0)
        defer {
            UIGraphicsEndImageContext()
        }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            logger.logError(.general, "Failed to create CGContext")
            return nil
        }
        
        let cellColor = options.cellFillColor.toUIColor()?.cgColor ?? UIColor.lightGray.cgColor
        context.setFillColor(cellColor)
        context.fill(CGRect(origin: .zero, size: pageSize))
        
        // Calculate title area and adjust available space for grid
        var titleRect = CGRect.zero
        var availablePageSize = pageSize
        var gridOffset = CGPoint.zero
        
        if let title = pageTitle, !title.isEmpty && options.pageTitleVisible {
            let titleAreaHeight = pageSize.height * options.pageTitleHeightPercentage
            let titleMargin = titleAreaHeight * 0.2 // 20% margin within title area
            
            titleRect = CGRect(x: 0, y: 0, width: pageSize.width, height: titleAreaHeight)
            
            // Adjust available space for the grid
            availablePageSize = CGSize(width: pageSize.width, height: pageSize.height - titleAreaHeight)
            gridOffset = CGPoint(x: 0, y: titleAreaHeight)
            
            // Draw title
            drawPageTitle(context: context, title: title, titleRect: titleRect, titleMargin: titleMargin, options: options)
        }
        
        let cellSize = PageLayout.cardSize(pageSize: availablePageSize, pageLayout: gridSize)
        
        //Iterate through the rows and columns
        var imageIndex = 0
        for row in 0..<Int(gridSize.height) {
            for col in 0..<Int(gridSize.width) {
                
                let cellOrigin: CGPoint = calcCellOrigin(row: row, col: col, cellSize: cellSize, gridSize: gridSize, pageSize: availablePageSize, offset: gridOffset)
                let cellRect = CGRect(origin: cellOrigin, size: cellSize)
                
                context.setFillColor(cellColor)
                context.fill(cellRect)

                if imageIndex > images.count - 1 {
                    continue
                }
                
                let photoItem = images[imageIndex]
                let image = photoItem.image
                
                //Put a margin on in the cell
                let margin: CGFloat = cellSize.width * options.marginPercentage
                let newCellOrigin = CGPoint(x: cellOrigin.x + margin, y: cellOrigin.y + margin)
                let newCellSize = CGSize(width: cellSize.width-(2*margin), height: cellSize.height-(2*margin))
                var newCellRect = CGRect(origin: newCellOrigin, size: newCellSize)

                //If we need to draw a border, do that now.
                if photoItem.fitzgeraldKey != .none {
                    
                    //Draw the cell frame
                    
                    let borderColor = photoItem.fitzgeraldKey.color
                    
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
                if let labelText = photoItem.title {
                                        
                    if labelText.count > 0 {
                    
                        let labelHeightPercent = options.cardTitleFontHeightPercentage
                        var labelHeight = newCellRect.height * labelHeightPercent
                        if labelHeight < 5.0 { labelHeight = 5.0 }
                        
                        let labelWidth = photoRect.width
                        let labelSpacing = labelHeight * 0.5

                        let descriptor = UIFont.systemFont(ofSize: 30, weight: options.cardTitleFontBold ? .bold : .regular).fontDescriptor
                        
                        guard let labelFont = UIFont.fontFittingText(labelText, in: CGSize(width: labelWidth, height: labelHeight), fontDescriptor: descriptor, option: .fillContainer) else {
                            logger.logError(.general, "Unable to create font for collage label with max height of \(labelHeight)")
                            return nil
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
                
                var targetImageSize: CGSize!
                //Work out the image size within the target rectangle so it gets stretched/shrunk.
                //Resize based on width or height, depending on which is the closest match.
                let widthDiff = abs(photoRect.width - image.size.width)
                let heightDiff = abs(photoRect.height - image.size.height)
                if widthDiff < heightDiff {
                    targetImageSize = calcImageSizeFromCellWidth(image: image, cellWidth: photoRect.width)
                    if targetImageSize.height > photoRect.height {
                        targetImageSize = calcImageSizeFromCellHeight(image: image, cellHeight: photoRect.height)
                    }
                }
                else {
                    targetImageSize = calcImageSizeFromCellHeight(image: image, cellHeight: photoRect.height)
                    if targetImageSize.width > photoRect.width {
                        targetImageSize = calcImageSizeFromCellWidth(image: image, cellWidth: photoRect.width)
                    }
                }
                let imageOriginWithinCell = CGPoint(
                    x: (photoRect.size.width - targetImageSize.width) / 2,
                    y: (photoRect.size.height - targetImageSize.height) / 2
                )
                let imageOriginWithinPage = CGPoint(x: imageOriginWithinCell.x + photoRect.origin.x,
                                                    y: imageOriginWithinCell.y + photoRect.origin.y)
                photoRect = CGRect(origin: imageOriginWithinPage, size: targetImageSize)
                
                image.draw(in: photoRect)
                imageIndex += 1
            }
        }
        
        drawGridlines(context: context, pageSize: availablePageSize, gridSize: gridSize, cellSize: cellSize, lineColor: options.gridlinesColor, lineWidth: options.gridlinesWidth, offset: gridOffset)
        
        guard let cgImage = context.makeImage() else {
            print("Failed to create CGImage")
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        
        return image
    }
    
    static func drawPageTitle(context: CGContext, title: String, titleRect: CGRect, titleMargin: CGFloat, options: CollageFormatting) {
        
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
    
    static func calcCellOrigin(row: Int, col: Int, cellSize: CGSize, gridSize: PageLayoutType, pageSize: CGSize, offset: CGPoint = .zero) -> CGPoint {
        
        let totalWidth = calcWidthOfAllCellsInRow(cellSize: cellSize, gridSize: gridSize)
        let totalHeight = calcHeightOfAllCellsInColumn(cellSize: cellSize, gridSize: gridSize)
        
        let leftMargin: CGFloat = (pageSize.width - totalWidth) / 2
        let topMargin: CGFloat = (pageSize.height - totalHeight) / 2
        let cellOrigin = CGPoint(
            x: offset.x + leftMargin + (CGFloat(col) * cellSize.width),
            y: offset.y + topMargin + (CGFloat(row) * cellSize.height)
        )
        
        return cellOrigin
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
    
    static func calcImageSizeFromCellHeight(image: UIImage, cellHeight: CGFloat) -> CGSize {
        
        let multiplier = image.size.height / cellHeight
        let targetImageSize = CGSize(
            width: image.size.width / multiplier,
            height: cellHeight
        )

        return targetImageSize
        
    }

    
    static func calcImageSizeFromCellWidth(image: UIImage, cellWidth: CGFloat) -> CGSize {
        
        let multiplier = image.size.width / cellWidth
        let targetImageSize = CGSize(
            width: cellWidth,
            height: image.size.height / multiplier
        )
        
        return targetImageSize
        
    }
    
    static func createLabelFont(maxHeight: CGFloat) -> UIFont? {
        let fontHeight = maxHeight
        let tempFont = UIFont.systemFont(ofSize: fontHeight)
        return tempFont
    }

    static func calcWidthOfAllCellsInRow(cellSize: CGSize, gridSize: PageLayoutType) -> CGFloat {
        return CGFloat(gridSize.width) * cellSize.width
    }
    static func calcHeightOfAllCellsInColumn(cellSize: CGSize, gridSize: PageLayoutType) -> CGFloat {
        return CGFloat(gridSize.height) * cellSize.height
    }

    static func drawGridlines(context: CGContext, pageSize: CGSize, gridSize: PageLayoutType, cellSize: CGSize, lineColor: Color, lineWidth: CGFloat, offset: CGPoint = .zero) {
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor.toUIColor()?.cgColor ?? UIColor.black.cgColor)

        //Draw the lines across the page.
        for row in 0...Int(gridSize.height) {
                let cellOrigin = calcCellOrigin(row: row, col: 0, cellSize: cellSize, gridSize: gridSize, pageSize: pageSize, offset: offset)
                let rowWidth = calcWidthOfAllCellsInRow(cellSize: cellSize, gridSize: gridSize)
                
                let rowStartPoint = CGPoint(x: cellOrigin.x, y: cellOrigin.y)
                let rowEndPoint = CGPoint(x: cellOrigin.x + rowWidth, y: rowStartPoint.y)
                
                context.strokeLineSegments(between: [rowStartPoint, rowEndPoint])
            }

        //Draw the lines down the page.
        for col in 0...Int(gridSize.width) {
                let cellOrigin = calcCellOrigin(row: 0, col: col, cellSize: cellSize, gridSize: gridSize, pageSize: pageSize, offset: offset)
                let rowHeight = calcHeightOfAllCellsInColumn(cellSize: cellSize, gridSize: gridSize)

                let columnStartPoint = CGPoint(x: cellOrigin.x, y: cellOrigin.y)
                let columnEndPoint = CGPoint(x: cellOrigin.x, y: cellOrigin.y + rowHeight)
                
                context.strokeLineSegments(between: [columnStartPoint, columnEndPoint])
            }
    }
    
    static func drawGridlinesOld(context: CGContext, pageSize: CGSize, gridSize: PageLayoutType, cellSize: CGSize, lineColor: Color, lineWidth: CGFloat) {
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor.toUIColor()?.cgColor ?? UIColor.black.cgColor)
        
        //Iterate through the rows and columns
        
        if gridSize.height > 1 {
            for row in 1..<Int(gridSize.height) {
                
                let rowStartPoint = CGPoint(x: 0, y: CGFloat(row) * cellSize.height)
                let rowEndPoint = CGPoint(x: pageSize.width, y: rowStartPoint.y)
                
                context.strokeLineSegments(between: [rowStartPoint, rowEndPoint])
            }
        }

        if gridSize.width > 1 {
            for col in 1..<Int(gridSize.width) {
                    
                let columnStartPoint = CGPoint(x: CGFloat(col) * cellSize.width, y: 0)
                let columnEndPoint = CGPoint(x: columnStartPoint.x, y: pageSize.height)
                
                context.strokeLineSegments(between: [columnStartPoint, columnEndPoint])
            }
        }
    }
}

// Extension for text alignment conversion
extension TopBottomPosition {
    func toNSTextAlignment() -> NSTextAlignment {
        switch self {
        case .top:
            return .center
        case .bottom:
            return .center
        }
    }
}

// Text alignment enum (add this if you don't have it)
enum TextAlignment {
    case left
    case center
    case right
    
    func toNSTextAlignment() -> NSTextAlignment {
        switch self {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        }
    }
}
