//
//  HeaderButton.swift
//  MyMusic
//
//  Created by Andy on 30/09/2021.
//  Copyright © 2021 Andrew Clynes. All rights reserved.
//

import SwiftUI
import LogFramework

struct HeaderButton: View {
    
    var imageName: String?
    var action: () -> Void = {}
    
    private var symbolImageConfig = UIImage.SymbolConfiguration(pointSize: headerViewFontSize)
    
    init(imageName: String, action: @escaping () -> Void = {}) {
        self.imageName = imageName
        self.action = action
    }
    
    @ViewBuilder
    var body: some View {

            Button(action: action ) {
                Image(uiImage: UIImage(systemName: imageName!, withConfiguration: symbolImageConfig)?.withRenderingMode(.alwaysTemplate).withTintColor(headerViewFontColor) ?? UIImage())
            }
            //.buttonStyle(SquishableButtonStyle())

    }

    public static func closeButton(animateToMenuIcon: Bool = false, closeAction: @escaping () -> Void) -> HeaderButton {
            return HeaderButton(imageName: "xmark.circle", action: closeAction)
    }

    public static func backButton(action: @escaping () -> Void) -> HeaderButton {
        return HeaderButton(imageName: "chevron.left.circle", action: action)
    }
        
    public static func shareButton(action: @escaping () -> Void) -> HeaderButton {
        return HeaderButton(imageName: "square.and.arrow.up", action: action)
    }
        
    public static func menuButton(animateToCloseIcon: Bool = false, action: @escaping () -> Void) -> HeaderButton {
            return HeaderButton(imageName: "line.horizontal.3", action: action)
    }
}

