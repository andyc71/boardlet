//
//  TitleRow2.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import SwiftUI
struct TitleRowZoomedImage: View {
    @Binding var photo: PhotoItem
    var index: Int?
    
    private var safeIndex: Int { index ?? 0 }
    
    @Binding var imageIsZoomed: Bool
    

    
    func eraseBackground() {
        guard let image =  photo.image.removeBackground(returnResult: .finalImage) else {
            return
        }
        photo.image = image
    }

    var body: some View {
        VStack {
            Button(action: { withAnimation { imageIsZoomed.toggle() } } ) {
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                    .clipped()
                    .cornerRadius(5)
                    .padding(SwiftUI.Edge.Set.trailing, 4)
                    .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.image(for: safeIndex))
            }
            .buttonStyle(BorderlessButtonStyle()) //Critical, or button tap affects all buttons in the list row

            #if EasyPECSPlus
            StandardButton(action: {
                eraseBackground()
            }, text: "Erase Background")
            #endif
            
        }
    }
}

struct TitleRow2: View {
    
    @Binding var photo: PhotoItem
    var index: Int?
    private var safeIndex: Int { index ?? 0 }
    @State var imageIsZoomed: Bool = false
    
    var body: some View {
        if imageIsZoomed {
            TitleRowZoomedImage(photo: $photo, index: index, imageIsZoomed: $imageIsZoomed)
        }
        else {
            TitleRowThumbnailImage(photo: $photo, index: index, imageIsZoomed: $imageIsZoomed)
        }
    }
}

struct TitleRowThumbnailImage: View {
    
    @Binding var photo: PhotoItem
    var index: Int?
    private var safeIndex: Int { index ?? 0 }
    @Binding var imageIsZoomed: Bool
    
    var body: some View {
        
        HStack {
            //Button(action: { onImageTapped?() }) {
            Button(action: { withAnimation { imageIsZoomed.toggle() } } ) {
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                    .width(AppSettings.labelRowHeight)
                    .maxHeight(AppSettings.labelRowHeight)
                    .clipped()
                    .cornerRadius(5)
                    .padding(SwiftUI.Edge.Set.trailing, 4)
                    .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.image(for: safeIndex))
            }
            .buttonStyle(BorderlessButtonStyle()) //Critical, or button tap affects all buttons in the list row

            Divider()
            TextField(L10n.TitlesPage.titleTextPlaceholder, text: $photo.title)
                .autocapitalization(.none)
                .padding(4)
                .background(Color.tertiarySystemFill)
                .cornerRadius(4)
                .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.titleText(for: safeIndex))
        }
    }
}

struct TitleRow2_Previews: PreviewProvider {
    @State static var photoItem = PhotoItem(image: UIImage(systemName: "music.note")!, title: "Music")
    static let index = 0
    static var previews: some View {
        TitleRow2(photo: $photoItem, index: index)
    }
}
