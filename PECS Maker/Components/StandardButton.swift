//
//  MainMenuButton.swift
//  PECS Maker
//
//  Created by Andy on 29/09/2021.
//

import SwiftUI
import SharedSwiftUI


struct StandardButton: View {
    
    var action: ()->()
    var systemIconName: String? = nil
    var text: String
    var purpose: ButtonPurpose = .secondary

    let buttonFontTitle = Font.title2
    //let buttonFontWeight = FontVariation.semibold
    //let buttonFontImage = Font.title2
    let buttonFontImage = Font.title

    var body: some View {
     
        CapsuleButton(text: text, purpose: purpose, action: {
            action()
        })
        .frame(maxWidth: AppSettings.maxButtonWidth)
        /*
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
        }*/
    }
}
