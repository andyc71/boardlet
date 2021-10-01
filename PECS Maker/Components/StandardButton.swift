//
//  MainMenuButton.swift
//  PECS Maker
//
//  Created by Andy on 29/09/2021.
//

import SwiftUI

struct StandardButton: View {
    
    var action: ()->()
    var systemIconName: String? = nil
    var text: String
    var isHorizontal: Bool = false

    let buttonFontTitle = Font.title2
    //let buttonFontWeight = FontVariation.semibold
    //let buttonFontImage = Font.title2
    let buttonFontImage = Font.title

    var body: some View {
     
        Button(action: { action() }) {
            ConditionalStack(isHorizonalStack: isHorizontal) {
                if let systemIconName = systemIconName {
                    Image(systemName: systemIconName)
                        //.font(buttonFontImage)
                        .padding(2)
                }
                Text(text)
                    //.font(buttonFontTitle)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color("mfBrightBlue"))
            .cornerRadius(20)
        }
    }
}
