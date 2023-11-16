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
    
    func cardSize(for pageSize: PageSize, orientation: PageOrientation) -> Measurements? {
        PageLayout.cardSizeinMM(pageSize: pageSize, orientation: orientation, pageLayout: self)
    }
    
    static func cardSizeinMM(pageSize: PageSize, orientation: PageOrientation, pageLayout: PageLayout) -> Measurements? {
        let pageSize = PageMeasurements2.forSize(pageSize, orientation: orientation)

        let cardSize = cardSize(pageSize: pageSize, pageLayout: pageLayout)

        if cardSize.width < minCardSize.width || cardSize.height < minCardSize.height {
            return nil
        }

        let individualCardMeasurements = Measurements(cardSize)
        return individualCardMeasurements
    }
    
    static func cardSize(pageSize: CGSize, pageLayout: PageLayout) -> CGSize {
        var cardHeight = pageSize.height / CGFloat(pageLayout.height)
        var cardWidth = pageSize.width / CGFloat(pageLayout.width)

        if let fixedCardAspectRatio = pageLayout.fixedCardAspectRatio, (pageLayout.width == 1 || pageLayout.height == 1) {
            //If we have a single row or a single column then we can
            //specify an fixed aspect ratio to use for the cards.
            if pageLayout.width == 1 {
                cardWidth = cardHeight / fixedCardAspectRatio
            }
            else {
                cardHeight = cardWidth / fixedCardAspectRatio
            }
        }
        
        let size = CGSize(width: cardWidth, height: cardHeight)
        return size
    }

    
    static func forPageSize(_ pageSize: PageSize, orientation: PageOrientation) -> [PageLayoutType] {
        
        var pageLayouts = [PageLayoutType]()
        
        for width in 1...maxColumns {
            for height in 1...maxRows {
                var pageLayout = PageLayout(width: width, height: height)
                guard let cardSize = cardSizeinMM(pageSize: pageSize, orientation: orientation, pageLayout: pageLayout) else {
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
                    if width == 3 && height == 4 {
                        pageLayout.isDefault = .portrait
                    }
                    else if width == 4 && height == 3 {
                        pageLayout.isDefault = .landscape
                    }
                case .a5:
                    if width == 2 && height == 3 {
                        pageLayout.isDefault = .portrait
                    }
                    else if width == 3 && height == 2 {
                        pageLayout.isDefault = .landscape
                    }
                case .photo10by15:
                    if width == 2 && height == 3 {
                        pageLayout.isDefault = .portrait
                    }
                    else if width == 3 && height == 2 {
                        pageLayout.isDefault = .landscape
                    }
                }
                
                pageLayouts.append(pageLayout)
            }
        }
        
        //Special case where we support a single column of items.
        for height in 3...maxRows {
            var pageLayout = PageLayout(width: 1, height: height, fixedCardAspectRatio: 1.0)
            guard let cardSize = cardSizeinMM(pageSize: pageSize, orientation: orientation, pageLayout: pageLayout) else {
                continue
            }
            pageLayouts.append(pageLayout)
        }
        
        //Special case where we support a row column of items.
        for width in 3...maxColumns {
            var pageLayout = PageLayout(width: width, height: 1, fixedCardAspectRatio: 1.0)
            guard let cardSize = cardSizeinMM(pageSize: pageSize, orientation: orientation, pageLayout: pageLayout) else {
                continue
            }
            pageLayouts.append(pageLayout)
        }
        
        return pageLayouts
    }
            


    static func forPageSize2(_ pageSize: PageSize) -> [PageLayoutType] {
        switch pageSize {
        
        case .a5:
            return [

                PageLayoutType(width: 1, height: 2),
                PageLayoutType(width: 2, height: 2, isDefault: .landscape),
                PageLayoutType(width: 3, height: 2),
                PageLayoutType(width: 4, height: 2),

                PageLayoutType(width: 1, height: 3),
                PageLayoutType(width: 2, height: 3, isDefault: .portrait),
                PageLayoutType(width: 3, height: 3),
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

            ]
            
        case .a4, .usLetter:
            return [

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


