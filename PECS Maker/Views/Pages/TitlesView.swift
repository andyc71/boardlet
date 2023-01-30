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
    
    func deletePhoto(at index: Int?) {
        guard let index = index else {
            logger.logError(.general, "Cannot delete photo - unexpectedly not found within collection")
            return
        }
        pageLayoutState.deletePhoto(at: index)
    }

    func duplicatePhoto(at index: Int?) {
        guard let index = index else {
            logger.logError(.general, "Cannot duplicate photo - unexpectedly not found within collection")
            return
        }
        pageLayoutState.duplicatePhoto(at: index)
    }

    
    var body: some View {
        List {
            
            ForEach($pageLayoutState.photoBrowserData.photoItems) { $photo in
                let index = pageLayoutState.photoBrowserData.photoItems.firstIndex(where: {$0.id == photo.id })
                
                //We're wrapping the content in an HStack because we want the row content
                //to have a fixed maxWidth, but we want the list to go full width. If we don't
                //do it this way then the user won't be able to scroll unless they swipe over
                //a list item, which will be counter-intuitive on iPad because they would
                //probably try to swipe on the large empty space on the left or right of the list.
                HStack {
                    Spacer(minLength: 0)
                    TitleRow(photo: $photo, index: index ?? -1, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                             onDelete: {
                        deletePhoto(at: index)
                    },
                             onDuplicate: {
                        duplicatePhoto(at: index)
                    })
                    .frame(maxWidth: AppSettings.maxViewWidth)
                    Spacer(minLength: 0)
                }
                .listRowBackground(Color(currentTheme.backgroundColor))
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
        .noPhotosTipView(photoBrowserData: pageLayoutState.photoBrowserData)
        .navigationBarTitle(Text(L10n.TitlesPage.title), displayMode: .inline)
        .padding(.top)
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
