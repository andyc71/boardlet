//
//  TitleRow2.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import SwiftUI
struct TitleRow2: View {
    
    @Binding var photo: PhotoItem
    var index: Int?
    private var safeIndex: Int { index ?? 0 }
    @State var imageIsZoomed: Bool = false
    
    @Namespace private var animationNamespace
    
    var body: some View {
        let animationInfo = TitleRowAnimationInfo(namespace: animationNamespace, itemID: safeIndex)
        if imageIsZoomed {
            TitleRowZoomedImage(photo: $photo, index: index, imageIsZoomed: $imageIsZoomed, animationInfo: animationInfo)
        }
        else {
            TitleRowThumbnailImage(photo: photo, index: index, imageIsZoomed: $imageIsZoomed, animationInfo: animationInfo)
        }
    }
}

struct TitleRowThumbnailImage: View {
    
    @ObservedObject var photo: PhotoItem
    var index: Int?
    private var safeIndex: Int { index ?? 0 }
    @Binding var imageIsZoomed: Bool
    
    var animationInfo: TitleRowAnimationInfo

    var body: some View {
        
        HStack {
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
                .clipped()
                .cornerRadius(5)
                .padding(SwiftUI.Edge.Set.trailing, 4)
                .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.image(for: safeIndex))
                //Need to have matchedGeometryEffect before frame, otherwise
                //the animation doesn't work.
                .matchedGeometryEffect(id: animationInfo.imageID, in: animationInfo.namespace)
                .width(AppSettings.labelRowHeight)
                .maxHeight(AppSettings.labelRowHeight)
                .onTapGesture {
                    withAnimation { imageIsZoomed.toggle()
                    }
                }
            
            
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
