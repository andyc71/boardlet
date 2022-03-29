//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI

let colors: [Color] = [.red, .green, .blue, .yellow, .purple]
 
@ViewBuilder
func ColorView() -> some View {
    (colors.randomElement() ?? .gray)
        .cornerRadius(10)
        .frame(minHeight: 40)
}

struct LayoutSelectionView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    //var pageLayoutState: PageLayoutState

    let gridItem = GridItem(.fixed(50))

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SelectionHeading(text: "Layout")
                .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.layoutHeading)

            LazyVGrid(columns: [gridItem, gridItem, gridItem]) {

                ForEach((0..<pageLayoutState.availableLayouts.count), id: \.self) { i in
                //ForEach((0...5), id: \.self) { i in
                    let layoutSize = pageLayoutState.availableLayouts[i]
                    let isSelected = pageLayoutState.pageLayout == layoutSize
                    Button(action: {
                        pageLayoutState.pageLayout = layoutSize
                    }) {
                        
                        //Spacer()
                        LayoutView(pageLayoutState: pageLayoutState, cols: Int(layoutSize.width), rows: Int(layoutSize.height), isSelected: isSelected, aspectRatio: pageLayoutState.aspectRatio)
                        //.frame(width: geometry.size.width / 2)
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.layoutButton(for: layoutSize))
                    .if(isSelected) { view in
                        view.accessibility(addTraits: [.isSelected])
                    }
                    //Spacer()
                     
                }

            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(ColorNames.lightBlue))
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            

            /* TODO
            LayoutSummaryView(pageLayoutState: pageLayoutState)
            //.frame(maxHeight: .infinity)
            //.frame(height: 150)
                .padding()
             */

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
