//
//  NavigationBar.swift
//  PECS Maker
//
//  Created by Andy on 02/10/2021.
//

import UIKit

class NavigationBar {
    
    static func configure() {
        //Use this if NavigationBarTitle is with Large Font
        //UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        
        //Use this if NavigationBarTitle is with displayMode = .inline
//        UINavigationBar.appearance().titleTextAttributes = [
//            .font : UIFont(name: "Marker Felt", size: 24)!,
//            .foregroundColor : UIColor(named: "mfBrightBlue") as Any
//        ]
//        UINavigationBar.appearance().backgroundColor = UIColor(named: "mfLightYellow")
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
                
        let titleTextAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor : UIColor(named: Theme.headerTextColorName) as Any,
            .strokeColor : UIColor(named: Theme.headerTextOutlineColorName) as Any,
            .strokeWidth : Theme.headerTextOutlineWidth as Any,
            .font : Theme.headerFontDefault as Any,
            .paragraphStyle : paragraphStyle as Any
        ]
        
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        //coloredAppearance.configureWithOpaqueBackground()
        //coloredAppearance.backgroundColor = UIColor(named: Theme.headerBackgroundColorName)
        coloredAppearance.titleTextAttributes = titleTextAttributes
        coloredAppearance.largeTitleTextAttributes = titleTextAttributes

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        
    }
    
    
}
