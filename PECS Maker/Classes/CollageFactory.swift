//
//  CollageFactory.swift
//  SimpleCollageMaker
//
//  Created by Andy on 19/09/2021.
//  Copyright © 2021 Aj. All rights reserved.
//

import UIKit

class CollageFactory {

    static func createCollage( from images: [UIImage], gridSize: CGSize = CGSize(width: 3, height: 3), pageSize: CGSize = CGSize(width: 2100, height: 3000), cellFillColor: UIColor = .white, marginPercentage: CGFloat = 0.05, borderColor: UIColor = .darkGray, borderWidth: CGFloat = 4 ) -> UIImage? {

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
        

        //Work out the width and height of each cell
        let cellSize = CGSize(
            width: pageSize.width / gridSize.width,
            height: pageSize.height / gridSize.height
        )
        
        //Iterate through the rows and columns
        var imageIndex = 0
        for row in 0..<Int(gridSize.height) {
            for col in 0..<Int(gridSize.width) {
                
                let cellOrigin = CGPoint(x: CGFloat(col) * cellSize.width, y: CGFloat(row) * cellSize.height)
                let cellRect = CGRect(origin: cellOrigin, size: cellSize)
                
                //context.clip(to: imageRect, mask: cgImage)
                context.setFillColor(cellFillColor.cgColor)
                context.fill(cellRect)

                if imageIndex > images.count - 1 {
                    continue
                }
                
                let image = images[imageIndex]
                
                
                /*
                //Draw the cell frame
                var borderRect = cellRect
                
                //If we've got more than one item going across, and this is not the last item,
                //we need to draw the right border over to the right a bit so it overlaps the one
                //on the next cell, otherwise we will get double thick borders.
                var borderRectWidthIncrease: CGFloat = 0
                var borderRectHeightIncrease: CGFloat = 0
                if gridSize.width > 1 && col < Int(gridSize.width - 1) {
                    borderRectWidthIncrease = borderWidth / 2.0
                }
                if gridSize.height > 1 && row < Int(gridSize.height - 1) {
                    borderRectHeightIncrease = borderWidth / 2.0
                }
                borderRect.size = CGSize(width: borderRect.width + borderRectWidthIncrease, height: borderRect.height + borderRectHeightIncrease)
                
                context.setLineWidth(borderWidth)
                context.setStrokeColor(borderColor.cgColor)
                context.setFillColor(UIColor.clear.cgColor)
                context.stroke(borderRect)
                 */
                //Put a margin on in the cell
                let margin: CGFloat = cellSize.width * marginPercentage
                let newCellOrigin = CGPoint(x: cellOrigin.x + margin, y: cellOrigin.y + margin)
                let newCellSize = CGSize(width: cellSize.width-(2*margin), height: cellSize.height-(2*margin))
                let newCellRect = CGRect(origin: newCellOrigin, size: newCellSize)

                var targetImageSize: CGSize!
                //Work out the image size within the target rectangle so it gets stretched/shrunk.
                //Resize based on width or height, depending on which is the closest match.
                let widthDiff = abs(cellRect.width - image.size.width)
                let heightDiff = abs(cellRect.height - image.size.height)
                if widthDiff < heightDiff {
                    targetImageSize = calcImageSizeFromCellWidth(image: image, cellWidth: newCellRect.width)
                    if targetImageSize.height > newCellRect.height {
                        targetImageSize = calcImageSizeFromCellHeight(image: image, cellHeight: newCellRect.height)
                    }
                }
                else {
                    targetImageSize = calcImageSizeFromCellHeight(image: image, cellHeight: newCellRect.height)
                    if targetImageSize.width > newCellRect.width {
                        targetImageSize = calcImageSizeFromCellWidth(image: image, cellWidth: newCellRect.width)
                    }
                }
                let imageOriginWithinCell = CGPoint(
                    x: (newCellRect.size.width - targetImageSize.width) / 2,
                    y: (newCellRect.size.height - targetImageSize.height) / 2
                )
                let imageOriginWithinPage = CGPoint(x: imageOriginWithinCell.x + newCellRect.origin.x,
                                                    y: imageOriginWithinCell.y + newCellRect.origin.y)
                let imageRect = CGRect(origin: imageOriginWithinPage, size: targetImageSize)
                
                image.draw(in: imageRect)
                imageIndex += 1
            }
        }
        
        drawGridlines(context: context, pageSize: pageSize, gridSize: gridSize, cellSize: cellSize, lineColor: borderColor, lineWidth: borderWidth)
        
        guard let cgImage = context.makeImage() else {
            print("Failed to create CGImage")
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        
        return image
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

    
    static func drawGridlines(context: CGContext, pageSize: CGSize, gridSize: CGSize, cellSize: CGSize, lineColor: UIColor, lineWidth: CGFloat) {
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor.cgColor)
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
