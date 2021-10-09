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
    
    static func forSize(_ pageSize: PageSize) -> CGSize {
        switch pageSize {
        case .a4:
            return PageMeasurements2.a4
        case .photo10by15:
            return PageMeasurements2.photo10by15
        case .usLetter:
            return PageMeasurements2.usLetter
        }
    }
}

struct Measurements {
    
    enum MeasurementUnit { case mm, inches }
    enum OutputDevice { case screen, paper }
    enum TShirtSize { case small, medium, large }

    var sizeInMM: CGSize
    let unit: MeasurementUnit = .mm

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
    
    func convertToPrinterMeasurements() -> CGSize {
        CGSize(width: self.sizeInMM.width * 15.0, height: self.sizeInMM.height * 15.0)
    }
    
    func convertToScreenMeasurements(_ tShirtSize: TShirtSize) -> CGSize {
        
        switch tShirtSize {
        case .small:
            return CGSize(width: self.sizeInMM.width * 1.0, height: self.sizeInMM.height * 1.0)
        case .medium:
            return CGSize(width: self.sizeInMM.width * 2.0, height: self.sizeInMM.height * 2.0)
        case .large:
            return CGSize(width: self.sizeInMM.width * 3.0, height: self.sizeInMM.height * 3.0)
        }
    }

    
}
