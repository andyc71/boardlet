//
//  PageLayout.swift
//  PECS Maker
//
//  Created by Andy on 26/09/2021.
//

import UIKit

struct PageScreenLayout {
    let pageSize: CGSize
    let scrollHorizontally: Bool
}

enum PageLayoutSectionKind: CaseIterable, Identifiable, Hashable {
    case recommended
    case singleRow
    case allSizes

    var id: Self { self }
}

enum PageLayoutPreset: CaseIterable, Hashable {
    case large
    case medium
    case small

    var targetSizeInMillimetres: CGFloat {
        switch self {
        case .small: return 25
        case .medium: return 50
        case .large: return 75
        }
    }
}

enum PageLayoutChoiceID: Hashable {
    case preset(PageLayoutPreset)
    case layout(PageLayoutType)
}

struct PageLayoutChoice: Identifiable {
    let layout: PageLayoutType
    let cardSize: Measurements
    let preset: PageLayoutPreset?

    var id: PageLayoutChoiceID {
        preset.map(PageLayoutChoiceID.preset) ?? .layout(layout)
    }
}

struct PageLayoutSection: Identifiable {
    let kind: PageLayoutSectionKind
    let layouts: [PageLayoutChoice]

    var id: PageLayoutSectionKind { kind }

    static func make(
        cardSize: (PageLayoutType) -> Measurements?
    ) -> [PageLayoutSection] {
        let allSizes = allSizeChoices(cardSize: cardSize)
        let recommendedCandidates = allSizes.filter {
            $0.layout.width > 1 && $0.layout.height > 1
        }
        let recommended = presetChoices(from: recommendedCandidates)
        let singleRows = presetChoices(from: singleRowChoices(cardSize: cardSize))

        return [
            PageLayoutSection(kind: .recommended, layouts: recommended),
            PageLayoutSection(kind: .singleRow, layouts: singleRows),
            PageLayoutSection(kind: .allSizes, layouts: allSizes)
        ]
    }

    static let minimumSupportedSize: CGFloat = 25

    static func effectiveSize(of cardSize: Measurements) -> CGFloat {
        min(cardSize.sizeInMM.width, cardSize.sizeInMM.height)
    }

    private static func allSizeChoices(
        cardSize: (PageLayoutType) -> Measurements?
    ) -> [PageLayoutChoice] {
        var choices = [PageLayoutChoice]()
        for columns in 1...PageLayoutType.maxColumns {
            for rows in 1...PageLayoutType.maxRows {
                let layout = PageLayout(width: columns, height: rows)
                guard let measurements = cardSize(layout),
                      effectiveSize(of: measurements) >= minimumSupportedSize else {
                    continue
                }
                choices.append(PageLayoutChoice(
                    layout: layout,
                    cardSize: measurements,
                    preset: nil
                ))
            }
        }
        return choices
    }

    private static func singleRowChoices(
        cardSize: (PageLayoutType) -> Measurements?
    ) -> [PageLayoutChoice] {
        (1...PageLayoutType.maxColumns).compactMap { columns in
            let layout = PageLayout(width: columns, height: 1, fixedCardAspectRatio: 1)
            guard let measurements = cardSize(layout),
                  effectiveSize(of: measurements) >= minimumSupportedSize else {
                return nil
            }
            return PageLayoutChoice(layout: layout, cardSize: measurements, preset: nil)
        }
    }

    private static func presetChoices(
        from candidates: [PageLayoutChoice]
    ) -> [PageLayoutChoice] {
        PageLayoutPreset.allCases.compactMap { preset in
            guard let closest = candidates.min(by: {
                distance(from: $0.cardSize, to: preset.targetSizeInMillimetres)
                    < distance(from: $1.cardSize, to: preset.targetSizeInMillimetres)
            }) else {
                return nil
            }
            return PageLayoutChoice(
                layout: closest.layout,
                cardSize: closest.cardSize,
                preset: preset
            )
        }
    }

    static func distance(from cardSize: Measurements, to target: CGFloat) -> CGFloat {
        let widthDifference = cardSize.sizeInMM.width - target
        let heightDifference = cardSize.sizeInMM.height - target
        return widthDifference * widthDifference + heightDifference * heightDifference
    }
}

