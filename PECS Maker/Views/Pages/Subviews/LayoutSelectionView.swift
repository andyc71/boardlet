//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

//let colors: [Color] = [.red, .green, .blue, .yellow, .purple]
//
//@ViewBuilder
//func ColorView() -> some View {
//    (colors.randomElement() ?? .gray)
//        .cornerRadius(10)
//        .frame(minHeight: 40)
//}

struct LayoutSelectionView: View, Equatable {
    
    static func == (lhs: LayoutSelectionView, rhs: LayoutSelectionView) -> Bool {
        lhs.pageLayoutState.availableLayouts == rhs.pageLayoutState.availableLayouts &&
        lhs.pageLayoutState.pageLayout == rhs.pageLayoutState.pageLayout
    }
    
    
    @ObservedObject var pageLayoutState: PageLayoutState
    //var pageLayoutState: PageLayoutState
    
    let gridItem = GridItem(.fixed(50))
    
    var columns: [GridItem] {
        let layoutCounts = pageLayoutState.availableLayouts.count
        let colCount = min(layoutCounts, pageLayoutState.orientation == .portrait ? 6 : 5)
        return Array(repeating: gridItem, count: colCount)
    }
    
    var body: some View {
        
        SimpleCard(title: L10n.LayoutSelectionView.title, titleAccId: AccessibilityIdentifiers.LayoutScreen.layoutHeading) {
            
            LazyVGrid(columns: self.columns) {
                //HStack{
                
                //ForEach((0..<pageLayoutState.availableLayouts.count), id: \.self) { i in
                //ForEach((0...5), id: \.self) { i in
                ForEach(pageLayoutState.availableLayouts, id: \.self) { layoutSize in
                    //let layoutSize = pageLayoutState.availableLayouts[i]
                    let isSelected = pageLayoutState.pageLayout == layoutSize
                    Button(action: {
                        pageLayoutState.pageLayout = layoutSize
                    }) {
                        //print("Layout state - ")
                        //Spacer()
                        LayoutView(pageLayoutState: pageLayoutState, layout: layoutSize, isSelected: isSelected)
                        //.frame(width: geometry.size.width / 2)
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.layoutButton(for: layoutSize))
                    .if(isSelected) { view in
                        view.accessibility(addTraits: [.isSelected])
                    }
                    //Spacer()
                    
                }
                
            }
        }
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
