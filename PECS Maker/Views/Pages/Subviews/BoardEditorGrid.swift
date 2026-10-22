import SwiftUI
import SharedSwiftUI

/// An editable board laid out with native controls. The printed page remains
/// responsible for its own typography and decorations.
struct BoardEditorGrid: View {
    @ObservedObject var pageLayoutState: PageLayoutState
    @Binding var selectedPage: Int
    let selectedPhotoIDs: Set<UUID>
    let isSelectionMode: Bool
    let isLandscape: Bool
    let contextMenuDelegate: any PhotoCellActionDelegate
    let onCellTap: (Int) -> Void
    @AppStorage(PageLayoutMedium.storageKey) private var medium = PageLayoutMedium.preferred()
    @AppStorage(PageLayoutMedium.automaticKey) private var automatic = true
    @AppStorage(PageLayoutMedium.screenLayoutKey) private var screenLayoutData = Data()
    @AppStorage(PageLayoutMedium.screenCardSizeKey) private var screenCardSizeData = Data()
    @State private var viewportSize = CGSize(width: 1, height: 1)
    @State private var visiblePage = 0
    @State private var pendingPage: Int?
    @State private var showsEmptyBoardPrompt = true

    private let spacing: CGFloat = 8
    private let pageSpacing: CGFloat = 8

    private var effectiveLayout: PageLayoutType {
        guard medium == .screen else { return pageLayoutState.pageLayout }
        return automatic ? PageLayoutMedium.automaticLayout(in: viewportSize)
            : PageLayoutMedium.predefinedLayout(data: screenLayoutData, viewport: viewportSize)
    }

    private var columnsCount: Int { max(effectiveLayout.width, 1) }
    private var rowsCount: Int { max(effectiveLayout.height, 1) }
    private var cardsPerPage: Int { columnsCount * rowsCount }
    private var photos: [PhotoItem] { pageLayoutState.photoBrowserData.photoItems }
    private var pageCount: Int { max(1, (photos.count + cardsPerPage - 1) / cardsPerPage) }
    private var validSelectedPage: Int { min(max(selectedPage, 0), pageCount - 1) }

    private var pageSelection: Binding<Int> {
        Binding(get: { validSelectedPage }, set: { selectedPage = $0 })
    }

    private var cardAspectRatio: CGFloat {
        if medium == .screen {
            guard !automatic, let size = PageLayoutMedium.fixedCardSize(data: screenCardSizeData) else { return 1 }
            return size.width / size.height
        }
        let size = pageLayoutState.individualCardMeasurements.sizeInMM
        return size.height > 0 ? size.width / size.height : 1
    }

    private var gridGeometry: ScreenCardGridGeometry {
        .fittingPage(effectiveLayout, in: viewportSize,
                     cardAspectRatio: cardAspectRatio, spacing: spacing)
    }

