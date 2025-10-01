//
//  CollageFormatting.swift
//  PECS Maker
//
//  Created by Andy on 23/03/2022.
//

import SwiftUI
import SharedSwiftUI
import LogFramework
import SettingsFramework

//This was originally implemented with the intntion of being a global setting
//that is persisted to user defaults. However it is not stored on a per-topic
//basis; the global setting is loaded from user defaults and applied to new topics.
class CollageFormatting : ObservableObject, Codable, Equatable {
    
    static func == (lhs: CollageFormatting, rhs: CollageFormatting) -> Bool {
        lhs.cardTitleFontColor.getHex() == rhs.cardTitleFontColor.getHex() &&
        lhs.cardTitleFontBold == rhs.cardTitleFontBold &&
        lhs.cardTitleFontHeightPercentage == rhs.cardTitleFontHeightPercentage &&
        lhs.cardTitlePosition == rhs.cardTitlePosition &&
        lhs.cellFillColor.getHex() == rhs.cellFillColor.getHex() &&
        lhs.gridlinesColor.getHex() == rhs.gridlinesColor.getHex() &&
        lhs.gridlinesThick == rhs.gridlinesThick &&
        lhs.fitzgeraldBordersEnabled == rhs.fitzgeraldBordersEnabled &&
        lhs.fitzgeraldBordersThick == rhs.fitzgeraldBordersThick &&
        lhs.marginPercentage == rhs.marginPercentage &&
        lhs.pageTitleVisible == rhs.pageTitleVisible &&
        lhs.pageTitleBoldFont == rhs.pageTitleBoldFont &&
        lhs.pageTitleColor.getHex() == rhs.pageTitleColor.getHex() &&
        lhs.pageTitleHeightPercentage == rhs.pageTitleHeightPercentage
    }
    
    init() {
    }

    /*
    private static var _shared: CollageFormatting?
    
    static var shared: CollageFormatting {
        get {
            if let s = _shared {
                return s
            }
            let s = CollageFormatting()
            s.loadFromUserDefaults()
            _shared = s
            return s
        }
    }
    
    static func reset() {
        _shared = CollageFormatting()
    }
     */

    //MARK: Title (at the top of the screen)
    
    @SimpleUserDefault(key: "pageTitleVisible", defaultValue: false, manualPersist: true)
    public var pageTitleVisible: Bool

    @SimpleUserDefault(key: "pageTitleColor", defaultValue: Color.black, manualPersist: true)
    public var pageTitleColor: Color

    @SimpleUserDefault(key: "pageTitleBoldFont", defaultValue: false, manualPersist: true)
    public var pageTitleBoldFont: Bool
    
    @SimpleUserDefault(key: "pageTitleHeightPercentage", defaultValue: 0.15, manualPersist: true)
    public var pageTitleHeightPercentage: CGFloat

    //MARK: Labels (within each cell)
    @SimpleUserDefault(key: "titleColor", defaultValue: Color.black, manualPersist: true)
    public var cardTitleFontColor: Color

    @SimpleUserDefault(key: "titleBoldFont", defaultValue: false, manualPersist: true)
    public var cardTitleFontBold: Bool
    
    @SimpleUserDefault(key: "labelHeightPercentage", defaultValue: 0.15, manualPersist: true)
    public var cardTitleFontHeightPercentage: CGFloat
                       
    @SimpleUserDefault(key: "labelPosition", defaultValue: .bottom, manualPersist: true)
    public var cardTitlePosition: TopBottomPosition

    @SimpleUserDefault(key: "marginPercentage", defaultValue: 0.05, manualPersist: true)
    public var marginPercentage: CGFloat
    
    @SimpleUserDefault(key: "cellFillColor", defaultValue: Color.white, manualPersist: true)
    public var cellFillColor: Color
    
    @SimpleUserDefault(key: "gridlineColor", defaultValue: Color(white: 0.2), manualPersist: true)
    public var gridlinesColor: Color

    @SimpleUserDefault(key: "thickerGridlines", defaultValue: false, manualPersist: true)
    public var gridlinesThick: Bool

    @SimpleUserDefault(key: "enableFitzgeraldBorders", defaultValue: false, manualPersist: true)
    public var fitzgeraldBordersEnabled: Bool

    @SimpleUserDefault(key: "thickerFitzgeraldBorders", defaultValue: true, manualPersist: true)
    public var fitzgeraldBordersThick: Bool
    
