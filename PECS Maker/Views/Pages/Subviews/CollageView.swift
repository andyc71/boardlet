import SwiftUI

/// Interactive page composition. View updates consume prepared images; they never
/// rasterize a page. The model survives navigation to the focused card editor.
struct CollageView<CompactActions: View>: View {
    @ObservedObject var pageLayoutState: PageLayoutState
    @Binding var selectedPage: Int
    var selectedPhotoIDs: Set<UUID> = []
    var isSelectionMode = false
    var usesBoardIdentifiers = false
    var compactControls = false
    var showsNoPhotosOverlay = false
    var pageControlsVerticalPadding: CGFloat = 0
    @Binding var zoom: CGFloat
    var transitionNamespace: Namespace.ID?
    var onTransitionSourceSelected: ((String) -> Void)?
    var compactActions: CompactActions
    var onCellTap: (Int) -> Void
    @Environment(\.displayScale) private var displayScale
    @StateObject private var renderer = BoardPageRenderModel()
    @GestureState private var pinchMagnification: CGFloat = 1

    var body: some View {
        let geometry = BoardPageGeometry(pageSize: pageLayoutState.pageMeasurements2.convertToPDFMeasurements(),
            layout: pageLayoutState.pageLayout, title: pageLayoutState.title,
            style: BoardRenderStyle(pageLayoutState.topic.formatting), attribution: pageLayoutState.symbolAttribution)
        let layout = compactControls ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        layout {
            GeometryReader { geo in
                let viewport = BoardPageViewport(pageSize: geometry.pageSize, cellSize: geometry.cellSize,
                                                 viewport: geo.size, zoom: effectiveZoom)
                BoardPageCanvas(viewport: viewport, size: geo.size,
                    accessibilityID: usesBoardIdentifiers ? AccessibilityIdentifiers.PhotoSelectionView.collectionView : AccessibilityIdentifiers.PreviewScreen.pageScroll,
                    photoCount: pageLayoutState.photoBrowserData.photoCount) {
                    if let page = renderer.page, page.boardID == ObjectIdentifier(pageLayoutState) {
                        pageContent(page, displaySize: viewport.displaySize)
                    } else {
                        Color.clear.frame(width: viewport.displaySize.width, height: viewport.displaySize.height)
                    }
                }
                .overlay {
                    if showsNoPhotosOverlay && pageLayoutState.photoBrowserData.photoItems.isEmpty {
                        NoPhotosBoardOverlay(pageLayoutState: pageLayoutState)
                    }
                }
                // Preserve the scroll view and gestures across resize and zoom.
                // Only navigating to a different page should discard its offsets.
                .id("\(ObjectIdentifier(pageLayoutState))-\(selectedPage)")
                .task(id: "\(ObjectIdentifier(pageLayoutState))-\(pageLayoutState.renderRevision)-\(selectedPage)-\(geo.size)-\(zoom)-\(displayScale)") {
                    await renderer.prepare(state: pageLayoutState, pageIndex: selectedPage,
                        viewport: geo.size, zoom: zoom, displayScale: displayScale)
                }
                .simultaneousGesture(zoomGesture)
                .accessibilityAction(named: Text(L10n.BoardEditor.zoomIn)) {
                    zoom = BoardPageViewport.zoomedIn(from: zoom)
                }
                .accessibilityAction(named: Text(L10n.BoardEditor.zoomOut)) {
                    zoom = BoardPageViewport.zoomedOut(from: zoom)
                }
                .accessibilityAction(named: Text(L10n.BoardEditor.zoomFit)) {
                    zoom = BoardPageViewport.fitZoom
                }
            }
            if compactControls {
                VStack(spacing: 0) {
                    compactActions
                        .frame(maxHeight: .infinity, alignment: .center)
                    if pageCount > 1 {
                        BoardPageControls(selectedPage: $selectedPage, pageCount: pageCount,
                                          compact: true, onDropPage: dropOnPage)
                    }
                }
                .frame(width: 112)
            } else if pageCount > 1 {
                BoardPageControls(selectedPage: $selectedPage, pageCount: pageCount,
                                  compact: false, onDropPage: dropOnPage)
                    .padding(.vertical, pageControlsVerticalPadding)
            }
        }
        .onChange(of: pageCount) { count in
            selectedPage = min(selectedPage, count - 1)
        }
    }

    private var pageCount: Int {
        let count = max(pageLayoutState.pageLayout.total, 1)
        return max(1, (pageLayoutState.photoBrowserData.photoCount + count - 1) / count)
    }

    private var effectiveZoom: CGFloat {
        BoardPageViewport.clampedZoom(zoom * pinchMagnification)
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($pinchMagnification) { magnification, state, _ in
                state = BoardPageViewport.clampedZoom(zoom * magnification) / zoom
            }
            .onEnded { magnification in
                zoom = BoardPageViewport.clampedZoom(zoom * magnification)
            }
    }

