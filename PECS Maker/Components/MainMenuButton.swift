//
//  MainMenuButton.swift
//  PECS Maker
//
//  Created by Andy on 29/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct MainMenuButton: View {
    
    var action: ()->()
    var systemIconName: String? = nil
    var text: String
    var showCheckMark: Bool = false
    var isHorizontal: Bool = false
    var isSecondary: Bool = false
    var isSelected: Bool = false

    let buttonFontTitle = Font.title2
    //let buttonFontWeight = FontVariation.semibold
    //let buttonFontImage = Font.title2
    let buttonFontImage = Font.title
    //let buttonFontCheckmark = Font.largeTitle
    let buttonFontCheckmark = Font.title2
    let innerPadding = CGFloat(16)
    
    func calcMaxHeight() -> CGFloat {
        var height = CGFloat(0)
        if systemIconName != nil {
            height += buttonFontImage.toUIFont()?.pointSize ?? 20
        }
        height += buttonFontTitle.toUIFont()?.pointSize ?? 20
        //height += (2 * innerPadding)
        return height * 2
    }

    var body: some View {
     
        Button(action: { action() }) {
            ConditionalStack(isHorizonalStack: isHorizontal) {
                //Spacer()
                    //.frame(minHeight: 0, idealHeight: 0)
                if let systemIconName = systemIconName {
                    Image(systemName: systemIconName)
                        .font(buttonFontImage)
                        .padding(0)
                        .frame(height: buttonFontImage.toUIFont()?.pointSize ?? 20)
                }
                ZStack {
                    Text(text)
                        .lineLimit(2)
                        .font(buttonFontTitle)
                        //.fixedSize(horizontal: false, vertical: true)
                    
                    if showCheckMark {
                        Image(systemName: "checkmark.circle.fill")
                            .font(buttonFontCheckmark)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            //.withAnimation(Animation.easeIn(duration: 1.0))
                    }
                }
                .frame(maxWidth: .infinity)
                //.padding(EdgeInsets(top: -8, leading: 0, bottom: 0, trailing: 0))
                //Spacer()
                            //.frame(minHeight: 0, idealHeight: 0)
            }
        }
        //.frame(maxWidth: AppSettings.maxButtonWidth)
        .buttonStyle(RoundedButtonStyle( purpose: isSecondary ? ButtonPurpose.secondary : ButtonPurpose.primary, cornerRadius: 25, padding: innerPadding, isSelected: isSelected ))
    }
}

struct MainMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MainMenuButton(action: {}, systemIconName: "photo", text: "Select Photos", isSecondary: false, isSelected: true)
            MainMenuButton(action: {}, systemIconName: "square.grid.2x2", text: "Layout", isSecondary: false, isSelected: false)
            MainMenuButton(action: {}, systemIconName: "printer", text: "Preview and Print", isSecondary: true, isSelected: false)

        }
        .maxWidth(350)

    }
}