    var body: some View {
        let geometry = gridGeometry
        let pageSize = geometry.pageSize
        let cardWidth = geometry.cardSize.width
        let cardHeight = geometry.cardSize.height
        let style = BoardRenderStyle(pageLayoutState.topic.formatting)

        Color.clear.overlay {
            if isLandscape {
                horizontalPages(pageSize: pageSize, cardWidth: cardWidth,
                                cardHeight: cardHeight, style: style)
            } else {
                TabView(selection: pageSelection) {
                    ForEach(0..<pageCount, id: \.self) { page in
                        pageView(page, pageSize: pageSize, cardWidth: cardWidth,
                                 cardHeight: cardHeight, style: style,
                                 scrollAxes: pageSize.width > viewportSize.width ? [.horizontal, .vertical] : .vertical,
                                 width: viewportSize.width)
                            .tag(page)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.pageTabs)
            }
        }
        .onGeometryChange(for: CGSize.self) { geometry in
            geometry.size
        } action: {
            viewportSize = $0
            pageLayoutState.screenViewportSize = $0
            if medium == .screen, !automatic,
               PageLayoutMedium.fixedCardSize(data: screenCardSizeData) == nil {
                screenCardSizeData = PageLayoutMedium.cardSizeData(for: effectiveLayout, viewport: $0)
            }
        }
        .onChange(of: pageCount) { count in
            selectedPage = min(max(selectedPage, 0), count - 1)
        }
    }

    private func horizontalPages(pageSize: CGSize, cardWidth: CGFloat,
                                 cardHeight: CGFloat, style: BoardRenderStyle) -> some View {
        // All landscape pages move together when a dense board scrolls vertically.
        let pageWidth = pageSize.width + 16
        let pageStride = pageWidth + pageSpacing
        return ScrollView(.vertical) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: pageSpacing) {
                        ForEach(0..<pageCount, id: \.self) { page in
                            pageContent(page, pageSize: pageSize, cardWidth: cardWidth,
                                        cardHeight: cardHeight, style: style, width: pageWidth)
                                .id(page)
                        }
                    }
                    .frame(minWidth: viewportSize.width)
                    .onGeometryChange(for: CGFloat.self) { geometry in
                        geometry.frame(in: .named("boardEditorPages")).minX
                    } action: { originX in
                        let offset = max(-originX, 0)
                        if let pendingPage {
                            let contentWidth = CGFloat(pageCount) * pageStride - pageSpacing
                            let maxOffset = max(contentWidth - viewportSize.width, 0)
                            let targetOffset = min(CGFloat(pendingPage) * pageStride, maxOffset)
                            if abs(offset - targetOffset) < 2 { self.pendingPage = nil }
                            return
                        }
                        // The viewport can show multiple pages, so track the one at its leading edge.
                        let page = min(Int((offset + pageStride / 2) / pageStride), pageCount - 1)
                        if visiblePage != page {
                            visiblePage = page
                            selectedPage = page
                        }
                    }
                }
                .frame(height: max(viewportSize.height, pageSize.height + 40))
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                .coordinateSpace(name: "boardEditorPages")
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.pageScroll)
                .onAppear {
                    visiblePage = validSelectedPage
                    pendingPage = validSelectedPage
                    proxy.scrollTo(validSelectedPage, anchor: .leading)
                }
                .onChange(of: selectedPage) { page in
                    guard visiblePage != page else { return }
                    visiblePage = page
                    pendingPage = page
                    withAnimation { proxy.scrollTo(page, anchor: .leading) }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.collectionView)
        .accessibilityValue("\(photos.count)")
        .overlay {
            if photos.isEmpty && showsEmptyBoardPrompt {
                EmptyBoardView(pageLayoutState: pageLayoutState) {
                    showsEmptyBoardPrompt = false
                }
            }
        }
    }

    private func pageView(_ page: Int, pageSize: CGSize, cardWidth: CGFloat,
                          cardHeight: CGFloat, style: BoardRenderStyle,
                          scrollAxes: Axis.Set, width: CGFloat) -> some View {
        ScrollView(scrollAxes) {
            pageContent(page, pageSize: pageSize, cardWidth: cardWidth,
                        cardHeight: cardHeight, style: style, width: width)
        }
        .frame(width: width)
        .scrollBounceBehavior(.basedOnSize, axes: scrollAxes)
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.collectionView)
        .accessibilityValue("\(photos.count)")
        .overlay {
            if photos.isEmpty && showsEmptyBoardPrompt {
                EmptyBoardView(pageLayoutState: pageLayoutState) {
                    showsEmptyBoardPrompt = false
                }
            }
        }
    }

    private func pageContent(_ page: Int, pageSize: CGSize, cardWidth: CGFloat,
                             cardHeight: CGFloat, style: BoardRenderStyle,
                             width: CGFloat) -> some View {
        let geometry = gridGeometry
        return ScreenCardGrid(geometry: geometry) { slot in
            let index = page * cardsPerPage + slot
            let photo = photo(at: index)
            let visiblePhoto = photo?.isPlaceholder == true ? nil : photo
            cellWithContextMenu(Button {
                onCellTap(pageLayoutState.repeatSinglePhoto && photos.count == 1 ? 0 : index)
            } label: {
                BoardEditorGridCard(photo: visiblePhoto, size: CGSize(width: cardWidth, height: cardHeight),
                                    style: style,
                                    isSelected: visiblePhoto.map { selectedPhotoIDs.contains($0.itemID) } ?? false)
            }
            .buttonStyle(.plain)
            .disabled(isSelectionMode && visiblePhoto == nil)
            .accessibilityLabel(L10n.PreviewPage.cardPosition(page + 1, slot + 1,
                accessibilityTitle(for: visiblePhoto)))
            .accessibilityHint(visiblePhoto == nil ? L10n.PreviewPage.addCardHint : L10n.PreviewPage.editCardHint)
            .accessibilityAddTraits(visiblePhoto.map { selectedPhotoIDs.contains($0.itemID) } == true ? .isSelected : [])
            .accessibilityIdentifier(visiblePhoto == nil
                ? AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: index)
                : AccessibilityIdentifiers.PhotoSelectionView.image(for: index))
            .draggable(visiblePhoto?.itemID.uuidString ?? "")
            .dropDestination(for: String.self) { items, _ in
                guard let value = items.first, let id = UUID(uuidString: value) else { return false }
                return move(id: id, to: index)
            }
            .accessibilityAction(named: Text(L10n.BoardEditor.moveEarlier)) {
                move(photo: visiblePhoto, to: index - 1)
            }
            .accessibilityAction(named: Text(L10n.BoardEditor.moveLater)) {
                move(photo: visiblePhoto, to: index + 1)
            }, photo: visiblePhoto)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.page(for: page))
        .accessibilityValue(L10n.MainMenu.layoutStatus(columnsCount, rowsCount))
        .padding(.horizontal, 8)
        .padding(.vertical, 20)
        .frame(minWidth: width, minHeight: viewportSize.height)
    }

    @ViewBuilder
    private func cellWithContextMenu<Content: View>(_ content: Content, photo: PhotoItem?) -> some View {
        if let photo, !isSelectionMode {
            content.photoCellContextMenu(for: photo, delegate: contextMenuDelegate,
                                         includesRename: false)
        } else {
            content
        }
    }

    private func photo(at index: Int) -> PhotoItem? {
        if pageLayoutState.repeatSinglePhoto && photos.count == 1 { return photos[0] }
        return photos.indices.contains(index) ? photos[index] : nil
    }

    private func accessibilityTitle(for photo: PhotoItem?) -> String {
        guard let photo else { return L10n.PhotoSelectionView.emptyCard }
        return photo.title.flatMap { $0.isEmpty ? nil : $0 } ?? L10n.PhotoSelectionView.untitledCell
    }

    private func move(photo: PhotoItem?, to index: Int) {
        guard let photo else { return }
        _ = move(id: photo.itemID, to: index)
    }

    private func move(id: UUID, to index: Int) -> Bool {
        var ordered = photos
        guard let source = ordered.firstIndex(where: { $0.itemID == id }),
              ordered.indices.contains(index), source != index else { return false }
        ordered.insert(ordered.remove(at: source), at: index)
        pageLayoutState.photoBrowserData.photoItems = ordered
        selectedPage = index / cardsPerPage
        return true
    }
}

private struct BoardEditorGridCard: View {
    let photo: PhotoItem?
    let size: CGSize
    let style: BoardRenderStyle
    let isSelected: Bool
    @ScaledMetric(relativeTo: .body) private var titleScale: CGFloat = 1

    private var title: String? {
        guard let title = photo?.title, !title.isEmpty else { return nil }
        return title
    }

    var body: some View {
        ImageTitleCard(
            image: photo.map { $0.image },
            title: title,
            isTextOnly: photo?.hasPhoto == false && title != nil,
            isEmpty: photo == nil,
            squareImage: false,
            size: size,
            fillColor: style.cellFillColor,
            titleColor: style.cardTitleFontColor,
            titleFont: .system(size: min(max(size.width * 0.14, 11), 18) * titleScale,
                               weight: style.cardTitleFontBold ? .bold : .regular),
            titlePosition: style.cardTitlePosition,
            titleLineLimit: size.height >= 72 ? 2 : 1,
            isSelected: isSelected
        )
    }
}
