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
            
            //ForEach(pageLayoutState.photos) { photo in
            //ForEach(pageLayoutState.photos) { photo in
            ForEach(Array(pageLayoutState.photos.enumerated()), id: \.element) { index, photo in
                TitleRow(photo: $pageLayoutState.photos[index], index: 0, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
//                    onImageTapped: {
//                        self.selectedPhoto = pageLayoutState.photos[i]
//                    },
                    onDelete: {
                        pageLayoutState.deletePhoto(at: 0)
                    },
                    onDuplicate: {
                        pageLayoutState.duplicatePhoto(at: 0)
                    }
//                    onCategorize: {
//                        //pageLayoutState.duplicatePhoto(at: i)
//                    }
                )
                .listRowBackground(Theme.backgroundColor)
                .padding(4)
                //Divider()
            }
            .emptyListPlaceholder(pageLayoutState.photos) {
                TipView(tipText: L10n.TitlesScreen.noPhotosMessage, canHide: false)
            }
//            .sheet(item: $selectedPhoto, content: { photo in
//                //guard let image = selectedPhoto?.image else { return }
//                PhotoZoomView(image: photo.image)
//            })
            
            
            StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: L10n.doneButton, isHorizontal: true)
                .padding()
                .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.doneButton)
                .listRowBackground(Theme.backgroundColor)
                .hideListRowSeparatorIfAvailable()

//                Spacer()
//                .listRowBackground(Theme.backgroundColor)

        }
        .listStyle(PlainListStyle())
        .navigationBarTitle(Text(L10n.TitlesPage.title), displayMode: .inline)
        
        .frame(maxWidth: AppSettings.maxViewWidth)
        //.padding()
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

extension View {
    func hideListRowSeparatorIfAvailable() -> some View {
        if #available(iOS 15.0, *) {
            return AnyView(self.listRowSeparator(.hidden))
        }
        else {
            return AnyView(self)
        }
    }
}
