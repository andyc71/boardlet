//
//  TitleRow2.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import SwiftUI

struct TitleRowAnimationInfo {
    private(set) var namespace: Namespace.ID
    private var itemID: Int
    
    var imageID: String {
        "TitleRowImage-\(itemID)"
    }
    
    var rowContainerID: String {
        "TitleRowContainer-\(itemID)"
    }

    init(namespace: Namespace.ID, itemID: Int) {
        self.namespace = namespace
        self.itemID = itemID
    }
}

struct TitleRowZoomedImage: View {
    @Binding var photo: PhotoItem
    @State var editedPhoto: UIImage?
    var index: Int?
    
    private var safeIndex: Int { index ?? 0 }
    
    @Binding var imageIsZoomed: Bool
    
    var animationInfo: TitleRowAnimationInfo
    
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
            Image(uiImage: editedPhoto ?? photo.image)
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                    .clipped()
                    .cornerRadius(5)
                    .padding(SwiftUI.Edge.Set.trailing, 4)
                    .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.image(for: safeIndex))
                    //Need to have matchedGeometryEffect before frame, otherwise
                    //the animation doesn't work.
                    .matchedGeometryEffect(id: animationInfo.imageID, in: animationInfo.namespace)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        withAnimation { imageIsZoomed.toggle() }
                    }
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
