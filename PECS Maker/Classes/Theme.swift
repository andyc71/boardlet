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
    
    static var cardBackgroundColor = Color(ColorNames.lightBlue)


    static var headerFontName = "Marker Felt"
    //static var headerFontSize = CGFloat(32)
    
    static var headerFontSize: CGFloat {
        get {
            let headerTextStyle = UIFont.TextStyle.title1
            return UIFont.preferredFont(forTextStyle: headerTextStyle).pointSize
        }
    }
    static var headerFont = Font.custom(headerFontName, fixedSize: headerFontSize)
    //static var headerBackgroundColorName = ColorNames.lightYellow
    //static var headerForegroundColorName = ColorNames.brightBlue

    static var headerBackgroundColorName = ColorNames.lightYellow
    static var headerTextColorName = ColorNames.brightBlue
    static var headerTextOutlineColorName = ColorNames.black
    static var headerTextOutlineWidth = CGFloat(-2)

}
