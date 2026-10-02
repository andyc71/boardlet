//
//  NavigationBar.swift
//  PECS Maker
//
//  Created by Andy on 02/10/2021.
//

import UIKit

class NavigationBar {
    static func configure() {
        guard let font = Theme.headerFontDefault else { return }
        let fontAttributes: [NSAttributedString.Key: Any] = [.font: font]
        UINavigationBar.appearance().titleTextAttributes = fontAttributes
        UINavigationBar.appearance().largeTitleTextAttributes = fontAttributes
    }
}
