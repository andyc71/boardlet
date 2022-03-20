//
//  PageSizeAndLayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import PhotosUI
import LogFramework

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
                .padding()

            OrientationSelectionView(pageLayoutState: pageLayoutState, horizontalStack: isVertical)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)
                .padding()

            LayoutSelectionView(pageLayoutState: pageLayoutState, horizontalStack: isVertical)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)
                .padding()
            
            LayoutSummaryView(pageLayoutState: self.pageLayoutState)
                .padding()
            
            
            StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: "Done", isHorizontal: true)
                .padding()

                Spacer()

        }
        .navigationBarTitle(Text("Layout"), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))
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
