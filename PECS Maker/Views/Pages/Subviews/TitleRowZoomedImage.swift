//
//  TitleRow2.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import SwiftUI

struct TitleRowZoomedImage: View {
    @Binding var photo: PhotoItem
    @State var editedPhoto: UIImage?
    var index: Int?
    
    private var safeIndex: Int { index ?? 0 }
    
    @Binding var imageIsZoomed: Bool
    

#if EasyPECSPlus
    func eraseBackground() {
        guard let image =  photo.image.removeBackground(returnResult: .finalImage) else {
            return
        }
        editedPhoto = image
    }
    
    func save() {
        guard let editedPhoto else { return }
        photo.image = editedPhoto
    }

    func revert() {
        editedPhoto = nil
    }

    
#endif
    
    var body: some View {
        VStack {
            Button(action: { withAnimation { imageIsZoomed.toggle() } } ) {
                Image(uiImage: editedPhoto ?? photo.image)
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                    .clipped()
                    .cornerRadius(5)
                    .padding(SwiftUI.Edge.Set.trailing, 4)
                    .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.image(for: safeIndex))
            }
            .buttonStyle(BorderlessButtonStyle()) //Critical, or button tap affects all buttons in the list row

            #if EasyPECSPlus
            if editedPhoto == nil {
                StandardButton(action: {
                    eraseBackground()
                }, text: "Erase Background")
            }
            else {
                HStack {
                    StandardButton(action: {
                        save()
                    }, text: "Save")
                    StandardButton(action: {
                        revert()
                    }, text: "Revert")
                }
            }
            #endif
            
        }
    }
}
