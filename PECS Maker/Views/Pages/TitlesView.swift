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
    }
    
    var body: some View {
        List {
            
            //ForEach(pageLayoutState.photos) { photo in
            //ForEach(pageLayoutState.photos) { photo in
            ForEach(Array(pageLayoutState.photos.enumerated()), id: \.element) { index, photo in
            //ForEach(Array(zip(pageLayoutState.photos.indices, pageLayoutState.photos)), id: \.1) { index, photo  in
                TitleRow(photo: $pageLayoutState.photos[index], index: index, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
//                    onImageTapped: {
//                        self.selectedPhoto = pageLayoutState.photos[i]
//                    },
                    onDelete: {
                        pageLayoutState.deletePhoto(at: index)
                    },
                    onDuplicate: {
                        pageLayoutState.duplicatePhoto(at: index)
                    }
//                    onCategorize: {
//                        //pageLayoutState.duplicatePhoto(at: i)
//                    }
                )
                .listRowBackground(Color(currentTheme.backgroundColor))
                //.padding(.horizontal, 16)
                .padding(.vertical, 4)
                //Divider()
            }
            
            VStack {
                StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: L10n.doneButton)
                    .accessibility(identifier: AccessibilityIdentifiers.TitlesScreen.doneButton)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color(currentTheme.backgroundColor))
            .hideListRowSeparatorIfAvailable()
                

        }
        .listStyle(PlainListStyle())
        .emptyListPlaceholder(pageLayoutState.photos) {
            VStack {
                TipView(tipText: L10n.TitlesScreen.noPhotosMessage, canHide: false)
                Spacer()
            }
            .padding()
            .listRowBackground(Color(currentTheme.backgroundColor))
            .hideListRowSeparatorIfAvailable()
        }
        .navigationBarTitle(Text(L10n.TitlesPage.title), displayMode: .inline)
        
        .frame(maxWidth: AppSettings.maxViewWidth)
        //.padding()
        .frame(maxWidth: .infinity)
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear { dismissAction() }
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Titles")
        }
        
    }
}

extension View {
    func scrollContentHideBackground() -> some View {
        if #available(iOS 16.0, *) {
            return self.scrollContentBackground(.hidden)
        } else {
            return self
        }
    }
}

/*
struct TitlesView_Previews: PreviewProvider {
    
    @ObservedObject static var pageLayoutState = PageLayoutState()

    static var previews: some View {
        TitlesView(pageLayoutState: pageLayoutState, dismissAction: {})
    }
}
 */

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
