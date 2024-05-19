//
//  NoPhotosTipView.swift
//  PECS Maker
//
//  Created by Andy on 11/02/2023.
//

import SwiftUI
import SharedSwiftUI

struct NoPhotosTipView : View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    var body: some View {
        //emptyListPlaceholder(pageLayoutState.photoBrowserData.photoItems) {
            VStack {
                TipView(
                    tipText: L10n.NoPhotosView.message,
                    //image: MFImage(named: "AddPhoto", tint: .mfVeryBrightBlue),
                    image: MFImage(systemName: "photo", tint: .mfVeryBrightBlue),
                        canHide: false, accessibilityIdentifier: AccessibilityIdentifiers.NoPhotosView.tipView)
                CapsuleButton(text: L10n.NoPhotosView.addPhotosButton, action: {
                    self.selectPhotos(pageLayoutState: pageLayoutState, preselectItems: AppSettings.preselectPhotosInPicker, isAdditive: AppSettings.photoPickerIsAdditive, currentTheme: currentTheme)
                })
                .accessibilityIdentifier(AccessibilityIdentifiers.NoPhotosView.addPhotosButton)
                .frame(maxWidth: AppSettings.maxButtonWidth)
                Spacer()
            }
            .frame(maxWidth: AppSettings.maxViewWidth)
            .padding()
            .listRowBackground(Color(currentTheme.backgroundColor))
            .hideListRowSeparatorIfAvailable()
        //}
    }
}

extension View {
    
    @ViewBuilder
    func noPhotosTipView(pageLayoutState: PageLayoutState) -> some View {
        
        if pageLayoutState.photoBrowserData.photoItems.isEmpty {
            NoPhotosTipView(pageLayoutState: pageLayoutState)
        }
        else {
            self
        }
        
    }
}

