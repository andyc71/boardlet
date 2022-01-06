//
//  MainMenuButton.swift
//  PECS Maker
//
//  Created by Andy on 29/09/2021.
//

import SwiftUI

struct MainMenuButton: View {
    
    var action: ()->()
    var systemIconName: String? = nil
    var text: String
    var showCheckMark: Bool = false
    var isHorizontal: Bool = false
    var isSecondary: Bool = false

    let buttonFontTitle = Font.title2
    //let buttonFontWeight = FontVariation.semibold
    //let buttonFontImage = Font.title2
    let buttonFontImage = Font.title

    var body: some View {
     
        Button(action: { action() }) {
            ConditionalStack(isHorizonalStack: isHorizontal) {
                Spacer()
                    .frame(minHeight: 0, idealHeight: 0)
                if let systemIconName = systemIconName {
                    Image(systemName: systemIconName)
                        .font(buttonFontImage)
                        .padding(0)
                }
                ZStack {
                    Text(text)
                        .lineLimit(2)
                        .font(buttonFontTitle)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if showCheckMark {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            //.withAnimation(Animation.easeIn(duration: 1.0))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: -8, leading: 0, bottom: 0, trailing: 0))
                Spacer()
                            .frame(minHeight: 0, idealHeight: 0)

            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(4)
            .foregroundColor(.white)
            .background(Color(isSecondary ? ColorNames.green : ColorNames.brightBlue) )
            .cornerRadius(20)
        }
    }
}