    private func pageContent(_ page: BoardRenderedPage, displaySize: CGSize) -> some View {
        let transientScale = displaySize.width / max(page.displaySize.width, 1)
        return ZStack(alignment: .topLeading) {
            page.style.cellFillColor
            ForEach(page.cards) { card in
                cardButton(card)
                    .frame(width: card.rect.width, height: card.rect.height)
                    .boardCardTransitionSource(id: transitionID(for: card), namespace: transitionNamespace)
                    .position(x: card.rect.midX, y: card.rect.midY)
            }
            decoration(page)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .frame(width: page.displaySize.width, height: page.displaySize.height)
        .clipped()
        .scaleEffect(transientScale, anchor: .topLeading)
        .frame(width: displaySize.width, height: displaySize.height, alignment: .topLeading)
        .shadow(color: .black.opacity(0.15), radius: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.page(for: selectedPage))
    }

    private func decoration(_ page: BoardRenderedPage) -> some View {
        let scale = page.displaySize.width / page.geometry.pageSize.width
        return ZStack(alignment: .topLeading) {
            BoardGridLines(geometry: page.geometry)
                .stroke(page.style.gridlinesColor, lineWidth: page.style.gridlinesWidth * scale)
            if let title = page.decoration.title {
                Image(uiImage: title).resizable()
                    .frame(width: page.displaySize.width, height: page.geometry.titleRect.height * scale)
            }
            if let footer = page.decoration.footer {
                Image(uiImage: footer).resizable()
                    .frame(width: page.displaySize.width, height: page.geometry.footerRect.height * scale)
                    .offset(y: page.geometry.footerRect.minY * scale)
            }
        }
        .frame(width: page.displaySize.width, height: page.displaySize.height)
    }

    private func transitionID(for card: BoardCardPlacement) -> String {
        "page-\(selectedPage)-slot-\(card.slot)"
    }

    private func cardButton(_ card: BoardCardPlacement) -> some View {
        Button {
            onTransitionSourceSelected?(transitionID(for: card))
            onCellTap(card.sourceIndex)
        } label: {
            ZStack {
                if let image = card.image {
                    Image(uiImage: image).resizable()
                }
                if let id = card.photoID, selectedPhotoIDs.contains(id) {
                    Color.accentColor.opacity(0.18)
                    Rectangle().strokeBorder(Color.accentColor, lineWidth: 2)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                }
            }
            // Blank cards have no rendered child to contribute a hit-test area.
            // Fill the button's proposed size so every visible card is tappable.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(BoardCardButtonStyle())
        .disabled(card.isBlank && isSelectionMode)
        .accessibilityLabel(L10n.PreviewPage.cardPosition(selectedPage + 1, card.slot + 1, card.title))
        .accessibilityHint(card.isBlank ? L10n.PreviewPage.addCardHint : L10n.PreviewPage.editCardHint)
        .accessibilityAddTraits(card.photoID.map { selectedPhotoIDs.contains($0) } == true ? .isSelected : [])
        .accessibilityIdentifier(usesBoardIdentifiers
            ? (card.isBlank ? AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: card.sourceIndex)
                                  : AccessibilityIdentifiers.PhotoSelectionView.image(for: card.sourceIndex))
            : AccessibilityIdentifiers.PreviewScreen.cell(for: selectedPage * max(pageLayoutState.pageLayout.total, 1) + card.slot))
        .draggable(card.photoID?.uuidString ?? "")
        .dropDestination(for: String.self) { items, _ in
            guard let value = items.first, let id = UUID(uuidString: value),
                  let target = pageLayoutState.photoBrowserData.photoItems.firstIndex(where: { $0.itemID == card.photoID }) else { return false }
            move(id: id, to: target)
            return true
        }
        .accessibilityAction(named: Text(L10n.BoardEditor.moveEarlier)) { move(card, offset: -1) }
        .accessibilityAction(named: Text(L10n.BoardEditor.moveLater)) { move(card, offset: 1) }
    }

    private func dropOnPage(_ items: [String], page: Int) -> Bool {
        guard (0..<pageCount).contains(page), let value = items.first,
              let id = UUID(uuidString: value) else { return false }
        move(id: id, to: min(page * max(pageLayoutState.pageLayout.total, 1), pageLayoutState.photoBrowserData.photoCount - 1))
        selectedPage = page
        return true
    }

    private func move(_ card: BoardCardPlacement, offset: Int) {
        guard let id = card.photoID,
              let index = pageLayoutState.photoBrowserData.photoItems.firstIndex(where: { $0.itemID == id }) else { return }
        let target = index + offset
        guard pageLayoutState.photoBrowserData.photoItems.indices.contains(target) else { return }
        move(id: id, to: target)
        selectedPage = target / max(pageLayoutState.pageLayout.total, 1)
    }

    private func move(id: UUID, to target: Int) {
        var photos = pageLayoutState.photoBrowserData.photoItems
        guard let source = photos.firstIndex(where: { $0.itemID == id }), photos.indices.contains(target), source != target else { return }
        let photo = photos.remove(at: source)
        photos.insert(photo, at: target)
        pageLayoutState.photoBrowserData.photoItems = photos
    }
}

/// A touch-up inside a large card must not count as a tap after swiping along
/// the fitted (non-scrolling) axis. TapGesture cancels once the finger moves.
private struct BoardCardButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onTapGesture(perform: configuration.trigger)
            .accessibilityAction { configuration.trigger() }
    }
}

private struct BoardGridLines: Shape {
    let geometry: BoardPageGeometry
    func path(in rect: CGRect) -> Path {
        let transform = CGAffineTransform(scaleX: rect.width / geometry.pageSize.width,
                                         y: rect.height / geometry.pageSize.height)
        var path = Path()
        for line in geometry.gridLines {
            path.move(to: line.0.applying(transform))
            path.addLine(to: line.1.applying(transform))
        }
        return path
    }
}
