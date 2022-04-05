//
//  FormattingView.swift
//  PECS Maker
//
//  Created by Andy on 22/03/2022.
//

import SwiftUI
import SharedSwiftUI

struct FormattingView: View {
    
    @ObservedObject var formattingOptions: CollageFormatting = CollageFormatting.shared

    var body: some View {
        ScrollView {
            
            SimpleCard(title: L10n.FormattingView.gridlinesSectionTitle) {
                Toggle(isOn: $formattingOptions.thickerGridlines ) {
                    Text(L10n.FormattingView.gridlinesThicker)
                }
                ColorPicker(L10n.FormattingView.gridlinesColour, selection: $formattingOptions.gridlineColor)
            }
            .padding()
            
            SimpleCard(title: L10n.FormattingView.titlesSectionTitle) {
                ColorPicker(L10n.FormattingView.titlesTextColor, selection: $formattingOptions.titleColor)
                Toggle(isOn: $formattingOptions.titleBoldFont ) {
                    Text(L10n.FormattingView.titlesBoldFontOption)
                }
            }
            .padding()

            SimpleCard(title: L10n.FormattingView.marginsSectionTitle) {
                Slider(value: $formattingOptions.marginPercentage, in: 0.02...0.1)
                HStack {
                    Text(L10n.FormattingView.marginsSmall).font(.caption).foregroundColor(.secondaryLabel)
                    Spacer()
                    Text(L10n.FormattingView.marginsBig).font(.caption).foregroundColor(.secondaryLabel)
                }
            }
            .padding()

            Spacer()

        }
        .navigationBarTitle(Text(L10n.FormattingView.title), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))
        .onDisappear {
            formattingOptions.saveChanges()
        }

    }
}


