//
//  CollageFormatting.swift
//  PECS Maker
//
//  Created by Andy on 23/03/2022.
//

import SwiftUI
import SharedSwiftUI
import LogFramework

//This was originally implemented with the intntion of being a global setting
//that is persisted to user defaults. However it is not stored on a per-topic
//basis; the global setting is loaded from user defaults and applied to new topics.
class CollageFormatting : ObservableObject, Codable, Equatable {
    
    static func == (lhs: CollageFormatting, rhs: CollageFormatting) -> Bool {
        lhs.labelColor.getHex() == rhs.labelColor.getHex() &&
        lhs.labelBoldFont == rhs.labelBoldFont &&
        lhs.labelHeightPercentage == rhs.labelHeightPercentage &&
        lhs.labelPosition == rhs.labelPosition &&
        lhs.cellFillColor.getHex() == rhs.cellFillColor.getHex() &&
        lhs.gridlinesColor.getHex() == rhs.gridlinesColor.getHex() &&
        lhs.gridlinesThick == rhs.gridlinesThick &&
        lhs.fitzgeraldBordersEnabled == rhs.fitzgeraldBordersEnabled &&
        lhs.fitzgeraldBordersThick == rhs.fitzgeraldBordersThick &&
        lhs.marginPercentage == rhs.marginPercentage
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
    
    @SimpleUserDefault(key: "titleColor", defaultValue: Color.black, manualPersist: true)
    public var labelColor: Color

    @SimpleUserDefault(key: "titleBoldFont", defaultValue: false, manualPersist: true)
    public var labelBoldFont: Bool

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

    @SimpleUserDefault(key: "labelHeightPercentage", defaultValue: 0.15, manualPersist: true)
    public var labelHeightPercentage: CGFloat
                       
    @SimpleUserDefault(key: "marginPercentage", defaultValue: 0.05, manualPersist: true)
    public var marginPercentage: CGFloat
    
    @SimpleUserDefault(key: "labelPosition", defaultValue: .bottom, manualPersist: true)
    public var labelPosition: TopBottomPosition
    
    var gridlinesWidth: CGFloat {
        get { return gridlinesThick ? 4 : 1 }
    }

    var fitzgeraldBorderWidth: CGFloat {
        get { return fitzgeraldBordersThick ? 4 : 1 }
    }

    func saveToUserDefaults() {
        _labelColor.save()
        _labelBoldFont.save()
        _labelPosition.save()
        _labelHeightPercentage.save()
        _cellFillColor.save()
        _marginPercentage.save()
        _gridlinesColor.save()
        _gridlinesThick.save()
        _fitzgeraldBordersEnabled.save()
        _fitzgeraldBordersThick.save()
        objectWillChange.send()
    }
    
    func loadFromUserDefaults() {
        _labelColor.load()
        _labelBoldFont.load()
        _labelPosition.load()
        _cellFillColor.load()
        _marginPercentage.load()
        _gridlinesColor.load()
        _gridlinesThick.load()
        _fitzgeraldBordersEnabled.load()
        _fitzgeraldBordersThick.load()
    }
    
    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case labelColor, labelBoldFont, labelPosition, labelHeightPercentage, cellFillColor, marginPercentage, gridlineColor, gridlinesThick, fitzgeraldBordersEnabled, fitzgeraldBordersThick
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(labelColor, forKey: .labelColor)
        try container.encode(labelBoldFont, forKey: .labelBoldFont)
        try container.encode(labelHeightPercentage, forKey: .labelHeightPercentage)
        try container.encode(labelPosition, forKey: .labelPosition)
        try container.encode(cellFillColor, forKey: .cellFillColor)
        try container.encode(marginPercentage, forKey: .marginPercentage)
        try container.encode(gridlinesColor, forKey: .gridlineColor)
        try container.encode(gridlinesThick, forKey: .gridlinesThick)
        try container.encode(fitzgeraldBordersEnabled, forKey: .fitzgeraldBordersEnabled)
        try container.encode(fitzgeraldBordersThick, forKey: .fitzgeraldBordersThick)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        labelColor = try values.decode(Color.self, forKey: .labelColor)
        labelBoldFont = try values.decode(Bool.self, forKey: .labelBoldFont)
        labelHeightPercentage = try values.decode(CGFloat.self, forKey: .labelHeightPercentage)
        labelPosition = try values.decode(TopBottomPosition.self, forKey: .labelPosition)
        cellFillColor = try values.decode(Color.self, forKey: .cellFillColor)
        marginPercentage = try values.decode(CGFloat.self, forKey: .marginPercentage)
        gridlinesColor = try values.decode(Color.self, forKey: .gridlineColor)
        gridlinesThick = try values.decode(Bool.self, forKey: .gridlinesThick)
        fitzgeraldBordersEnabled = try values.decode(Bool.self, forKey: .fitzgeraldBordersEnabled)
        fitzgeraldBordersThick = try values.decode(Bool.self, forKey: .fitzgeraldBordersThick)
    }
    
    
    
    
    
}
