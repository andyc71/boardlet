//
//  PageSizeAndLayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct PageSizeAndLayoutView: View {
    @ObservedObject var pageLayoutState: PageLayoutState
    @ObservedObject private var formattingOptions: CollageFormatting
    @AppStorage(PageLayoutMedium.storageKey) private var medium = PageLayoutMedium.preferred()
    @AppStorage(PageLayoutMedium.automaticKey) private var automatic = true
    @AppStorage(PageLayoutMedium.screenLayoutKey) private var screenLayoutData = Data()
    @AppStorage(PageLayoutMedium.screenCardSizeKey) private var screenCardSizeData = Data()
    let dismissAction: () -> Void

    @EnvironmentObject private var navigationModel: NavigationModel
    var onSeeAll: (() -> Void)?

    init(pageLayoutState: PageLayoutState, onSeeAll: (() -> Void)? = nil, dismissAction: @escaping () -> Void) {
        self.onSeeAll = onSeeAll
        self.pageLayoutState = pageLayoutState
        self.formattingOptions = pageLayoutState.topic.formatting
        self.dismissAction = dismissAction
    }

    private func preservePredefinedScreenLayout() {
        guard medium == .screen, !automatic else { return }
        let layout = PageLayoutMedium.predefinedLayout(data: screenLayoutData,
                                                       viewport: pageLayoutState.screenViewportSize)
        if PageLayoutMedium.fixedCardSize(data: screenCardSizeData) == nil {
            screenCardSizeData = PageLayoutMedium.cardSizeData(for: layout, viewport: pageLayoutState.screenViewportSize)
        }
        if let data = try? JSONEncoder().encode(layout), data != screenLayoutData {
            screenLayoutData = data
        }
    }

    var body: some View {
        LayoutSettingsView(medium: $medium, automatic: $automatic, onSizeChange: { size in
            let viewport = pageLayoutState.screenViewportSize
            if viewport == .zero || (viewport.width > viewport.height) != (size.width > size.height) {
                pageLayoutState.screenViewportSize = size
            }
        }) {
            PageSizeSelectionView(selectedPageSize: $pageLayoutState.pageSize)
            OrientationSelectionView(pageLayoutState: pageLayoutState)
            Toggle(L10n.LayoutScreen.showTitles, isOn: $formattingOptions.pageTitleVisible)
                .toggleStyle(BoardTitleCheckboxStyle())
                .accessibilityIdentifier("LayoutScreen.showTitles")
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 10))
        } designs: { isLandscape in
            LayoutSelectionView(pageLayoutState: pageLayoutState, usesAdaptiveColumns: isLandscape) {
                if let onSeeAll { onSeeAll() }
                else { navigationModel.push(.allLayouts) }
            }
        } summary: {
            LayoutSelectionSummary(pageSize: pageLayoutState.pageSize.localizedString,
                                   orientation: pageLayoutState.orientation.localizedString,
                                   cellCount: pageLayoutState.pageLayout.localizedCellCount)
        }
        // The highlighted default is a fixed choice once Pre-Defined is enabled.
        .onAppear(perform: preservePredefinedScreenLayout)
        .onChange(of: automatic) { _ in preservePredefinedScreenLayout() }
        .onChange(of: medium) { _ in preservePredefinedScreenLayout() }
        .onDisappear {
            formattingOptions.saveToUserDefaults()
            guard navigationModel.path.last != .allLayouts else { return }
            dismissAction()
        }
    }
}

/// The same layout screen serves board pages and the screen-only topic grid.
struct LayoutSettingsView<PaperOptions: View, Designs: View, Summary: View>: View {
    @Binding var medium: PageLayoutMedium
    @Binding var automatic: Bool
    var allowsPaper = true
    var onSizeChange: (CGSize) -> Void = { _ in }
    @ViewBuilder var paperOptions: () -> PaperOptions
    @ViewBuilder var designs: (Bool) -> Designs
    @ViewBuilder var summary: () -> Summary
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var currentTheme: SharedUITheme
    @State private var containerSize = CGSize.zero

    var body: some View {
        let isLandscape = containerSize.width > containerSize.height
        let columnWidth = max(0, containerSize.width - 38)
        let layout = isLandscape
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 22))
            : AnyLayout(VStackLayout(spacing: 22))
        Color.clear
            .onGeometryChange(for: CGSize.self) { $0.size } action: {
                containerSize = $0
                onSizeChange($0)
            }
            .overlay {
                ScrollView {
                    VStack(spacing: 22) {
                        layout {
                            VStack(alignment: .leading, spacing: 22) {
                                if allowsPaper && InterfaceStyle.canChange {
                                    Picker(L10n.LayoutScreen.medium, selection: $medium) {
                                        Text(L10n.LayoutScreen.paper).tag(PageLayoutMedium.paper)
                                        Text(L10n.LayoutScreen.screen).tag(PageLayoutMedium.screen)
                                    }
                                    .pickerStyle(.menu)
                                    .font(.headline)
                                    .accessibilityIdentifier("LayoutScreen.medium")
                                } else if !allowsPaper {
                                    Text(L10n.LayoutScreen.screen)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                }
                                if allowsPaper && medium == .paper {
                                    paperOptions()
                                } else {
                                    Picker(L10n.LayoutScreen.screenLayout, selection: $automatic) {
                                        Text(L10n.LayoutScreen.automatic).tag(true)
                                        Text(L10n.LayoutScreen.preDefined).tag(false)
                                    }
                                    .pickerStyle(.segmented)
                                    .accessibilityIdentifier("LayoutScreen.screenLayout")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(width: isLandscape ? columnWidth * 0.4 : nil)
                            if (allowsPaper && medium == .paper) || !automatic {
                                designs(isLandscape)
                                    .frame(maxWidth: .infinity)
                                    .frame(width: isLandscape ? columnWidth * 0.6 : nil)
                            }
                        }
                        if allowsPaper && medium == .paper { summary() }
                    }
                    .frame(maxWidth: isLandscape ? .infinity : 640)
                    .padding(.horizontal, 16)
                    .padding(.top, isLandscape && verticalSizeClass == .compact ? 0 : 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(L10n.LayoutScreen.title)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(currentTheme.backgroundColor).ignoresSafeArea())
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
