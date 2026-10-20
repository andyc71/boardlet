//
//  PageSizeAndLayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct PageSizeAndLayoutView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var currentTheme: SharedUITheme
    @ObservedObject var pageLayoutState: PageLayoutState
    @ObservedObject private var formattingOptions: CollageFormatting
    @State private var containerSize: CGSize = .zero
    let dismissAction: () -> Void

    @EnvironmentObject private var navigationModel: NavigationModel
    var onSeeAll: (() -> Void)?

    init(pageLayoutState: PageLayoutState, onSeeAll: (() -> Void)? = nil, dismissAction: @escaping () -> Void) {
        self.onSeeAll = onSeeAll
        self.pageLayoutState = pageLayoutState
        self.formattingOptions = pageLayoutState.topic.formatting
        self.dismissAction = dismissAction
    }

    var body: some View {
        let isLandscape = containerSize.width > containerSize.height
        let columnWidth = max(0, containerSize.width - 16 - 22)
        let layout = isLandscape
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 22))
            : AnyLayout(VStackLayout(spacing: 22))

        Color.clear
            .onGeometryChange(for: CGSize.self) { geometry in
                geometry.size
            } action: { size in
                containerSize = size
            }
            .overlay {
                ScrollView {
                    VStack(spacing: 22) {
                        layout {
                            VStack(spacing: 22) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L10n.LayoutScreen.paperSettings)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                    PageSizeSelectionView(selectedPageSize: $pageLayoutState.pageSize)
                                }
                                OrientationSelectionView(pageLayoutState: pageLayoutState)
                                Toggle(L10n.LayoutScreen.showTitles,
                                       isOn: $formattingOptions.pageTitleVisible)
                                    .toggleStyle(BoardTitleCheckboxStyle())
                                    .accessibilityIdentifier("LayoutScreen.showTitles")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground),
                                                in: RoundedRectangle(cornerRadius: 10))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(width: isLandscape ? columnWidth * 0.4 : nil)

                            LayoutSelectionView(
                                pageLayoutState: pageLayoutState,
                                usesAdaptiveColumns: isLandscape,
                                onSeeAll: {
                                    if let onSeeAll { onSeeAll() }
                                    else { navigationModel.push(.allLayouts) }
                                }
                            )
                            .frame(maxWidth: .infinity)
                            .frame(width: isLandscape ? columnWidth * 0.6 : nil)
                        }
                        LayoutSelectionSummary(
                            pageSize: pageLayoutState.pageSize.localizedString,
                            orientation: pageLayoutState.orientation.localizedString,
                            cellCount: pageLayoutState.pageLayout.localizedCellCount
                        )
                    }
                    .frame(maxWidth: isLandscape ? .infinity : 640)
                    .padding(.leading, 16)
                    .padding(.trailing, isLandscape ? 0 : 16)
                    .padding(.top, isLandscape && verticalSizeClass == .compact ? 0 : 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                }
            }
        .navigationBarTitle(L10n.LayoutScreen.title, displayMode: .inline)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear {
            formattingOptions.saveToUserDefaults()
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
