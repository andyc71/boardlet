//
//  OrientationSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct OrientationSelectionView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    var body: some View {
        
        SimpleCard(title: L10n.OrientationSelectionView.title, titleAccId: AccessibilityIdentifiers.LayoutScreen.orientationHeading) {
            
            HStack {
                ForEach(0..<PageOrientation.allCases.count, id:\.self) { index in
                    let orientation = PageOrientation.allCases[index]
                    let isSelected = pageLayoutState.orientation == orientation
                    Button(action: {
                        pageLayoutState.orientation = orientation
                    }) {
                        
                        //Spacer()
                        //LayoutView(pageLayoutState: pageLayoutState, cols: Int(layoutSize.width), rows: Int(layoutSize.height), isSelected: isSelected, aspectRatio: pageLayoutState.aspectRatio)
                        //.frame(width: geometry.size.width / 2)
                        OrientationView(pageLayoutState: pageLayoutState, pageOrientation: orientation, isSelected: isSelected)
                    }
                    .if(isSelected) { view in
                        view.accessibility(addTraits: [.isSelected])
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: orientation))
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
