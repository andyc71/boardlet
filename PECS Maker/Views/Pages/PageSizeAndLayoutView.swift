//
//  PageSizeAndLayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct PageSizeAndLayoutView: View {
    @EnvironmentObject private var currentTheme: SharedUITheme
    @ObservedObject var pageLayoutState: PageLayoutState
    let dismissAction: () -> Void

    @EnvironmentObject private var navigationModel: NavigationModel
    var onSeeAll: (() -> Void)?

    init(pageLayoutState: PageLayoutState, onSeeAll: (() -> Void)? = nil, dismissAction: @escaping () -> Void) {
        self.onSeeAll = onSeeAll
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                PageSizeSelectionView(selectedPageSize: $pageLayoutState.pageSize)
                OrientationSelectionView(pageLayoutState: pageLayoutState)
                LayoutSelectionView(
                    pageLayoutState: pageLayoutState,
                    onSeeAll: {
                        if let onSeeAll { onSeeAll() }
                        else { navigationModel.push(.allLayouts) }
                    }
                )
                LayoutSelectionSummary(
                    pageSize: pageLayoutState.pageSize.localizedString,
                    orientation: pageLayoutState.orientation.localizedString,
                    cellCount: pageLayoutState.pageLayout.localizedCellCount
                )
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitle(L10n.LayoutScreen.title, displayMode: .inline)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear {
            guard navigationModel.path.last != .allLayouts else { return }
            dismissAction()
        }
    }
}

private struct LayoutSelectionSummary: View {
    let pageSize: String
    let orientation: String
    let cellCount: String

    var body: some View {
        Text(L10n.LayoutScreen.summary(pageSize, orientation, cellCount))
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.mfVeryBrightBlue)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.summary)
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
