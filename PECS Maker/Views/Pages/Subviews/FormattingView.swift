//
//  FormattingView.swift
//  PECS Maker
//
//  Created by Andy on 22/03/2022.
//

import SwiftUI
import SharedSwiftUI
import LogFramework
import SettingsFramework
import LogFrameworkFirebase
import FeatureFramework

struct FormattingView: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    
    @ObservedObject var formattingOptions: CollageFormatting
    
    //@Environment(\.isPresented) private var isPresented
    @Environment(\.presentationMode) private var presentationMode
    
    var dismissAction: ()->()

    var body: some View {
        ScrollView {
            
            PopupHeader(title: L10n.FormattingView.title, hasCloseButton: true)
            
            // Board Title Section (New)
            SimpleCard(title: L10n.FormattingView.BoardSection.title, titleAccId: AccessibilityIdentifiers.FormattingView.BoardSection.title) {
                
                Toggle(isOn: $formattingOptions.pageTitleVisible) {
                    Text(L10n.FormattingView.BoardSection.showTitle)
                }
                
                ColorPicker(L10n.FormattingView.Font.color, selection: $formattingOptions.pageTitleColor)
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardSection.Font.color)
                
                Toggle(isOn: $formattingOptions.pageTitleBoldFont) {
                    Text(L10n.FormattingView.Font.bold)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardSection.Font.bold)

                /* Text alignment
                HStack {
                    Text(L10n.FormattingView.boardTitleAlignment)
                    Picker(L10n.FormattingView.boardTitleAlignment, selection: $formattingOptions.pageTitleAlignment) {
                        Text(L10n.FormattingView.BoardTitleAlignment.left).tag(TextAlignment.left)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardTitle.Alignment.left)
                        Text(L10n.FormattingView.BoardTitleAlignment.center).tag(TextAlignment.center)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardTitle.Alignment.center)
                        Text(L10n.FormattingView.BoardTitleAlignment.right).tag(TextAlignment.right)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardTitle.Alignment.right)
                    }
                    .pickerStyle(.segmented)
                }*/
                
                VStack(spacing: 0) {
                    Slider(value: $formattingOptions.pageTitleHeightPercentage, in: 0.05...0.20)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardSection.Font.Size.slider)
                    HStack {
                        Text(L10n.FormattingView.Font.Size.small).font(.caption).foregroundColor(.secondaryLabel)
                        Spacer()
                        Text(L10n.FormattingView.Font.Size.large).font(.caption).foregroundColor(.secondaryLabel)
                    }
                }
            }
            
            // Card Titles Section (Renamed from Titles)
            SimpleCard(title: L10n.FormattingView.CardSection.title, titleAccId: AccessibilityIdentifiers.FormattingView.CardSection.title) {
                
                ColorPicker(L10n.FormattingView.Font.color, selection: $formattingOptions.cardTitleFontColor)
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.Font.color)
                
                Toggle(isOn: $formattingOptions.cardTitleFontBold ) {
                    Text(L10n.FormattingView.Font.bold)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.Font.bold)
                
                HStack {
                    Text(L10n.FormattingView.TextPosition.title)
                    Picker(L10n.FormattingView.TextPosition.title, selection: $formattingOptions.cardTitlePosition) {
                        Text(L10n.FormattingView.TextPosition.top).tag(TopBottomPosition.top)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.TextPosition.top)
                        Text(L10n.FormattingView.TextPosition.bottom).tag(TopBottomPosition.bottom)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.TextPosition.bottom)
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(spacing: 0) {
                    Slider(value: $formattingOptions.cardTitleFontHeightPercentage, in: 0.02...0.25)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.Font.Size.slider)
                    HStack {
                        Text(L10n.FormattingView.Font.Size.small).font(.caption).foregroundColor(.secondaryLabel)
                        Spacer()
                        Text(L10n.FormattingView.Font.Size.large).font(.caption).foregroundColor(.secondaryLabel)
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
                        Text(L10n.FormattingView.marginLarge).font(.caption).foregroundColor(.secondaryLabel)
                    }
                }
            }

            SimpleCard(title: L10n.FormattingView.gridlinesSectionTitle, titleAccId: AccessibilityIdentifiers.FormattingView.Gridlines.sectionTitle) {
                ColorPicker(L10n.FormattingView.gridlinesColour, selection: $formattingOptions.gridlinesColor)
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Gridlines.colour)
                Toggle(isOn: $formattingOptions.gridlinesThick ) {
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
            
            SimpleCard(title: L10n.FormattingView.cellBackgroundTitle, titleAccId: AccessibilityIdentifiers.FormattingView.CellBackground.sectionTitle) {
                ColorPicker(L10n.FormattingView.cellBackgroundColour, selection: $formattingOptions.cellFillColor)
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CellBackground.colour)
            }
            
//            SimpleCard {
//                SettingsRow2(imageName: "gearshape.2", title: "Advanced Settings", destination: {
//                        AdvancedFormattingView()
//                })
//                //.accessibilityIdentifier(A12SSUI.SettingsScreen.AboutCard.creditsButton)
//
//            }
//            .padding()
            

            //Spacer()

        }
        //.navigationBarTitle(Text(L10n.FormattingView.title), displayMode: .inline)
//        .navigationBarItems(leading:
//            Button(systemImage: SFSymbolName.chevronLeft, action: {
//            DispatchQueue.main.async {
//                dismissAction()
//                //presentationMode.dismiss()
//            }
//            })
//        )
        //.frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        //.frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear {
            formattingOptions.saveToUserDefaults()
        }
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Formatting")
            featuresViewModel.logEvent()
        }

    }
}

// MARK: - Extensions for new localization keys and accessibility identifiers

// Add these to your L10n.FormattingView enum/struct:
extension L10n.FormattingView {
    
    // Board Title Alignment options
    enum BoardTitleAlignment {
        static let left = "Left"
        static let center = "Center"
        static let right = "Right"
    }
        
}

