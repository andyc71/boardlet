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
    static var mfNavBarText: UIColor { UIColor.mfBrightBlue }
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
    
    static func makeNavBarTextAttributes(large: Bool) -> Dictionary<NSAttributedString.Key, AnyObject> {
        
        var att = Dictionary<NSAttributedString.Key, AnyObject>()
        
        if large {
            att = [
                .font : largeHeaderViewUIFont,
                .foregroundColor : UIColor.mfNavBarText,
                .strokeColor: UIColor.black,
                .strokeWidth: -4
            ] as Dictionary<NSAttributedString.Key, AnyObject>
        }
        else {
            att = [
                .font : headerViewUIFont,
                //.foregroundColor : UIColor.mpNavBarText,
                .strokeColor: UIColor.black,
                //.strokeWidth: -4
            ] as Dictionary<NSAttributedString.Key, AnyObject>
        }
        return att
    }
    
    static func mfSetup(outlineText: Bool) {
        
        let appearance = UINavigationBarAppearance()
        //appearance.shadowColor = .white
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.mfNavBarBackground
        
        

//        if outlineText {
//            appearance.titleTextAttributes =  makeNavBarTextAttributes(outlineText: outlineText)
//        }
//        else {
//        }
        
        appearance.largeTitleTextAttributes = makeNavBarTextAttributes(large: true)
        appearance.titleTextAttributes = makeNavBarTextAttributes(large: false)

        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.mfNavBarIcon
        
    }
    
}
