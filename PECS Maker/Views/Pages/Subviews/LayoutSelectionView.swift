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
    @AppStorage(PageLayoutMedium.storageKey) private var medium = PageLayoutMedium.preferred()
    @AppStorage(PageLayoutMedium.screenLayoutKey) private var screenLayoutData = Data()
    @AppStorage(PageLayoutMedium.screenCardSizeKey) private var screenCardSizeData = Data()

    private var screenLayout: PageLayoutType? {
        PageLayoutMedium.predefinedLayout(data: screenLayoutData, viewport: pageLayoutState.screenViewportSize)
    }

    private var sections: [PageLayoutSection] {
        medium == .paper ? pageLayoutState.layoutSections
            : PageLayoutSection.forScreen(in: pageLayoutState.screenViewportSize)
    }

    private var previewAspectRatio: CGFloat {
        medium == .paper ? pageLayoutState.aspectRatio
            : pageLayoutState.screenViewportSize.width / max(1, pageLayoutState.screenViewportSize.height)
    }

    private func select(_ layout: PageLayoutType) {
        if medium == .paper { pageLayoutState.pageLayout = layout }
        else if let data = try? JSONEncoder().encode(layout) {
            screenCardSizeData = PageLayoutMedium.cardSizeData(for: layout, viewport: pageLayoutState.screenViewportSize)
            screenLayoutData = data
        }
    }
    var usesAdaptiveColumns = false
    let onSeeAll: () -> Void

    private var screenChoices: [PageLayoutChoice] {
        let recommended = sections.first?.layouts ?? []
        guard let screenLayout, !recommended.contains(where: { $0.layout == screenLayout }),
              let choice = sections.flatMap(\.layouts).first(where: { $0.layout == screenLayout }) else {
            return recommended
        }
        return recommended + [PageLayoutChoice(layout: choice.layout, cardSize: choice.cardSize, preset: nil)]
    }

    var body: some View {
        FeaturedLayoutChoiceSection(
            layouts: medium == .paper ? pageLayoutState.featuredLayoutChoices : screenChoices,
            selectedLayout: medium == .paper ? pageLayoutState.pageLayout : screenLayout,
            aspectRatio: previewAspectRatio,
            title: medium == .paper && pageLayoutState.topic.formatting.pageTitleVisible ? pageLayoutState.title : nil,
            titleHeightFraction: pageLayoutState.topic.formatting.pageTitleHeightPercentage,
            showsMeasurements: medium == .paper,
            usesAdaptiveColumns: usesAdaptiveColumns,
            onSeeAll: onSeeAll
        ) { select($0) }
    }
}

struct AllLayoutsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentTheme: SharedUITheme
    @ObservedObject var pageLayoutState: PageLayoutState
    @AppStorage(PageLayoutMedium.storageKey) private var medium = PageLayoutMedium.preferred()
    @AppStorage(PageLayoutMedium.screenLayoutKey) private var screenLayoutData = Data()
    @AppStorage(PageLayoutMedium.screenCardSizeKey) private var screenCardSizeData = Data()

    private var screenLayout: PageLayoutType? {
        PageLayoutMedium.predefinedLayout(data: screenLayoutData, viewport: pageLayoutState.screenViewportSize)
    }

    private var sections: [PageLayoutSection] {
        medium == .paper ? pageLayoutState.layoutSections
            : PageLayoutSection.forScreen(in: pageLayoutState.screenViewportSize)
    }

    private var previewAspectRatio: CGFloat {
        medium == .paper ? pageLayoutState.aspectRatio
            : pageLayoutState.screenViewportSize.width / max(1, pageLayoutState.screenViewportSize.height)
    }

    private func select(_ layout: PageLayoutType) {
        if medium == .paper { pageLayoutState.pageLayout = layout }
        else if let data = try? JSONEncoder().encode(layout) {
            screenCardSizeData = PageLayoutMedium.cardSizeData(for: layout, viewport: pageLayoutState.screenViewportSize)
            screenLayoutData = data
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(sections) { section in
                    LayoutChoiceSection(
                        kind: section.kind,
                        layouts: section.layouts,
                        selectedLayout: medium == .paper ? pageLayoutState.pageLayout : screenLayout,
                        aspectRatio: previewAspectRatio,
                        title: medium == .paper && pageLayoutState.topic.formatting.pageTitleVisible ? pageLayoutState.title : nil,
                        titleHeightFraction: pageLayoutState.topic.formatting.pageTitleHeightPercentage,
                        showsMeasurements: medium == .paper
                    ) { layout in
                        select(layout)
                        dismiss()
                    }
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

struct FeaturedLayoutChoiceSection: View {
    let layouts: [PageLayoutChoice]
    let selectedLayout: PageLayoutType?
    let aspectRatio: CGFloat
    let title: String?
    let titleHeightFraction: CGFloat
    var showsMeasurements = true
    let usesAdaptiveColumns: Bool
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

                        Text(L10n.LayoutScreen.recommendedDesigns)
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
                    title: title,
                    titleHeightFraction: titleHeightFraction,
                    showsMeasurements: showsMeasurements,
                    usesAdaptiveColumns: usesAdaptiveColumns,
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

struct LayoutChoiceSection: View {
    let kind: PageLayoutSectionKind
    let layouts: [PageLayoutChoice]
    let selectedLayout: PageLayoutType?
    let aspectRatio: CGFloat
    let title: String?
    let titleHeightFraction: CGFloat
    let showsMeasurements: Bool
    let onSelect: (PageLayoutType) -> Void

    @State private var isExpanded: Bool

    init(
        kind: PageLayoutSectionKind,
        layouts: [PageLayoutChoice],
        selectedLayout: PageLayoutType?,
        aspectRatio: CGFloat,
        title: String?,
        titleHeightFraction: CGFloat,
        showsMeasurements: Bool = true,
        onSelect: @escaping (PageLayoutType) -> Void
    ) {
        self.showsMeasurements = showsMeasurements
        self.kind = kind
        self.layouts = layouts
        self.selectedLayout = selectedLayout
        self.aspectRatio = aspectRatio
        self.title = title
        self.titleHeightFraction = titleHeightFraction
        self.onSelect = onSelect
        _isExpanded = State(initialValue: true)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            LayoutChoiceGrid(
                layouts: layouts,
                selectedLayout: selectedLayout,
                aspectRatio: aspectRatio,
                title: title,
                titleHeightFraction: titleHeightFraction,
                showsMeasurements: showsMeasurements,
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
    let selectedLayout: PageLayoutType?
    let aspectRatio: CGFloat
    let title: String?
    let titleHeightFraction: CGFloat
    var showsMeasurements = true
    var usesAdaptiveColumns = false
    let onSelect: (PageLayoutType) -> Void

    @ScaledMetric(relativeTo: .subheadline) private var minimumColumnWidth = 104

    private var columns: [GridItem] {
        usesAdaptiveColumns
            ? [GridItem(.adaptive(minimum: minimumColumnWidth), spacing: 8)]
            : Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }

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
                        cardSize: showsMeasurements ? choice.cardSize : nil,
                        isSelected: isSelected,
                        title: title,
                        titleHeightFraction: titleHeightFraction
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
