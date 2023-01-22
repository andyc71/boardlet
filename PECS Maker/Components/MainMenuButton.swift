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
    var isLarge: Bool = false

    //let buttonFontTitle = Font.title2
    //let buttonFontWeight = FontVariation.semibold
    //let buttonFontImage = Font.title2
    let buttonFontImage = Font.title
    //let buttonFontCheckmark = Font.largeTitle
    //let buttonFontCheckmark = Font.title2
    let innerPadding = CGFloat(16)
    
    func calcMaxHeight() -> CGFloat {
        var height = CGFloat(0)
        if systemIconName != nil {
            height += calcIconHeight()
            height += calcInternalPadding() * 4
        }
        height += calcTextHeight()
        //height += (2 * innerPadding)
        return height * 2
    }
    
    func calcIconHeight() -> CGFloat {
        var height: CGFloat = 20
        if let h = buttonFontImage.toUIFont()?.pointSize {
            height = h
        }
        if isLarge {
            return height * 1.5
        }
        else {
            return height
        }
    }
    
    func calcTextHeight() -> CGFloat {
//        var height: CGFloat = 20
//        if let h = buttonFontTitle.toUIFont()?.pointSize {
//            height = h
//        }
//        if isLarge {
//            return height * 1.5
//        }
//        else {
//            return height
//        }
        return calcIconHeight() * 0.75
    }
    
    func makeTextFont() -> Font {
        return .system(size: calcTextHeight())
    }
    
    func makeCheckMarkFont() -> Font {
        return makeTextFont()
    }

    func calcMaxWidth() -> CGFloat {
        var width = AppSettings.maxButtonWidth
        if isLarge {
            width *= 2
        }
        return width
    }
    
    func calcInternalPadding() -> CGFloat {
        if isLarge {
            return calcTextHeight() * 0.1
        }
        else {
            return 0
        }
    }
    
    
    private var checkMarkView: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(makeCheckMarkFont())
            .foregroundColor(.white)
            //.frame(maxWidth: .infinity, alignment: .trailing)
    }

    var body: some View {
     
        Button(action: { action() }) {
            ConditionalStack(isHorizonalStack: isHorizontal) {
                //Spacer()
                    //.frame(minHeight: 0, idealHeight: 0)
                if let systemIconName = systemIconName {
                    Image(systemName: systemIconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        //.height(calcIconHeight())
                        //.font(buttonFontImage)
                        .padding(calcInternalPadding())
                        .frame(height: calcIconHeight())
                }
                ZStack {
                    Text(text)
                        .lineLimit(2)
                        .font(makeTextFont())
                        .padding(calcInternalPadding())
                }
                //Causes the ZStack to be full width, which
                //enables us to have the tickbox overlay
                //fully right-aligned.
                .frame(maxWidth: .infinity)
            }
            .if(showCheckMark) { view in
                view.overlay(alignment: .bottomTrailing) {
                    //No real reason to have this visible to
                    //accessibility, but if we did unhide it we
                    //would need to be careful because somehow is
                    //causes the entire button to show as selected!
                    checkMarkView
                        .padding(.vertical, calcInternalPadding())
                        .accessibilityHidden(true)
                }
            }
        }
        .if(isLarge) { view in
            view.frame(maxHeight: calcMaxHeight())
        }
        .buttonStyle(RoundedButtonStyle( purpose: isSecondary ? ButtonPurpose.secondary : ButtonPurpose.primary, cornerRadius: 25, padding: innerPadding, isSelected: isSelected ))
    }
}

struct MainMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MainMenuButton(action: {}, systemIconName: "printer", text: "Big Button", showCheckMark: true, isSecondary: false, isSelected: true, isLarge: true)
            
            Divider()
                .padding()

            MainMenuButton(action: {}, systemIconName: "photo", text: "Select Photos", isSecondary: false, isSelected: true)
            MainMenuButton(action: {}, systemIconName: "square.grid.2x2", text: "Layout", isSecondary: false, isSelected: false)
            MainMenuButton(action: {}, systemIconName: "printer", text: "Preview and Print", isSecondary: true, isSelected: false)


        }
        .maxWidth(350)

    }
}
