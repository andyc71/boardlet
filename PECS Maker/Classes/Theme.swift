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
    
    
    static var backgroundColor = Color(ColorNames.paleBlue)
    
    static var selectionHighlightColor = Color(ColorNames.yellow)
    static var selectionHighlightUIColor = UIColor(named: ColorNames.yellow) ?? .systemYellow

    
    static var cardBackgroundColor = Color(ColorNames.lightBlue)


    private static var headerFontName = "Coiny-Regular"
    //static var headerFontSize = CGFloat(32)
    
    private static var headerFontSizeForHomePage: CGFloat {
        get {
            let headerTextStyle = UIFont.TextStyle.largeTitle
            return UIFont.preferredFont(forTextStyle: headerTextStyle).pointSize
        }
    }

    private static var headerFontSizeDefault: CGFloat {
        get {
            let headerTextStyle = UIFont.TextStyle.title1
            return UIFont.preferredFont(forTextStyle: headerTextStyle).pointSize
        }
    }

    //Font for the home page
    static var headerFontHomePage = Font.custom(headerFontName, fixedSize: headerFontSizeForHomePage)
    
    //Font for the child pages
    static var headerFontDefault = UIFont(name: headerFontName, size: headerFontSizeDefault)

    //static var headerBackgroundColorName = ColorNames.lightYellow
    //static var headerForegroundColorName = ColorNames.brightBlue

    static var headerBackgroundColorName = ColorNames.lightYellow
    static var headerTextColorName = ColorNames.brightBlue
    static var headerTextOutlineColorName = ColorNames.transparent
    static var headerTextOutlineWidth = CGFloat(0)
    //static var headerTextOutlineColorName = ColorNames.black
    //static var headerTextOutlineWidth = CGFloat(-2)

}
