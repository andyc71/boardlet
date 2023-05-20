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

    //@State var isVertical: Bool
    
    //@State private var orientation = UIDeviceOrientation.unknown
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        //ConditionalStack(isHorizonalStack: !self.isVertical, name: "SelectionViews") {
        ScrollView {
            
            AdaptiveStack(isVertical: horizontalSizeClass == .compact, verticalAlignment: .top) {
                
                PageSizeSelectionView(selectedPageSize: $pageLayoutState.pageSize)
                //.frame(maxHeight: .infinity)
                //.frame(height: 150)
                //.padding()
                
                OrientationSelectionView(pageLayoutState: pageLayoutState)
                //.frame(maxHeight: .infinity)
                //.frame(height: 150)
                //.padding()
            }

            LayoutSelectionView(pageLayoutState: pageLayoutState)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)
                //.padding()
            
            LayoutSummaryView(pageLayoutState: self.pageLayoutState)
                //.padding()
            
                Spacer()

        }
        .navigationBarTitle(L10n.LayoutScreen.title, displayMode: .inline)
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
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
