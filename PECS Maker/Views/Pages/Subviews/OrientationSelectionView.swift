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
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.OrientationSelectionView.title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.orientationHeading)

            HStack(spacing: 8) {
                ForEach(PageOrientation.allCases, id: \.self) { orientation in
                    let isSelected = orientation == pageLayoutState.orientation

                    Button {
                        pageLayoutState.orientation = orientation
                    } label: {
                        OrientationView(
                            pageSize: pageLayoutState.pageSize,
                            pageOrientation: orientation,
                            isSelected: isSelected
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.orientationButton(for: orientation))
                    .if(isSelected) { view in
                        view.accessibility(addTraits: .isSelected)
                    }
                }
            }
        }
    }
}

extension PageOrientation {
    var localizedString: String {
        switch self {
        case .portrait:
            L10n.LayoutScreen.portrait
        case .landscape:
            L10n.LayoutScreen.landscape
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
