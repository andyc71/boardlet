//
//  PageSizeSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct PageSizeSelectionView: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @Binding var selectedPageSize: PageSize
    
    var body: some View {
        SimpleCard(title: L10n.PageSizeSelectionView.title, titleAccId:
                    AccessibilityIdentifiers.LayoutScreen.pageSizeHeading) {
            
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
                        view.background(currentTheme.selectionHighlightColor)
                            .accessibility(addTraits: [.isSelected])
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.pageSizeButton(for: pageSize))
                    
                }
            }
        }
    }
}

struct PageSizeSelectionView_Previews: PreviewProvider {
    
    @State static var selectedPageSize = PageSize.a4
    
    static var previews: some View {
        PageSizeSelectionView(selectedPageSize: $selectedPageSize)
    }
}
