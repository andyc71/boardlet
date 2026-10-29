import SwiftUI

/// Fits the printable page to an independently measured viewport, including after rotation.
struct ClassicCollageView: View {
    @Environment(\.displayScale) private var displayScale
    @ObservedObject var pageLayoutState: PageLayoutState
    @State private var viewportSize: CGSize = .zero
    @State private var selectedPage = 0

    private var pageCount: Int {
        let photos = pageLayoutState.photoBrowserData.photoItems.count
        return max(1, Int(ceil(Double(photos) / Double(max(1, pageLayoutState.pageLayout.total)))))
    }

    var body: some View {
        // The overlay cannot change the viewport's proposal. In particular, a fitted
        // landscape page must never become the maximum height of the portrait view.
        Color.clear
            .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
            .overlay {
                if viewportSize.width > 0 && viewportSize.height > 0 {
                    let indicatorHeight: CGFloat = pageCount > 1 ? 28 : 0
                    let pageSpace = CGSize(width: viewportSize.width,
                                           height: max(1, viewportSize.height - indicatorHeight))
                    let pageSize = pageLayoutState.calculateCollageSizeForScreen3(availableSpace: pageSpace)
                    let collage = pageLayoutState.createCollageForScreen(maxWidth: (pageSize.width * displayScale).rounded(.up))

                    TabView(selection: $selectedPage) {
                        ForEach(collage) { item in
                            VStack(spacing: 0) {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: pageSize.width, height: pageSize.height)
                                    .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                                    .accessibilityLabel(L10n.PreviewPage.pageStatus(item.index + 1, pageCount))
                                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.previewImage(for: item.index))
                                if indicatorHeight > 0 {
                                    Color.clear.frame(height: indicatorHeight)
                                }
                            }
                            .tag(item.index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: pageCount > 1 ? .always : .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .frame(width: pageSize.width, height: pageSize.height + indicatorHeight)
                }
            }
            .onChange(of: pageCount) { count in
                selectedPage = min(selectedPage, count - 1)
            }
    }
}
