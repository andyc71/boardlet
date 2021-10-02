//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI

struct LayoutSelectionView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    //var pageLayoutState: PageLayoutState

    var horizontalStack: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SelectionHeading(text: "Layout")
            
            ConditionalStack(isHorizonalStack: horizontalStack) {
                Spacer()
                ForEach(pageLayoutState.availableLayouts) { layoutSize in
                    Button(action: {
                        pageLayoutState.pageLayout = layoutSize
                    }) {
                        
                        //Spacer()
                        let isSelected = pageLayoutState.pageLayout == layoutSize
                        LayoutView(pageLayoutState: pageLayoutState, cols: Int(layoutSize.width), rows: Int(layoutSize.height), isSelected: isSelected, aspectRatio: pageLayoutState.aspectRatio)
                        //.frame(width: geometry.size.width / 2)
                    }
                    
                    //Spacer()
                }
                Spacer()

            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(ColorNames.lightBlue))
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])

            Spacer()
        }
        .navigationBarTitle(Text("Layout"), displayMode: .inline)

        
        
    }
}
//
//struct LayoutSelectionView_Previews: PreviewProvider {
//    @State static var selectedLayout = CGSize(width: 2, height: 2)
//    @State static var availableLayouts: [CGSize] = [
//        CGSize(width: 2, height: 2),
//        CGSize(width: 2, height: 3)
//    ]
//    
//    
//    static var previews: some View {
////        LayoutSelectionView(availableLayouts: $availableLayouts, selectedLayout: $selectedLayout, horizontalStack: true, aspectRatio: 0.7)
//    }
//}
