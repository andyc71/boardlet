//
//  TitleRow2.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import SwiftUI

struct PhotoCellZoomed: View {
    @Binding var photo: PhotoItem?
    @State var editedPhoto: UIImage?
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

                HStack {
                    
                    if editedPhoto == nil {
                        StandardButton(action: {
                            cropPhoto()
                        }, text: L10n.PhotoZoomView.cropButton)
                        .accessibility(identifier: AccessibilityIdentifiers.PhotoZoomView.cropButton)
                    }
                    
#if EasyPECSPlus
                    if editedPhoto == nil {
                        StandardButton(action: {
                            eraseBackground()
                        }, text: L10n.PhotoZoomView.eraseBackgroundButton)
                    }
                        .accessibility(identifier: AccessibilityIdentifiers.PhotoZoomView.eraseBackgroundButton)
#endif
                    
                    
                    if editedPhoto != nil {
                        
                        StandardButton(action: {
                            revert()
                        }, text: L10n.PhotoZoomView.revertButton)
                        .accessibility(identifier: AccessibilityIdentifiers.PhotoZoomView.revertButton)
                        StandardButton(action: {
                            saveAndClose()
                        }, text: L10n.PhotoZoomView.saveButton)
                        .accessibility(identifier: AccessibilityIdentifiers.PhotoZoomView.saveButton)
                    }
                    else {
                        StandardButton(action: {
                            saveAndClose()
                        }, text: L10n.PhotoZoomView.closeButton)
                        .accessibility(identifier: AccessibilityIdentifiers.PhotoZoomView.closeButton)
                    }
                }
                
            }
            .padding()
        }
        else {
            EmptyView()
        }
    }
}

