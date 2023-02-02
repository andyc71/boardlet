//
//  PageMeasurements.swift
//  PECS Maker
//
//  Created by Andy on 02/10/2021.
//

import UIKit

struct PageMeasurements2 {
    
    ///All sized are portrait in mm
    static let a4 = CGSize(width: 210, height: 297)
    static let usLetter = CGSize(width: 215.9, height: 279.4)
    static let photo10by15 = CGSize(width: 100, height: 150)
    
    static func forSize(_ pageSize: PageSize, orientation: PageOrientation = .portrait) -> CGSize {
        var size: CGSize!
        switch pageSize {
        case .a4:
            size = PageMeasurements2.a4
        case .photo10by15:
            size = PageMeasurements2.photo10by15
        case .usLetter:
            size = PageMeasurements2.usLetter
        }
        if orientation == .landscape {
            return size.flipped()
        }
        else {
            return size
        }
    }
}

struct Measurements {
    
    enum MeasurementUnit { case mm, inches, aspectRatio }
    enum OutputDevice { case screen, paper }
    enum TShirtSize { case small, medium, maxWidth(_ maxWidth: CGFloat), maxHeight(_ maxHeight: CGFloat), maxSize(_ maxSize: CGSize) }

    var sizeInMM: CGSize
    let unit: MeasurementUnit = .mm
    var aspectRatio: CGFloat { sizeInMM.width / sizeInMM.height }

    //var width: CGFloat { get { return sizeInMM.width} }
    //var height: CGFloat { get { return sizeInMM.height} }

    init(_ sizeInMM: CGSize) {
        self.sizeInMM = sizeInMM
    }
    
    func formatAs(measurementType: MeasurementUnit) -> String {
        let size = sizeInMM
        switch measurementType {
        case .mm:
            let widthStr = String(format: "%.0f", size.width)
            let heightStr = String(format: "%.0f", size.height)
            return "\(widthStr) mm x \(heightStr) mm"
        case .inches:
            let inches = Measurements.convertToInches(size: size)
            let widthStr = String(format: "%.1f", inches.width)
            let heightStr = String(format: "%.1f", inches.height)
            return "\(widthStr) in x \(heightStr) in"
        case .aspectRatio:
            let aspectRatio = sizeInMM.width / sizeInMM.height
            return String(format: "%.2f", aspectRatio)
        }

    }
    
    var metricAndImperialFormat: String {
        let metricFormat = formatAs(measurementType: .mm)
        let imperialFormat = formatAs(measurementType: .inches)
        return "\(metricFormat) (\(imperialFormat))"
    }

    static func convertToInches(size: CGSize) -> CGSize {
        let width = size.width / 25.4
        let height = size.height / 25.4
        return CGSize(width: width, height: height)
    }
    
    func convertWithDPI(_ dpi: CGFloat) -> CGSize {
        
        //Assuming the pixel density is 72 dpi, meaning that there are 72 pixels per inch.
        //We know that 1 inch is equal to 25.4 mm. So there are 72 pixels per 25.4 mm.
        //Then 1 pixel = (25.4 / 96) mm. Thus, there are 0.352777777777778 millimeters in a pixel.
        
        let mmPerPixel: CGFloat = 25.4 / dpi
        
        let pixels = CGSize(width: self.sizeInMM.width / mmPerPixel, height: self.sizeInMM.height / mmPerPixel)
        
        return pixels
    }
    
    func convertToPDFMeasurements() -> CGSize {
        //From https://stackoverflow.com/questions/11809133/default-paper-size-and-unit-for-pdf-documents-on-ios
        //PDF and PostScript use "PostScript points" as a unit. A PostScript point is 1/72 inch. So the default page size is 612 x 792 points = 8.5 x 11 inch = 215.9 mm x 279.4 mm
        let size = convertWithDPI(72)
        return size
    }
    
    func convertToScreenMeasurements(_ tShirtSize: TShirtSize) -> CGSize {
        
        switch tShirtSize {
        case .small:
            return CGSize(width: self.sizeInMM.width * 1.0, height: self.sizeInMM.height * 1.0)
        case .medium:
            return CGSize(width: self.sizeInMM.width * 2.0, height: self.sizeInMM.height * 2.0)
        case .maxWidth(let maxWidth):
            let scaleFactor = self.sizeInMM.width / maxWidth
            let height = self.sizeInMM.height / scaleFactor
            let size = CGSize(width: maxWidth, height: height)
            return size
        case .maxHeight(let maxHeight):
            let scaleFactor = self.sizeInMM.height / maxHeight
            let width = self.sizeInMM.width / scaleFactor
            let size = CGSize(width: width, height: maxHeight)
            return size
        case .maxSize(let maxSize):
            let maxWidthSize = convertToScreenMeasurements(.maxWidth(maxSize.width))
            let maxHeightSize = convertToScreenMeasurements(.maxHeight(maxSize.height))
            if maxWidthSize.height > maxSize.height {
                return maxHeightSize
            }
            if maxHeightSize.width > maxSize.width {
                return maxWidthSize
            }
            
            let area1 = maxWidthSize.width * maxWidthSize.height
            let area2 = maxHeightSize.width * maxHeightSize.height
            if area1 > area2 {
                return maxWidthSize
            }
            else {
                return maxHeightSize
            }
            
        }
    }

    
}
