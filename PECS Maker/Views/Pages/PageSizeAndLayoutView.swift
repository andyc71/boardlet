//
//  PageSizeAndLayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import PhotosUI
import LogFramework
import SharedSwiftUI

struct PageSizeAndLayoutView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState

    @State var isVertical: Bool
    
    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, isVertical: Bool, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.isVertical = isVertical
        self.dismissAction = dismissAction
        MFAnalytics.logScreenView(screenName: "PageSizeAndLayout")
    }
    
    var body: some View {
        //ConditionalStack(isHorizonalStack: !self.isVertical, name: "SelectionViews") {
        ScrollView {
            PageSizeSelectionView(selectedPageSize: $pageLayoutState.pageSize)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)
                //.padding()

            OrientationSelectionView(pageLayoutState: pageLayoutState)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)
                //.padding()

            LayoutSelectionView(pageLayoutState: pageLayoutState)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)
                //.padding()
            
            LayoutSummaryView(pageLayoutState: self.pageLayoutState)
                //.padding()
            
            StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: L10n.LayoutScreen.doneButton, isHorizontal: true)
                .padding()
                .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.doneButton)

                Spacer()

        }
        .navigationBarTitle(L10n.LayoutScreen.title, displayMode: .inline)
        //.frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear { dismissAction() }
    }
}

//struct PageSizeAndLayoutView_Previews: PreviewProvider {
//    
//    @ObservedObject static var pageLayoutState = PageLayoutState()
//
//    static var previews: some View {
////        PageSizeAndLayoutView(pageLayoutState: pageLayoutState, isVertical: true, dismissAction: {})
//    }
//}
