//
//  SelectionViews.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import PhotosUI

struct SelectionViews: View {
    
    @Binding var photoData: [PhotoPickerData?]
    @ObservedObject var pageLayoutState: PageLayoutState

    @State var isVertical: Bool
    
    var body: some View {
        ConditionalStack(isHorizonalStack: self.isVertical, name: "SelectionViews") {
            PageSizeSelectionView(selectedPageSize: $pageLayoutState.pageSize)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)

            LayoutSelectionView(pageLayoutState: pageLayoutState, horizontalStack: isVertical)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)

        }
        .frame(maxWidth: .infinity)
        .if(isVertical) { view in
            view.frame(height: 150)
        }
        .if(!isVertical) { view in
            view.frame(width: 200)
        }
        
    }
}

//struct SelectionViews_Previews: PreviewProvider {
//    
//    @ObservedObject static var pageLayoutState = PageLayoutState()
//
//    static var previews: some View {
//        SelectionViews(pageLayoutState: pageLayoutState, isVertical: true)
//    }
//}
