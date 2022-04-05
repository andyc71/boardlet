//
//  PageSizeSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI

struct PageSizeSelectionView: View {
    
    @Binding var selectedPageSize: PageSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SelectionHeading(text: L10n.PageSizeSelectionView.title)
                .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.pageSizeHeading)

            VStack(alignment: .leading) {
                ForEach(PageSize.allCases) { pageSize in
                    Button(action: {
                        self.selectedPageSize = pageSize
                    }) {
                        Text(pageSize.rawValue)
                    }
                    .padding(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .if(pageSize==self.selectedPageSize) { view in
                        //view.padding(5)
                        view.background(Theme.selectionHighlightColor)
                            .accessibility(addTraits: [.isSelected])
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.pageSizeButton(for: pageSize))
                    
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(ColorNames.lightBlue))
            //.cornerRadius(<#T##radius: CGFloat##CGFloat#>)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            
            
        }
        //.border(Color(UIColor.secondaryLabel), width: 1)
    }
}

struct PageSizeSelectionView_Previews: PreviewProvider {

    @State static var selectedPageSize = PageSize.a4

    static var previews: some View {
        PageSizeSelectionView(selectedPageSize: $selectedPageSize)
    }
}