extension PageLayoutType : Identifiable {

    // Equality and hashing are synthesized together on PageLayoutType, including
    // fixedCardAspectRatio: fitted and fixed-aspect layouts are distinct choices.
    
    
    static var zero : PageLayoutType { get { return PageLayoutType(width: 0, height: 0)}}
    
    //Min size of a PECS card in mm
    static let minCardSize = CGSize(width: 25, height: 25)
    
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
    
    public var id: Self { self }
    
    func cardSize(for pageSize: PageSize, orientation: PageOrientation) -> Measurements? {
        PageLayout.cardSizeinMM(pageSize: pageSize, orientation: orientation, pageLayout: self)
    }

    /// The final physical card size used by the shared screen/print/PDF renderer.
    /// BoardPageGeometry applies reserved page regions and fixed-aspect constraints.
    func printableCardSize(
        for pageSize: PageSize,
        orientation: PageOrientation,
        title: String?,
        style: BoardRenderStyle,
        attribution: String?
    ) -> Measurements? {
        let pageSizeInMM = PageMeasurements2.forSize(pageSize, orientation: orientation)
        let pageSizeInPoints = Measurements(pageSizeInMM).convertToPDFMeasurements()
        let geometry = BoardPageGeometry(
            pageSize: pageSizeInPoints,
            layout: self,
            title: title,
            style: style,
            attribution: attribution
        )
        guard geometry.cellSize.width > 0, geometry.cellSize.height > 0 else {
            return nil
        }
        return Measurements(geometry.cellSizeInMillimetres)
    }

    /// Fits the page until cards become too small, then scrolls along the limiting axis.
    func screenLayout(in viewport: CGSize, cardAspectRatio: CGFloat) -> PageScreenLayout {
        let columns = CGFloat(max(width, 1))
        let rows = CGFloat(max(height, 1))
        let ratio = max(cardAspectRatio, 0.01)
        let availableWidth = max(viewport.width - 16, 1)
        let availableHeight = max(viewport.height - 16, 1)
        let widthFittingHeight = availableWidth / (columns * ratio)
        let heightFittingHeight = availableHeight / rows
        let fittingHeight = min(widthFittingHeight, heightFittingHeight)
        let minimumCardWidth: CGFloat = 52
        // Leave room for five rows beneath Boardlet's controls in iPhone landscape.
        let minimumCardHeight: CGFloat = 36
        let preferredHeight = max(minimumCardHeight, minimumCardWidth / ratio)
        let scrollHorizontally = fittingHeight < preferredHeight &&
            widthFittingHeight < heightFittingHeight
        let cardHeight: CGFloat
        if fittingHeight < preferredHeight {
            let nonScrollingHeight = scrollHorizontally ? heightFittingHeight : widthFittingHeight
            cardHeight = min(preferredHeight, nonScrollingHeight)
        } else {
            cardHeight = fittingHeight
        }
        return PageScreenLayout(pageSize: CGSize(width: columns * cardHeight * ratio,
                                                 height: rows * cardHeight),
                                scrollHorizontally: scrollHorizontally)
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
            if pageLayout.width == 1 && pageLayout.height == 1 {
                if cardWidth / cardHeight > fixedCardAspectRatio {
                    cardWidth = cardHeight * fixedCardAspectRatio
                } else {
                    cardHeight = cardWidth / fixedCardAspectRatio
                }
            }
            else if pageLayout.width == 1 {
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
                case .a4, .usLetter, .quarto:
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
            let pageLayout = PageLayout(width: 1, height: height, fixedCardAspectRatio: 1.0)
            guard let _ = cardSizeinMM(pageSize: pageSize, orientation: orientation, pageLayout: pageLayout) else {
                continue
            }
            pageLayouts.append(pageLayout)
        }
        
        //Special case where we support a row column of items.
        for width in 3...maxColumns {
            let pageLayout = PageLayout(width: width, height: 1, fixedCardAspectRatio: 1.0)
            guard let _ = cardSizeinMM(pageSize: pageSize, orientation: orientation, pageLayout: pageLayout) else {
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
            
        case .a4, .usLetter, .quarto:
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
