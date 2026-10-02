//
//  PageSizeAndLayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import PhotosUI
import LogFramework
import SharedSwiftUI

struct PageSizeAndLayoutView: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @ObservedObject var pageLayoutState: PageLayoutState

    //@State var isVertical: Bool
    
    //@State private var orientation = UIDeviceOrientation.unknown
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AdaptiveStack(isVertical: horizontalSizeClass == .compact,
                              verticalAlignment: .top, spacing: 20) {
                    PageSizeSelectionView(selectedPageSize: $pageLayoutState.pageSize)
                    OrientationSelectionView(pageLayoutState: pageLayoutState)
                }

                LayoutSelectionView(pageLayoutState: pageLayoutState)
                LayoutSummaryView(pageLayoutState: pageLayoutState)
            }
        }
        .navigationBarTitle(L10n.LayoutScreen.title, displayMode: .inline)
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear { dismissAction() }
    }
}

struct LayoutSectionCard<Content: View>: View {
    let title: String
    let titleAccId: String?
    let content: () -> Content

    init(title: String, titleAccId: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.titleAccId = titleAccId
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .if(titleAccId != nil) { view in
                    view.accessibilityIdentifier(titleAccId!)
                }

            VStack(alignment: .leading) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 10))
        }
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
