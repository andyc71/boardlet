import SwiftUI
import SharedSwiftUI

struct TopicLayoutSelectionView: View {
    @Binding var layoutData: Data
    @Binding var recommendationID: String
    @Binding var customCardWidth: Double
    @Binding var customCardAspectRatio: Double
    let viewportSize: CGSize
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentTheme: SharedUITheme
    @State private var showsAllLayouts = false
    @State private var automatic: Bool

    init(layoutData: Binding<Data>, recommendationID: Binding<String>,
         customCardWidth: Binding<Double>, customCardAspectRatio: Binding<Double>, viewportSize: CGSize) {
        _layoutData = layoutData
        _recommendationID = recommendationID
        _customCardWidth = customCardWidth
        _customCardAspectRatio = customCardAspectRatio
        self.viewportSize = viewportSize
        _automatic = State(initialValue: layoutData.wrappedValue.isEmpty && recommendationID.wrappedValue.isEmpty)
    }

    private var sections: [PageLayoutSection] {
        PageLayoutSection.forScreen(in: viewportSize, horizontalInset: 20, verticalInset: 20, spacing: 12, minimumCardWidth: 80)
    }

    private var selectedLayout: PageLayoutType? {
        try? JSONDecoder().decode(PageLayoutType.self, from: layoutData)
    }

    private var featuredChoices: [PageLayoutChoice] {
        let recommended = sections.first?.layouts ?? []
        guard let selectedLayout, !recommended.contains(where: { $0.layout == selectedLayout }),
              let choice = sections.flatMap(\.layouts).first(where: { $0.layout == selectedLayout }) else {
            return recommended
        }
        return recommended + [PageLayoutChoice(layout: choice.layout, cardSize: choice.cardSize, preset: nil)]
    }

    private func select(_ layout: PageLayoutType) {
        guard let data = try? JSONEncoder().encode(layout),
              sections.flatMap(\.layouts).contains(where: { $0.layout == layout }) else { return }
        let geometry = ScreenCardGridGeometry.screenPreset(layout, in: viewportSize,
                                                            spacing: 12, horizontalInset: 20)
        layoutData = data
        recommendationID = ""
        customCardWidth = geometry.cardSize.width
        customCardAspectRatio = geometry.cardSize.width / geometry.cardSize.height
    }

    var body: some View {
        LayoutSettingsView(medium: .constant(.screen), automatic: $automatic, allowsPaper: false, header: {
            Text(L10n.LayoutScreen.screen)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
        }) {
            EmptyView()
        } designs: { isLandscape in
            FeaturedLayoutChoiceSection(
                layouts: featuredChoices,
                selectedLayout: selectedLayout,
                aspectRatio: viewportSize.width / max(1, viewportSize.height),
                title: nil,
                titleHeightFraction: 0,
                showsMeasurements: false,
                usesAdaptiveColumns: isLandscape,
                onSeeAll: { showsAllLayouts = true },
                onSelect: select
            )
        } summary: {
            EmptyView()
        }
        .onChange(of: automatic) { automatic in
            if automatic {
                layoutData = Data()
                recommendationID = ""
            } else if selectedLayout == nil,
                      let layout = sections.first?.layouts.first(where: { $0.preset == .medium })?.layout {
                select(layout)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.LayoutScreen.doneButton) { dismiss() }
                    .accessibilityIdentifier("TopicLayout.done")
            }
        }
        .navigationDestination(isPresented: $showsAllLayouts) {
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(sections) { section in
                        LayoutChoiceSection(kind: section.kind, layouts: section.layouts,
                                            selectedLayout: selectedLayout,
                                            aspectRatio: viewportSize.width / max(1, viewportSize.height),
                                            title: nil, titleHeightFraction: 0, showsMeasurements: false) { layout in
                            select(layout)
                            showsAllLayouts = false
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Color(currentTheme.backgroundColor).ignoresSafeArea())
            .navigationTitle(L10n.LayoutScreen.layouts)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
