//
//  PageLayout.swift
//  PECS Maker
//
//  Created by Andy on 26/09/2021.
//

import UIKit

extension PageLayoutType : Identifiable, Equatable {

    static func == (lhs: PageLayoutType, rhs: PageLayoutType) -> Bool {
        return lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.isDefault == rhs.isDefault
    }
    
    
    static var zero : PageLayoutType { get { return PageLayoutType(width: 0, height: 0)}}
    
    //Min size of a PECS card in mm
    static let minCardSize = CGSize(width: 20, height: 20)
    
    //Min and max aspect ration of a card
    static let minCardAspectRatio = 0.3
    static let maxCardAspectRatio = 2.0
    
    //Max number of cards across and down the page.
    static let maxColumns = 15
    static let maxRows = 15
    
    func flipped() -> PageLayoutType {
        return PageLayoutType(width: self.height, height: self.width)
    }
    
    func asPortrait() -> PageLayoutType {
        return self
    }
    
    func asLandsape() -> PageLayoutType {
        return self.flipped()
    }
    
    public var id: UUID {
        return UUID()
    }
    
    func cardSize(for pageSize: PageSize, orientation: PageOrientation) -> Measurements {
        PageLayout.cardSize(pageSize: pageSize, orientation: orientation, pageLayout: self)
    }
    
    static func cardSize(pageSize: PageSize, orientation: PageOrientation, pageLayout: PageLayout) -> Measurements {
        let sizeInMM = PageMeasurements2.forSize(pageSize, orientation: orientation)
        let cardWidth = sizeInMM.width / CGFloat(pageLayout.width)
        let cardHeight = sizeInMM.height / CGFloat(pageLayout.height)
        let individualCardMeasurements = Measurements(CGSize(width: cardWidth, height: cardHeight))
        return individualCardMeasurements

    }
    
    static func forPageSize(_ pageSize: PageSize, orientation: PageOrientation) -> [PageLayoutType] {
        
        var pageLayouts = [PageLayoutType]()
        for width in 1...maxColumns {
            for height in 1...maxRows {
                var pageLayout = PageLayout(width: width, height: height)
                let cardSize = cardSize(pageSize: pageSize, orientation: orientation, pageLayout: pageLayout)
                if cardSize.sizeInMM.width < minCardSize.width || cardSize.sizeInMM.height < minCardSize.height {
                        continue
                }
                if cardSize.aspectRatio < minCardAspectRatio {
                    continue
                }
                if cardSize.aspectRatio > maxCardAspectRatio {
                    continue
                }
                
                switch pageSize {
                case .a4, .usLetter:
                    if width == 3 && height == 3 {
                        pageLayout.isDefault = orientation
                    }
                case .photo10by15:
                    if width == 2 && height == 2 {
                        pageLayout.isDefault = .portrait
                    }
                    else if width == 1 && height == 2 {
                        pageLayout.isDefault = .portrait
                    }
                }
                
                pageLayouts.append(pageLayout)
            }
        }
           return pageLayouts
        
    }
            


    static func forPageSize2(_ pageSize: PageSize) -> [PageLayoutType] {
        switch pageSize {
        case .a4, .usLetter:
            return [
//                PageLayoutType(width: 1, height: 2),
//                PageLayoutType(width: 1, height: 3),
//                PageLayoutType(width: 1, height: 4),
//
//                PageLayoutType(width: 2, height: 2),
//                PageLayoutType(width: 2, height: 3),
//                PageLayoutType(width: 2, height: 4),
//
//                PageLayoutType(width: 3, height: 2, isDefault: .landscape),
//                PageLayoutType(width: 3, height: 3, isDefault: .portrait),
//                PageLayoutType(width: 3, height: 4),
//
//                PageLayoutType(width: 4, height: 2),
//                PageLayoutType(width: 4, height: 3),
//                PageLayoutType(width: 4, height: 4),
                
                /*
                 
                 //Row 1
                 PageLayoutType(width: 1, height: 2),
                 PageLayoutType(width: 2, height: 2),
                 PageLayoutType(width: 3, height: 2, isDefault: .landscape),
                 PageLayoutType(width: 4, height: 2),
                 //PageLayoutType(width: 5, height: 2),
                 //PageLayoutType(width: 6, height: 2),

                 //Row 2
                 PageLayoutType(width: 1, height: 3),
                 PageLayoutType(width: 2, height: 3),
                 PageLayoutType(width: 3, height: 3, isDefault: .portrait),
                 PageLayoutType(width: 4, height: 3),
                 //PageLayoutType(width: 5, height: 3),
                 //PageLayoutType(width: 6, height: 3),

                 //Row 3
                 //PageLayoutType(width: 1, height: 4),
                 PageLayoutType(width: 2, height: 4),
                 PageLayoutType(width: 3, height: 4),
                 PageLayoutType(width: 4, height: 4),
                 PageLayoutType(width: 5, height: 4),
                 //PageLayoutType(width: 6, height: 4),

                 //Row 4
                 //PageLayoutType(width: 1, height: 5),
                 //PageLayoutType(width: 2, height: 5),
                 PageLayoutType(width: 3, height: 5),
                 PageLayoutType(width: 4, height: 5),
                 PageLayoutType(width: 5, height: 5),
                 PageLayoutType(width: 6, height: 5),

                 //Row 5
                 //PageLayoutType(width: 1, height: 6),
                 //PageLayoutType(width: 2, height: 6),
                 //PageLayoutType(width: 3, height: 6),
                 PageLayoutType(width: 4, height: 6),
                 PageLayoutType(width: 5, height: 6),
                 PageLayoutType(width: 6, height: 6),
                 PageLayoutType(width: 6, height: 7),

                 PageLayoutType(width: 6, height: 8),

                 */

                PageLayoutType(width: 1, height: 2),
                PageLayoutType(width: 2, height: 2),
                PageLayoutType(width: 3, height: 2, isDefault: .landscape),
                PageLayoutType(width: 4, height: 2),

                PageLayoutType(width: 1, height: 3),
                PageLayoutType(width: 2, height: 3),
                PageLayoutType(width: 3, height: 3, isDefault: .portrait),
                PageLayoutType(width: 4, height: 3),

                PageLayoutType(width: 1, height: 4),
                PageLayoutType(width: 2, height: 4),
                PageLayoutType(width: 3, height: 4),
                PageLayoutType(width: 4, height: 4),

                PageLayoutType(width: 3, height: 5),
                PageLayoutType(width: 4, height: 5),
                PageLayoutType(width: 3, height: 6),
                PageLayoutType(width: 4, height: 6),

                PageLayoutType(width: 5, height: 5),
                PageLayoutType(width: 6, height: 5),
                PageLayoutType(width: 5, height: 6),
                PageLayoutType(width: 6, height: 6),

                PageLayoutType(width: 5, height: 7),
                PageLayoutType(width: 6, height: 7),

                PageLayoutType(width: 5, height: 8),
                PageLayoutType(width: 6, height: 8),

                PageLayoutType(width: 7, height: 7),
                PageLayoutType(width: 7, height: 6),
                //PageLayoutType(width: 8, height: 6),
                //PageLayoutType(width: 7, height: 7),
                //PageLayoutType(width: 8, height: 7),

                
            ]
        case .photo10by15:
            return [
                PageLayoutType(width: 1, height: 1),
                PageLayoutType(width: 2, height: 1, isDefault: .landscape),
                PageLayoutType(width: 1, height: 2, isDefault: .portrait),
            ]
        }
    }
}


