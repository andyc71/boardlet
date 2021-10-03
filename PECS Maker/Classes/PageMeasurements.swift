//
//  PageMeasurements.swift
//  PECS Maker
//
//  Created by Andy on 02/10/2021.
//

import UIKit

struct PageMeasurements {
    static let a4 = CGSize(width: 2100, height: 2970)
    static let usLetter = CGSize(width: 2159, height: 2794)
    static let photo10by15 = CGSize(width: 1000, height: 1500)
    
    static func forSize(_ pageSize: PageSize) -> CGSize {
        switch pageSize {
        case .a4:
            return PageMeasurements.a4
        case .photo10by15:
            return PageMeasurements.photo10by15
        case .usLetter:
            return PageMeasurements.usLetter
        }
    }
}

struct Measurements {
    
    enum MeasurementUnit { case mm, inches }
    enum OutputDevice { case screen, paper }

    var size: CGSize
    let unit: MeasurementUnit = .mm
    let outputDevice: OutputDevice = .screen

    var width: CGFloat { get { return size.width} }
    var height: CGFloat { get { return size.height} }

    init(_ size: CGSize) {
        self.size = size
    }
    
    func formatAs(measurementType: MeasurementUnit) -> String {
        let size = convertToPaperMeasurements()
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
    
    func convertToPaperMeasurements() -> CGSize {
        CGSize(width: self.size.width / 10.0, height: self.size.height / 10.0)
    }
    
}
