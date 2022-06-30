//
//  TitlesView.swift
//  PECS Maker
//
//  Created by Andy on 8/11/2021.
//

import SwiftUI
import PhotosUI
import LogFramework
import SharedSwiftUI

struct TitlesView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    @State var selectedPhoto: PhotoItem?
    

    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
        MFAnalytics.logScreenView(screenName: "Titles")
    }
    
    var body: some View {
        ScrollView {
            
            let items = pageLayoutState.photos
            ForEach(items.indices, id: \.self) { i in
            
            //ForEach(pageLayoutState.photos) { photo in
                TitleRow(photo: $pageLayoutState.photos[i], index: i, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
//                    onImageTapped: {
//                        self.selectedPhoto = pageLayoutState.photos[i]
//                    },
                    onDelete: {
                        pageLayoutState.deletePhoto(at: i)
                    },
                    onDuplicate: {
                        pageLayoutState.duplicatePhoto(at: i)
                    }
//                    onCategorize: {
//                        //pageLayoutState.duplicatePhoto(at: i)
//                    }
                )
                .padding(4)
                Divider()
            }
            .emptyListPlaceholder(items) {
                TipView(tipText: L10n.TitlesScreen.noPhotosMessage, canHide: false)
            }
//            .sheet(item: $selectedPhoto, content: { photo in
//                //guard let image = selectedPhoto?.image else { return }
//                PhotoZoomView(image: photo.image)
//            })
            
            
            StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: L10n.doneButton, isHorizontal: true)
                .padding()
                .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.doneButton)

                Spacer()

        }
        //.listStyle(PlainListStyle())
        .navigationBarTitle(Text(L10n.TitlesPage.title), displayMode: .inline)
        
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))
        .onDisappear { dismissAction() }
        
    }
}

struct TitlesView_Previews: PreviewProvider {
    
    @ObservedObject static var pageLayoutState = PageLayoutState()

    static var previews: some View {
        TitlesView(pageLayoutState: pageLayoutState, dismissAction: {})
    }
}
