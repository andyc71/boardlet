//
//  NoPhotosTipView.swift
//  PECS Maker
//
//  Created by Andy on 11/02/2023.
//

import SwiftUI
import SharedSwiftUI

struct NoPhotosTipView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct NoPhotosTipView_Previews: PreviewProvider {
    static var previews: some View {
        NoPhotosTipView()
    }
}

extension View {
    func noPhotosTipView(pageLayoutState: PageLayoutState) -> some View {
        self.emptyListPlaceholder(pageLayoutState.photoBrowserData.photoItems) {
            VStack {
                TipView(
                    tipText: L10n.NoPhotosView.message,
                    //image: MFImage(named: "AddPhoto", tint: .mfVeryBrightBlue),
                    image: MFImage(systemName: "photo", tint: .mfVeryBrightBlue),
                        canHide: false, accessibilityIdentifier: AccessibilityIdentifiers.NoPhotosView.tipView)
                CapsuleButton(text: L10n.NoPhotosView.addPhotosButton, action: {
                    self.selectPhotos(pageLayoutState: pageLayoutState, preselectItems: AppSettings.preselectPhotosInPicker, isAdditive: AppSettings.photoPickerIsAdditive)
                })
                .accessibilityIdentifier(AccessibilityIdentifiers.NoPhotosView.addPhotosButton)
                .frame(maxWidth: AppSettings.maxButtonWidth)
                Spacer()
            }
            .frame(maxWidth: AppSettings.maxViewWidth)
            .padding()
            .listRowBackground(Color(currentTheme.backgroundColor))
            .hideListRowSeparatorIfAvailable()
        }
    }
}
