//
//  Theme.swift
//  PECS Maker
//
//  Created by Andy on 28/09/2021.
//

import SwiftUI

struct CardStyleCardDefault: ViewModifier {

    func body(content: Content) -> some View {
            content
                //.font(.caption2)
                .padding()
                .background( Theme.cardBackgroundColor )
        }
}


class Theme {
    
    //static var cardStyleCard: Some ViewModifier = CardStyleCardDefault()

    //static var selectionHighlightUIColor = UIColor(named: ColorNames.lightYellow) ?? .systemYellow
    
    static var cardBackgroundColor = Color(ColorNames.lightBlue)

    //static var tempImageColor = UIColor(named: ColorNames.green) ?? .systemGreen


    static var headerFontName = "Baloo 2"
    //static var headerFontSize = CGFloat(32)
    
    private static var headerFontSizeForHomePage: CGFloat {
        get {
            let headerTextStyle = UIFont.TextStyle.largeTitle
            return UIFont.preferredFont(forTextStyle: headerTextStyle).pointSize
        }
    }

    private static var headerFontSizeDefault: CGFloat {
        get {
            let headerTextStyle = UIFont.TextStyle.title2
            return UIFont.preferredFont(forTextStyle: headerTextStyle).pointSize
        }
    }

    //Font for the home page
    static var headerFontHomePage = Font.custom(headerFontName, fixedSize: headerFontSizeForHomePage)
    
    //Font for the child pages
    static var headerFontDefault = UIFont(name: headerFontName, size: headerFontSizeDefault)

    //static var headerBackgroundColorName = ColorNames.lightYellow
    //static var headerForegroundColorName = ColorNames.brightBlue

    //static var headerBackgroundColorName = ColorNames.lightYellow
    
    static var headerBackgroundColor = UIColor.mfNavBarBackground
    static var headerTextColor = UIColor.mfNavBarText
    static var headerTextOutlineColor = UIColor.mfNavBarText
    static var headerTextOutlineWidth = CGFloat(0)
    
    
    //static var headerTextOutlineColorName = ColorNames.black
    //static var headerTextOutlineWidth = CGFloat(-2)

}
