//
//  CollageFormatting.swift
//  PECS Maker
//
//  Created by Andy on 23/03/2022.
//

import SwiftUI
import SharedSwiftUI
import LogFramework

class CollageFormatting : ObservableObject {
    
    static var _shared: CollageFormatting?
    
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
    
    private enum UserDefaultsKeys: String  {
        case cellFillColor, marginPercentage, gridlineColor, labelHeightPercent, thickerGridlines
    }
    
    @SimpleUserDefault(key: "titleColor", defaultValue: Color.black, manualPersist: true)
    public var titleColor: Color

    @SimpleUserDefault(key: "titleBoldFont", defaultValue: false, manualPersist: true)
    public var titleBoldFont: Bool

    @SimpleUserDefault(key: "cellFillColor", defaultValue: Color.white, manualPersist: true)
    public var cellFillColor: Color
    
    @SimpleUserDefault(key: "gridlineColor", defaultValue: Color(white: 0.2), manualPersist: true)
    public var gridlineColor: Color

    @SimpleUserDefault(key: "thickerGridlines", defaultValue: false, manualPersist: true)
    public var thickerGridlines: Bool

    @SimpleUserDefault(key: "thickerFitzgeraldBorders", defaultValue: true, manualPersist: true)
    public var thickerFitzgeraldBorders: Bool

    @SimpleUserDefault(key: "labelHeightPercentage", defaultValue: 0.15, manualPersist: true)
    public var labelHeightPercentage: CGFloat
                       
    @SimpleUserDefault(key: "marginPercentage", defaultValue: 0.05, manualPersist: true)
    public var marginPercentage: CGFloat
    
    var gridlineWidth: CGFloat {
        get { return thickerGridlines ? 4 : 1 }
    }

    var fitzgeraldBorderWidth: CGFloat {
        get { return thickerFitzgeraldBorders ? 4 : 1 }
    }

    func saveChanges() {
        //objectWillChange.send()
        saveToUserDefaults()
    }
    
    func saveToUserDefaults() {
        _titleColor.save()
        _titleBoldFont.save()
        _cellFillColor.save()
        _marginPercentage.save()
        _gridlineColor.save()
        _labelHeightPercentage.save()
        _thickerGridlines.save()
        objectWillChange.send()
        /*
        UserDefaults.standard.set(cellFillColor, forKey: UserDefaultsKeys.cellFillColor.rawValue)
        
        UserDefaults.standard.set(marginPercentage, forKey: UserDefaultsKeys.marginPercentage.rawValue)
        
        UserDefaults.standard.set(gridlineColor, forKey: UserDefaultsKeys.gridlineColor.rawValue)
        
        UserDefaults.standard.set(cellFillColor, forKey: UserDefaultsKeys.cellFillColor.rawValue)
        
        UserDefaults.standard.set(labelHeightPercent, forKey: UserDefaultsKeys.labelHeightPercent.rawValue)
        
        UserDefaults.standard.set(thickerGridlines, forKey: UserDefaultsKeys.thickerGridlines.rawValue)
         */
    }
    
    func loadFromUserDefaults() {
        _titleColor.load()
        _titleBoldFont.load()
        _cellFillColor.load()
        _marginPercentage.load()
        _gridlineColor.load()
        _labelHeightPercentage.load()
        _thickerGridlines.load()
    }
    
}
