//
//  ViewSettings.swift
//  PECS Maker
//
//  Created by Andy on 30/09/2021.
//

import UIKit

let headerViewFontName = "Marker-Felt"
let headerViewFontSize = CGFloat(24)
let headerViewFontColor = UIColor.label

let settingsRowIconColor = ColorNames.brightBlue

var settingsRowIconSize: CGFloat {
    get {
        let height = UIFont.preferredFont(forTextStyle: .body).pointSize
        return height * 1.4
        
    }
}

