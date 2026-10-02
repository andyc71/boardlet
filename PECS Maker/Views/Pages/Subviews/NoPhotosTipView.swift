//
//  NoPhotosTipView.swift
//  PECS Maker
//
//  Created by Andy on 11/02/2023.
//

import SwiftUI
import SharedSwiftUI
import LogFramework
import LogFrameworkFirebase
import FeatureFramework

struct NoPhotosTipView: View {
    enum Presentation { case list, card }
    enum Source: String {
        case mainMenu = "MainMenu"
        case photoList = "PhotoList"
        case titles = "Titles"
    }

    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    @ObservedObject var pageLayoutState: PageLayoutState
    let source: Source
    var presentation: Presentation = .list

#if EasyPECSPlus
    @State private var showAACStandardSymbolsPicker = false
#endif
    @State private var showARASAACSymbolsPicker = false

    var body: some View {
        Group {
            if presentation == .list {
                content
                    .frame(maxWidth: AppSettings.maxViewWidth)
                    .padding()
                    .listRowBackground(Color(currentTheme.backgroundColor))
                    .hideListRowSeparatorIfAvailable()
            } else {
                content
                    .frame(maxWidth: .infinity)
            }
        }
#if EasyPECSPlus
        .selectAACStandardSymbols(isPresented: $showAACStandardSymbolsPicker,
                                  pageLayoutState: pageLayoutState,
                                  isAdditive: AppSettings.photoPickerIsAdditive)
#endif
        .selectARASAACSymbols(isPresented: $showARASAACSymbolsPicker,
                              pageLayoutState: pageLayoutState,
                              isAdditive: AppSettings.photoPickerIsAdditive)
    }

    private var content: some View {
        VStack(spacing: 14) {
            TipView(tipText: L10n.NoPhotosView.message,
                    image: MFImage(systemName: "photo", tint: .mfVeryBrightBlue),
                    canHide: false,
                    accessibilityIdentifier: AccessibilityIdentifiers.NoPhotosView.tipView)

            CapsuleButton(L10n.NoPhotosView.addPhotosButton, role: .primary) {
                logAction("selectPhotos")
                selectPhotos(pageLayoutState: pageLayoutState,
                             isAdditive: AppSettings.photoPickerIsAdditive,
                             currentTheme: currentTheme)
            }
            .accessibilityIdentifier(presentation == .card
                                     ? AccessibilityIdentifiers.MainMenu.selectPhotoButton
                                     : AccessibilityIdentifiers.NoPhotosView.addPhotosButton)
            .accessibilityHint(L10n.MainMenu.selectPhotosHint)
            .frame(maxWidth: AppSettings.maxButtonWidth)

            if FeatureFlags.current.arasaacSymbolsEnabled {
                CapsuleButton(L10n.MainMenu.symbolSearchButton, role: .secondary) {
                    logAction("ARASAACSymbolSearch")
                    showARASAACSymbolsPicker = true
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.symbolSearchButton)
                .accessibilityHint(L10n.MainMenu.symbolSearchHint)
                .frame(maxWidth: AppSettings.maxButtonWidth)
            }

#if EasyPECSPlus
            CapsuleButton(L10n.Symbols.aacStandard, role: .secondary) {
                logAction("AACStandardSymbolSearch")
                showAACStandardSymbolsPicker = true
            }
            .accessibilityIdentifier("aacStandardSymbolSearchButton")
            .frame(maxWidth: AppSettings.maxButtonWidth)
#endif

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                CapsuleButton(L10n.NoPhotosView.takePhotoButton, role: .secondary) {
                    logAction("takePhoto")
                    takeBoardPhoto(pageLayoutState: pageLayoutState)
                }
                .accessibilityIdentifier(presentation == .card
                                         ? "takeBoardPhoto"
                                         : AccessibilityIdentifiers.NoPhotosView.takePhotoButton)
                .accessibilityHint(L10n.MainMenu.takePhotoHint)
                .frame(maxWidth: AppSettings.maxButtonWidth)
            }

            if presentation == .list { Spacer() }
        }
    }

    private func logAction(_ action: String) {
        MFAnalytics.logScreenView(screenName: "\(action)From\(source.rawValue)")
        featuresViewModel.logEvent()
    }
}

extension View {
    
    @ViewBuilder
    func noPhotosTipView(pageLayoutState: PageLayoutState, source: NoPhotosTipView.Source) -> some View {
        
        if pageLayoutState.photoBrowserData.photoItems.isEmpty {
            NoPhotosTipView(pageLayoutState: pageLayoutState, source: source)
        }
        else {
            self
        }
        
    }
}
