//
//  FormattingView.swift
//  PECS Maker
//
//  Created by Andy on 22/03/2022.
//

import SwiftUI
import SharedSwiftUI
import LogFramework

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
            
            SimpleCard(title: L10n.FormattingView.titlesSectionTitle) {
                ColorPicker(L10n.FormattingView.titlesTextColor, selection: $formattingOptions.titleColor)
                Toggle(isOn: $formattingOptions.titleBoldFont ) {
                    Text(L10n.FormattingView.titlesBoldFontOption)
                }
                HStack {
                    Text(L10n.FormattingView.titlesTextPosition)
                    Picker(L10n.FormattingView.titlesTextPosition, selection: $formattingOptions.labelPosition) {
                        Text("Top").tag(TopBottomPosition.top)
                        Text("Bottom").tag(TopBottomPosition.bottom)
                    }
                    .pickerStyle(.segmented)
                }
            }

            SimpleCard(title: L10n.FormattingView.marginSectionTitle) {
                Slider(value: $formattingOptions.marginPercentage, in: 0.02...0.25)
                HStack {
                    Text(L10n.FormattingView.marginSmall).font(.caption).foregroundColor(.secondaryLabel)
                    Spacer()
                    Text(L10n.FormattingView.marginBig).font(.caption).foregroundColor(.secondaryLabel)
                }
            }

            SimpleCard(title: L10n.FormattingView.labelSectionTitle) {
                Slider(value: $formattingOptions.labelHeightPercentage, in: 0.02...0.25)
                HStack {
                    Text(L10n.FormattingView.labelSmall).font(.caption).foregroundColor(.secondaryLabel)
                    Spacer()
                    Text(L10n.FormattingView.labelBig).font(.caption).foregroundColor(.secondaryLabel)
                }
            }

            #if FitzgeraldKeysFeature
            SimpleCard(title: L10n.FormattingView.fitzgeraldKeysSectionTitle) {
                Toggle(isOn: $formattingOptions.thickerFitzgeraldBorders ) {
                    Text(L10n.FormattingView.fitzgeraldKeysThickerBorders)
                }
            }
            #endif

            Spacer()

        }
        .navigationBarTitle(Text(L10n.FormattingView.title), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear {
            formattingOptions.saveChanges()
        }
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Formatting")
        }

    }
}


