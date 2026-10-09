//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct LayoutSelectionView: View {
    @ObservedObject var pageLayoutState: PageLayoutState
    let onSeeAll: () -> Void

    var body: some View {
        FeaturedLayoutChoiceSection(
            layouts: pageLayoutState.featuredLayoutChoices,
            selectedLayout: pageLayoutState.pageLayout,
            aspectRatio: pageLayoutState.aspectRatio,
            onSeeAll: onSeeAll
        ) { pageLayoutState.pageLayout = $0 }
    }
}

struct AllLayoutsView: View {
    @EnvironmentObject private var currentTheme: SharedUITheme
    @ObservedObject var pageLayoutState: PageLayoutState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(pageLayoutState.layoutSections) { section in
                    LayoutChoiceSection(
                        kind: section.kind,
                        layouts: section.layouts,
                        selectedLayout: pageLayoutState.pageLayout,
                        aspectRatio: pageLayoutState.aspectRatio
                    ) { pageLayoutState.pageLayout = $0 }
                }
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(L10n.LayoutScreen.layouts)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
    }
}

private extension PageLayoutSectionKind {
    var title: String {
        switch self {
        case .recommended: return L10n.LayoutScreen.recommendedLayouts
        case .singleRow: return L10n.LayoutScreen.singleRow
        case .allSizes: return L10n.LayoutScreen.allSizes
        }
    }
}

private struct FeaturedLayoutChoiceSection: View {
    let layouts: [PageLayoutChoice]
    let selectedLayout: PageLayoutType
    let aspectRatio: CGFloat
    let onSeeAll: () -> Void
    let onSelect: (PageLayoutType) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .accessibilityHidden(true)

                        Text(L10n.LayoutScreen.layouts)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.layoutHeading)
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 12)

                Button(action: onSeeAll) {
                    Text(L10n.LayoutScreen.seeAll)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.mfVeryBrightBlue)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.seeAllButton)
            }
            .padding(.horizontal, 12)

            if isExpanded {
                LayoutChoiceGrid(
                    layouts: layouts,
                    selectedLayout: selectedLayout,
                    aspectRatio: aspectRatio,
                    onSelect: onSelect
                )
                .padding(12)
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LayoutChoiceSection: View {
    let kind: PageLayoutSectionKind
    let layouts: [PageLayoutChoice]
    let selectedLayout: PageLayoutType
    let aspectRatio: CGFloat
    let onSelect: (PageLayoutType) -> Void

    @State private var isExpanded: Bool

    init(
        kind: PageLayoutSectionKind,
        layouts: [PageLayoutChoice],
        selectedLayout: PageLayoutType,
        aspectRatio: CGFloat,
        onSelect: @escaping (PageLayoutType) -> Void
    ) {
        self.kind = kind
        self.layouts = layouts
        self.selectedLayout = selectedLayout
        self.aspectRatio = aspectRatio
        self.onSelect = onSelect
        _isExpanded = State(initialValue: true)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            LayoutChoiceGrid(
                layouts: layouts,
                selectedLayout: selectedLayout,
                aspectRatio: aspectRatio,
                onSelect: onSelect
            )
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.top, 8)
        } label: {
            Text(kind.title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .if(kind == .recommended) { view in
                    view.accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.layoutHeading)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LayoutChoiceGrid: View {
    let layouts: [PageLayoutChoice]
    let selectedLayout: PageLayoutType
    let aspectRatio: CGFloat
    let onSelect: (PageLayoutType) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(layouts) { choice in
                let layout = choice.layout
                let isSelected = layout == selectedLayout

                Button {
                    onSelect(layout)
                } label: {
                    LayoutView(
                        layout: layout,
                        aspectRatio: aspectRatio,
                        cardSize: choice.cardSize,
                        isSelected: isSelected
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.LayoutScreen.layoutButton(for: layout))
                .if(isSelected) { view in
                    view.accessibility(addTraits: .isSelected)
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
