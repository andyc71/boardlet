// FormattingView.swift
// PECS Maker

import SwiftUI
import SharedSwiftUI
import SettingsFramework
import LogFramework
import LogFrameworkFirebase
import FeatureFramework

struct FormattingView: View {
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    @ObservedObject var formattingOptions: CollageFormatting

    var dismissAction: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(L10n.FormattingView.BoardSection.showTitle,
                           isOn: $formattingOptions.pageTitleVisible)
                    ColorPicker(L10n.FormattingView.Font.color,
                                selection: $formattingOptions.pageTitleColor)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardSection.Font.color)
                    Toggle(L10n.FormattingView.Font.bold,
                           isOn: $formattingOptions.pageTitleBoldFont)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardSection.Font.bold)
                    VStack(spacing: 0) {
                        Slider(value: $formattingOptions.pageTitleHeightPercentage, in: 0.05...0.20)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardSection.Font.Size.slider)
                        HStack {
                            Text(L10n.FormattingView.Font.Size.small)
                            Spacer()
                            Text(L10n.FormattingView.Font.Size.large)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text(L10n.FormattingView.BoardSection.title)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.BoardSection.title)
                }

                Section {
                    ColorPicker(L10n.FormattingView.Font.color,
                                selection: $formattingOptions.cardTitleFontColor)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.Font.color)
                    Toggle(L10n.FormattingView.Font.bold,
                           isOn: $formattingOptions.cardTitleFontBold)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.Font.bold)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.FormattingView.TextPosition.title)
                        Picker(L10n.FormattingView.TextPosition.title,
                               selection: $formattingOptions.cardTitlePosition) {
                            Text(L10n.FormattingView.TextPosition.top)
                                .tag(TopBottomPosition.top)
                                .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.TextPosition.top)
                            Text(L10n.FormattingView.TextPosition.bottom)
                                .tag(TopBottomPosition.bottom)
                                .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.TextPosition.bottom)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    VStack(spacing: 0) {
                        Slider(value: $formattingOptions.cardTitleFontHeightPercentage, in: 0.02...0.25)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.Font.Size.slider)
                        HStack {
                            Text(L10n.FormattingView.Font.Size.small)
                            Spacer()
                            Text(L10n.FormattingView.Font.Size.large)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text(L10n.FormattingView.CardSection.title)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CardSection.title)
                }

                Section {
                    VStack(spacing: 0) {
                        Slider(value: $formattingOptions.marginPercentage, in: 0.02...0.25)
                            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Margins.sizeSlider)
                        HStack {
                            Text(L10n.FormattingView.marginSmall)
                            Spacer()
                            Text(L10n.FormattingView.marginLarge)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text(L10n.FormattingView.marginSectionTitle)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Margins.sectionTitle)
                }

                Section {
                    ColorPicker(L10n.FormattingView.gridlinesColour,
                                selection: $formattingOptions.gridlinesColor)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Gridlines.colour)
                    Toggle(L10n.FormattingView.gridlinesThicker,
                           isOn: $formattingOptions.gridlinesThick)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Gridlines.thicker)
                } header: {
                    Text(L10n.FormattingView.gridlinesSectionTitle)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.Gridlines.sectionTitle)
                }

                #if FitzgeraldKeysFeature
                Section {
                    Toggle(L10n.FormattingView.fitzgeraldKeysThickerBorders,
                           isOn: $formattingOptions.thickerFitzgeraldBorders)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.FitzgeraldKeys.thickerBorders)
                } header: {
                    Text(L10n.FormattingView.fitzgeraldKeysSectionTitle)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.fitzgeraldKeysSectionTitle)
                }
                #endif

                Section {
                    ColorPicker(L10n.FormattingView.cellBackgroundColour,
                                selection: $formattingOptions.cellFillColor)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CellBackground.colour)
                } header: {
                    Text(L10n.FormattingView.cellBackgroundTitle)
                        .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.CellBackground.sectionTitle)
                }
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.FormattingView.content)
            .scrollContentBackground(.hidden)
            .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
            .navigationTitle(L10n.FormattingView.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismissAction()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier(AccessibilityIdentifiersSSUI.PopupHeader.closeButton)
                }
            }
        }
        .onDisappear {
            formattingOptions.saveToUserDefaults()
        }
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Formatting")
            featuresViewModel.logEvent()
        }
    }
}

extension L10n.FormattingView {
    enum BoardTitleAlignment {
        static let left = "Left"
        static let center = "Center"
        static let right = "Right"
    }
}
