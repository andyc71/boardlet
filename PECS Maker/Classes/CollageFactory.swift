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

class CollageFactory {

    static func createCollage( from images: [PhotoItem], gridSize: PageLayoutType = PageLayoutType(width: 3, height: 3), pageSize: CGSize = CGSize(width: 2100, height: 3000), options: CollageFormatting
    ) -> UIImage? {

        /*
        //create a device independent color space.
        let colorSpace = CGColorSpaceCreateDeviceCMYK()
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        //Create context
        guard let context = //CGContext(data: nil, width: Int(pageSize.width), height: Int(pageSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            print("Failed to create CGContext")
            return nil
        }*/
        
        UIGraphicsBeginImageContext(pageSize)
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Failed to create CGContext")
            return nil
        }
        
//        context.setFillColor( UIColor.blue.cgColor)
//        context.fill(CGRect(origin: .zero, size: pageSize))

        //Work out the width and height of each cell
        let cellSize = CGSize(
            width: pageSize.width / CGFloat(gridSize.width),
            height: pageSize.height / CGFloat(gridSize.height)
        )
        
        //Iterate through the rows and columns
        var imageIndex = 0
        for row in 0..<Int(gridSize.height) {
            for col in 0..<Int(gridSize.width) {
                
                let cellOrigin = CGPoint(x: CGFloat(col) * cellSize.width, y: CGFloat(row) * cellSize.height)
                let cellRect = CGRect(origin: cellOrigin, size: cellSize)
                
                //context.clip(to: imageRect, mask: cgImage)
                let cellColor = options.cellFillColor.toUIColor()?.cgColor
                context.setFillColor(cellColor ?? UIColor.black.cgColor)
                //context.setFillColor(UIColor.blue.cgColor)
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
                    //context.setFillColor(UIColor.clear.cgColor)
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
                    
                        let labelHeightPercent = options.labelHeightPercentage
                        var labelHeight = newCellRect.height * labelHeightPercent
                        /*
                        guard labelHeight > 0 else {
                            logger.logError(.general, "Collage label height is zero")
                            return nil
                        }*/
                        if labelHeight < 5.0 { labelHeight = 5.0 }
                        
                        let labelWidth = photoRect.width
                        let labelSpacing = labelHeight * 0.5

                        //let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
                        
                        let descriptor = UIFont.systemFont(ofSize: 30, weight: options.titleBoldFont ? .bold : .regular).fontDescriptor
                        
                        //UIFontDescriptor.font (withTextStyle: .largeTitle)
                        
                        guard let labelFont = UIFont.fontFittingText(labelText, in: CGSize(width: labelWidth, height: labelHeight), fontDescriptor: descriptor, option: .fillContainer) else {
                            logger.logError(.general, "Unable to create font for collage label with max height of \(labelHeight)")
                            return nil
                        }

                        /*
                        if labelFont == nil {
                            labelFont = createLabelFont(maxHeight: labelHeight)
                            guard labelFont != nil else {
                                logger.logError(.general, "Unable to create font for collage label with max height of \(labelHeight)")
                                return nil
                            }
                        }*/

                        if labelHeight < labelFont.pointSize {
                            labelHeight = labelFont.pointSize
                        }

                        let labelSize = CGSize(width: labelWidth, height: labelHeight)
                        let labelAndPhotoRects = calcLabelAndPhotoRects(cellRect: newCellRect, labelSize: labelSize, labelSpacing: labelSpacing, labelPosition: options.labelPosition)
                        let labelRect = labelAndPhotoRects.labelRect
                        photoRect = labelAndPhotoRects.photoRect
                        

                        let paragraphStyle = NSMutableParagraphStyle()
                            paragraphStyle.alignment = .center
                        
                        let attrs = [
                            NSAttributedString.Key.font: labelFont,
                            NSAttributedString.Key.paragraphStyle: paragraphStyle,
                            NSAttributedString.Key.foregroundColor: options.titleColor.toUIColor() ?? UIColor.black
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
        
        drawGridlines(context: context, pageSize: pageSize, gridSize: gridSize, cellSize: cellSize, lineColor: options.gridlineColor, lineWidth: options.gridlineWidth)
        
        guard let cgImage = context.makeImage() else {
            print("Failed to create CGImage")
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        
        return image
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
                                   y: 0,
                                   width: labelSize.width,
                                   height: labelSize.height)
            
            let photoRect = CGRect(x: cellRect.minX,
                                   y: labelSize.height + labelSpacing,
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
        /*
        while fontHeight > 0 {
            let tempFont = UIFont.systemFont(ofSize: fontHeight)
            if tempFont.lineHeight > maxHeight {
                fontHeight -= 1
            }
            else {
                return tempFont
            }
        }
        return nil*/
    }

    
    static func drawGridlines(context: CGContext, pageSize: CGSize, gridSize: PageLayoutType, cellSize: CGSize, lineColor: Color, lineWidth: CGFloat) {
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor.toUIColor()?.cgColor ?? UIColor.black.cgColor)
        //context.setFillColor(UIColor.clear.cgColor)
        
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
