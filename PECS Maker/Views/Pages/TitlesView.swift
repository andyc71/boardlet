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
    
    @State var showTopicSelectionAlert: Bool = false
    @State var showPhotoCopySuccessAlert: Bool = false
    
    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        List {
            ForEach($pageLayoutState.photoBrowserData.photoItems) { $photo in
                let index = pageLayoutState.photoBrowserData.photoItems.firstIndex(of: photo)
                TitleRow2(photo: $photo, index: index)
                .listRowBackground(Color(currentTheme.backgroundColor))
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
        .emptyListPlaceholder(pageLayoutState.photoBrowserData.photoItems) {
            VStack {
                TipView(tipText: L10n.TitlesScreen.noPhotosMessage, canHide: false)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TitlesScreen.noPhotosTip)
                Spacer()
            }
            .padding()
            .listRowBackground(Color(currentTheme.backgroundColor))
            .hideListRowSeparatorIfAvailable()
        }
        .navigationBarTitle(Text(L10n.TitlesPage.title), displayMode: .inline)
        
        .frame(maxWidth: AppSettings.maxViewWidth)
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
