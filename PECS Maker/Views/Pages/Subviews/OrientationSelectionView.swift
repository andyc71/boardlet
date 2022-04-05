//
//  OrientationSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI

struct OrientationSelectionView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SelectionHeading(text: L10n.OrientationSelectionView.title)
                .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.orientationHeading)

            HStack {
                Spacer()
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
