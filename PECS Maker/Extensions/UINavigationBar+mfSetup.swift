//
//  UINavigationBar+mfSetup.swift
//  MyMusic
//
//  Created by Andy on 17/05/2022.
//  Copyright © 2022 Andrew Clynes. All rights reserved.
//

import UIKit
import SwiftUI

let headerViewFontName = "Coiny-Regular"
let headerViewFontSize = CGFloat(24)
let largeHeaderViewFontSize = CGFloat(48)

extension UIColor {
    ///Nav bar
    static var mfNavBarBackground: UIColor { UIColor.dynamicColor(light: UIColor.mfPaleBlue, dark: UIColor.mfDarkBlue) }
    static var mfNavBarText: UIColor { UIColor.mfVeryBrightBlue }
    static var mfNavBarIcon: UIColor { UIColor.mfVeryBrightBlue }
}

extension UINavigationBar {
    
    static var headerFont: Font {
        get { Font.custom(headerViewFontName, size: headerViewFontSize) }
    }

    static var headerViewUIFont: UIFont {
        get {
            let font = UIFont(name: headerViewFontName, size: headerViewFontSize)
            if font != nil {
                return font!
            }
            return UIFont.systemFont(ofSize: headerViewFontSize)
        }
    }

    static var largeHeaderViewUIFont: UIFont {
        get {
            let font = UIFont(name: headerViewFontName, size: largeHeaderViewFontSize)
            if font != nil {
                return font!
            }
            return UIFont.systemFont(ofSize: largeHeaderViewFontSize)
        }
    }
    
    static func makeNavBarTextAttributes(large: Bool) -> [NSAttributedString.Key: Any] {
        [.font: large ? largeHeaderViewUIFont : headerViewUIFont]
    }
    
    static func mfSetup(outlineText: Bool) {
        UINavigationBar.appearance().largeTitleTextAttributes = makeNavBarTextAttributes(large: true)
        UINavigationBar.appearance().titleTextAttributes = makeNavBarTextAttributes(large: false)
    }
    
}
