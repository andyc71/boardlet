//
//  PageSize.swift
//  PECS Maker
//
//  Created by Andy on 26/09/2021.
//

import UIKit

enum PageSize: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case a4 = "A4"
    case usLetter = "US Letter"
    case photo10by15 = "10x15 Photo Paper"
}

typealias PageLayout = CGSize

extension PageLayout {
    func flipped() -> PageLayout {
        return PageLayout(width: self.height, height: self.width)
    }
}

extension PageLayout {
    func asPortrait() -> CGSize {
        return self
    }
    func asLandsape() -> CGSize {
        return CGSize(width: self.height, height: self.width)
    }
}

extension PageLayout : Identifiable {
    public var id: UUID {
        return UUID()
    }
}



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

