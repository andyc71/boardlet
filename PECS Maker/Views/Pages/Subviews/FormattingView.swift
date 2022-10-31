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
            
            SimpleCard(title: L10n.FormattingView.titlesSectionTitle, titleAccId: AccessibilityIdentifiers.FormattingView.Titles.sectionTitle) {
                
                ColorPicker(L10n.FormattingView.titlesTextColor, selection: $formattingOptions.titleColor)
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Titles
                        .textColor)
                
                Toggle(isOn: $formattingOptions.titleBoldFont ) {
                    Text(L10n.FormattingView.titlesBoldFontOption)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Titles.boldFontOption)
                
                HStack {
                    Text(L10n.FormattingView.titlesTextPosition)
                    Picker(L10n.FormattingView.titlesTextPosition, selection: $formattingOptions.labelPosition) {
                        Text(L10n.FormattingView.TitlesTextPosition.top).tag(TopBottomPosition.top)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Titles.TextPosition.top)
                        Text(L10n.FormattingView.TitlesTextPosition.bottom).tag(TopBottomPosition.bottom)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Titles.TextPosition.bottom)
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(spacing: 0) {
                    Slider(value: $formattingOptions.labelHeightPercentage, in: 0.02...0.25)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Titles.sizeSlider)
                    HStack {
                        Text(L10n.FormattingView.labelSmall).font(.caption).foregroundColor(.secondaryLabel)
                        Spacer()
                        Text(L10n.FormattingView.labelBig).font(.caption).foregroundColor(.secondaryLabel)
                    }
                }

            }

            SimpleCard(title: L10n.FormattingView.marginSectionTitle, titleAccId: AccessibilityIdentifiers.FormattingView.Margins.sectionTitle) {
                VStack(spacing: 0) {
                    Slider(value: $formattingOptions.marginPercentage, in: 0.02...0.25)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Margins.sizeSlider)
                    HStack {
                        Text(L10n.FormattingView.marginSmall).font(.caption).foregroundColor(.secondaryLabel)
                        Spacer()
                        Text(L10n.FormattingView.marginBig).font(.caption).foregroundColor(.secondaryLabel)
                    }
                }
            }

            SimpleCard(title: L10n.FormattingView.gridlinesSectionTitle, titleAccId: AccessibilityIdentifiers.FormattingView.Gridlines.sectionTitle) {
                ColorPicker(L10n.FormattingView.gridlinesColour, selection: $formattingOptions.gridlineColor)
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Gridlines.colour)
                Toggle(isOn: $formattingOptions.thickerGridlines ) {
                    Text(L10n.FormattingView.gridlinesThicker)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Gridlines.thicker)
            }

            #if FitzgeraldKeysFeature
            SimpleCard(title: L10n.FormattingView.fitzgeraldKeysSectionTitle, titleAccId: AccessibilityIdentifiers.FormattingView.fitzgeraldKeysSectionTitle) {
                Toggle(isOn: $formattingOptions.thickerFitzgeraldBorders ) {
                    Text(L10n.FormattingView.fitzgeraldKeysThickerBorders)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.FitzgeraldKeys.thickerBorders)
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


