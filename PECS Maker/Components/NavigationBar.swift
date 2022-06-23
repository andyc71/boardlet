//
//  NavigationBar.swift
//  PECS Maker
//
//  Created by Andy on 02/10/2021.
//

import UIKit

class NavigationBar {
    
    static func makeNavBarTextAttributes() -> Dictionary<NSAttributedString.Key, AnyObject> {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
                
        let titleTextAttributes: [NSAttributedString.Key : AnyObject] = [
            .foregroundColor : Theme.headerTextColor as AnyObject,
            .strokeColor : Theme.headerTextOutlineColor as AnyObject,
            .strokeWidth : Theme.headerTextOutlineWidth as AnyObject,
            .font : Theme.headerFontDefault as AnyObject,
            .paragraphStyle : paragraphStyle as AnyObject
        ]
        return titleTextAttributes
    }
    
    static func configure() {

        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = Theme.headerBackgroundColor

        coloredAppearance.titleTextAttributes = makeNavBarTextAttributes()
        coloredAppearance.largeTitleTextAttributes = makeNavBarTextAttributes()
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = coloredAppearance
        }
        
        UINavigationBar.appearance().tintColor = UIColor.mfNavBarIcon
    }
    
    
}