    var gridlinesWidth: CGFloat {
        get { return gridlinesThick ? 4 : 1 }
    }

    var fitzgeraldBorderWidth: CGFloat {
        get { return fitzgeraldBordersThick ? 4 : 1 }
    }

    func saveToUserDefaults() {
        _pageTitleVisible.save()
        _pageTitleColor.save()
        _pageTitleBoldFont.save()
        _pageTitleHeightPercentage.save()
        _cardTitleFontColor.save()
        _cardTitleFontBold.save()
        _cardTitleFontHeightPercentage.save()
        _cardTitlePosition.save()
        _cellFillColor.save()
        _marginPercentage.save()
        _gridlinesColor.save()
        _gridlinesThick.save()
        _fitzgeraldBordersEnabled.save()
        _fitzgeraldBordersThick.save()
        objectWillChange.send()
    }
    
    func loadFromUserDefaults() {
        _pageTitleVisible.load()
        _pageTitleColor.load()
        _pageTitleBoldFont.load()
        _pageTitleHeightPercentage.load()
        _cardTitleFontColor.load()
        _cardTitleFontBold.load()
        _cardTitleFontHeightPercentage.load()
        _cardTitlePosition.load()
        _cellFillColor.load()
        _marginPercentage.load()
        _gridlinesColor.load()
        _gridlinesThick.load()
        _fitzgeraldBordersEnabled.load()
        _fitzgeraldBordersThick.load()
    }
    
    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case
            pageTitleVisible, pageTitleColor, pageTitleBoldFont, pageTitleHeightPercentage,
            labelColor, labelBoldFont, labelPosition, labelHeightPercentage, cellFillColor, marginPercentage, gridlineColor, gridlinesThick, fitzgeraldBordersEnabled, fitzgeraldBordersThick
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(pageTitleVisible, forKey: .pageTitleVisible)
        try container.encode(pageTitleColor, forKey: .pageTitleColor)
        try container.encode(pageTitleBoldFont, forKey: .pageTitleBoldFont)
        try container.encode(pageTitleHeightPercentage, forKey: .pageTitleHeightPercentage)
        try container.encode(cardTitleFontColor, forKey: .labelColor)
        try container.encode(cardTitleFontBold, forKey: .labelBoldFont)
        try container.encode(cardTitleFontHeightPercentage, forKey: .labelHeightPercentage)
        try container.encode(cardTitlePosition, forKey: .labelPosition)
        try container.encode(cellFillColor, forKey: .cellFillColor)
        try container.encode(marginPercentage, forKey: .marginPercentage)
        try container.encode(gridlinesColor, forKey: .gridlineColor)
        try container.encode(gridlinesThick, forKey: .gridlinesThick)
        try container.encode(fitzgeraldBordersEnabled, forKey: .fitzgeraldBordersEnabled)
        try container.encode(fitzgeraldBordersThick, forKey: .fitzgeraldBordersThick)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        pageTitleVisible = try values.decode(Bool.self, forKey: .pageTitleVisible)
        pageTitleColor = try values.decode(Color.self, forKey: .pageTitleColor)
        pageTitleBoldFont = try values.decode(Bool.self, forKey: .pageTitleBoldFont)
        pageTitleHeightPercentage = try values.decode(CGFloat.self, forKey: .pageTitleHeightPercentage)
        cardTitleFontColor = try values.decode(Color.self, forKey: .labelColor)
        cardTitleFontBold = try values.decode(Bool.self, forKey: .labelBoldFont)
        cardTitleFontHeightPercentage = try values.decode(CGFloat.self, forKey: .labelHeightPercentage)
        cardTitlePosition = try values.decode(TopBottomPosition.self, forKey: .labelPosition)
        cellFillColor = try values.decode(Color.self, forKey: .cellFillColor)
        marginPercentage = try values.decode(CGFloat.self, forKey: .marginPercentage)
        gridlinesColor = try values.decode(Color.self, forKey: .gridlineColor)
        gridlinesThick = try values.decode(Bool.self, forKey: .gridlinesThick)
        fitzgeraldBordersEnabled = try values.decode(Bool.self, forKey: .fitzgeraldBordersEnabled)
        fitzgeraldBordersThick = try values.decode(Bool.self, forKey: .fitzgeraldBordersThick)
    }
    
    
}
