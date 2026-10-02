//
//  TitleRow2.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import SwiftUI
import SharedSwiftUI

struct PhotoCellZoomed: View {
    @EnvironmentObject private var currentTheme: SharedUITheme
    @Binding var photo: PhotoItem?
    @State var editedPhoto: UIImage?
    @State private var photoToDelete: PhotoItem?
    var onDelete: (PhotoItem) -> Void
    var index: Int?
    
    private var safeIndex: Int { index ?? 0 }
    
#if EasyPECSPlus
    func eraseBackground() {
        guard let photo else { return }
        guard let image =  photo.image.removeBackground(returnResult: .finalImage) else {
            return
        }
        editedPhoto = image
    }
#endif
    
    func cropPhoto() {
        guard let photo else { return }
        let newImage = photo.image.trimWhitespace()
        editedPhoto = newImage
    }
    
    func save() {
        guard let editedPhoto else { return }
        photo?.image = editedPhoto
    }
    
    func revert() {
        editedPhoto = nil
    }
    
    func close() {
        photo = nil
    }
    
    func saveAndClose() {
        save()
        close()
    }
    
    var body: some View {
        if let photo {
            VStack {
                    Image(uiImage: editedPhoto ?? photo.image)
                        .resizable()
                        .aspectRatio(contentMode: ContentMode.fit)
                        .clipped()
                        .cornerRadius(5)
                        .padding(SwiftUI.Edge.Set.trailing, 4)
                        .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.image(for: safeIndex))
                        .padding()

                #if DEBUG
                    if let debugInfo = photo.debugInfo {
                        VStack {
                            ForEach(debugInfo, id: \.self) { debugString in
                                Text(debugString)
                            }
                        }
                    }
                #endif


            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                PhotoBottomActionBar {
                    PhotoBottomActionButton(L10n.PhotoContextMenu.deleteButton, symbol: "trash",
                                            id: AccessibilityIdentifiers.PhotoZoomView.deleteButton) {
                        photoToDelete = photo
                    }
                    if editedPhoto == nil {
                        PhotoBottomActionButton(L10n.PhotoZoomView.cropButton, symbol: "crop",
                                                id: AccessibilityIdentifiers.PhotoZoomView.cropButton) {
                            cropPhoto()
                        }
#if EasyPECSPlus
                        PhotoBottomActionButton(L10n.PhotoZoomView.eraseBackgroundButton,
                                                symbol: "wand.and.stars",
                                                id: AccessibilityIdentifiers.PhotoZoomView.eraseBackgroundButton) {
                            eraseBackground()
                        }
#endif
                    }

                    PhotoBottomActionButton("Edit Photo", symbol: "pencil", id: "editBoardPhoto") {
                        PhotoPresentation.edit(editedPhoto ?? photo.image, theme: currentTheme) { image in
                            editedPhoto = image
                        }
                    }
                    if editedPhoto != nil {
                        PhotoBottomActionButton(L10n.PhotoZoomView.revertButton, symbol: "arrow.uturn.backward",
                                                id: AccessibilityIdentifiers.PhotoZoomView.revertButton) {
                            revert()
                        }
                        PhotoBottomActionButton(L10n.PhotoZoomView.saveButton, symbol: "checkmark",
                                                id: AccessibilityIdentifiers.PhotoZoomView.saveButton) {
                            saveAndClose()
                        }
                    }
                }
            }
            .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
            .askToDeletePhoto(photo: $photoToDelete, theme: currentTheme) { photo in
                self.photo = nil
                onDelete(photo)
            }
        }
        else {
            EmptyView()
        }
    }
}
