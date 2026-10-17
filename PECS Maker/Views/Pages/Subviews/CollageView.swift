import SwiftUI
import UIKit

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var renderer = BoardPageRenderModel()
    @StateObject private var cardTapGate = BoardCardTapGate()
    @StateObject private var zoomHaptics = BoardZoomHapticFeedback()
    @GestureState private var pinchState = BoardPinchState()
    @State private var maximumZoomReleaseScale: CGFloat = 1
    @State private var showsEmptyBoardPrompt = true

    var body: some View {
        let geometry = BoardPageGeometry(pageSize: pageLayoutState.pageMeasurements2.convertToPDFMeasurements(),
            layout: pageLayoutState.pageLayout, title: pageLayoutState.title,
            style: BoardRenderStyle(pageLayoutState.topic.formatting), attribution: pageLayoutState.symbolAttribution)
        let layout = compactControls ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        layout {
            GeometryReader { geo in
                let viewport = BoardPageViewport(pageSize: geometry.pageSize, cellSize: geometry.cellSize,
                                                 viewport: geo.size, zoom: zoom)
                let showsEmptyBoard = showsNoPhotosOverlay &&
                    renderer.page?.boardID == ObjectIdentifier(pageLayoutState) &&
                    pageLayoutState.photoBrowserData.photoItems.isEmpty
                BoardPageCanvas(viewport: viewport, size: geo.size,
                    accessibilityID: usesBoardIdentifiers ? AccessibilityIdentifiers.PhotoSelectionView.collectionView : AccessibilityIdentifiers.PreviewScreen.pageScroll,
                    photoCount: pageLayoutState.photoBrowserData.photoCount,
                    isPinching: pinchState.isActive,
                    showsOverflowIndicators: !showsEmptyBoard || !showsEmptyBoardPrompt) {
                    if let page = renderer.page, page.boardID == ObjectIdentifier(pageLayoutState) {
                        pageContent(page, displaySize: viewport.displaySize,
                                    liveMagnification: pinchState.isActive
                                        ? pinchState.magnification
                                        : maximumZoomReleaseScale)
                    } else {
                        Color.clear.frame(width: viewport.displaySize.width, height: viewport.displaySize.height)
                    }
                }
                .overlay {
                    if showsEmptyBoard && showsEmptyBoardPrompt {
                        EmptyBoardView(pageLayoutState: pageLayoutState) {
                            showsEmptyBoardPrompt = false
                        }
                    }
                }
                // Preserve the scroll view and gestures across resize and zoom.
                // Only navigating to a different page should discard its offsets.
                .id("\(ObjectIdentifier(pageLayoutState))-\(selectedPage)")
                .task(id: "\(ObjectIdentifier(pageLayoutState))-\(pageLayoutState.renderRevision)-\(selectedPage)-\(geo.size)-\(zoom)-\(displayScale)") {
                    await renderer.prepare(state: pageLayoutState, pageIndex: selectedPage,
                        viewport: geo.size, zoom: zoom, displayScale: displayScale)
                }
                .simultaneousGesture(zoomGesture(pageSize: geometry.pageSize,
                                                 cellSize: geometry.cellSize,
                                                 viewportSize: geo.size))
                .accessibilityAction(named: Text(L10n.BoardEditor.zoomIn)) {
                    maximumZoomReleaseScale = 1
                    zoom = BoardPageViewport.zoomedIn(from: zoom)
                }
                .accessibilityAction(named: Text(L10n.BoardEditor.zoomOut)) {
                    maximumZoomReleaseScale = 1
                    zoom = BoardPageViewport.zoomedOut(from: zoom)
                }
                .accessibilityAction(named: Text(L10n.BoardEditor.zoomFit)) {
                    maximumZoomReleaseScale = 1
                    zoom = BoardPageViewport.fitZoom
                }
            }
            if compactControls && !pageLayoutState.photoBrowserData.photoItems.isEmpty {
                VStack(spacing: 0) {
                    compactActions
                        .frame(maxHeight: .infinity, alignment: .center)
                    if pageCount > 1 {
                        BoardPageControls(selectedPage: $selectedPage, pageCount: pageCount,
                                          onDropPage: dropOnPage)
                    }
                }
                .frame(width: 112)
            } else if pageCount > 1 {
                BoardPageControls(selectedPage: $selectedPage, pageCount: pageCount,
                                  onDropPage: dropOnPage)
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

    private func zoomGesture(pageSize: CGSize, cellSize: CGSize,
                             viewportSize: CGSize) -> some Gesture {
        MagnificationGesture(minimumScaleDelta: 0.001)
            .updating($pinchState) { magnification, state, _ in
                state = BoardPinchState(
                    magnification: BoardPageViewport.rubberBandedZoom(zoom * magnification) / zoom,
                    isActive: true
                )
            }
            .onChanged { magnification in
                cardTapGate.registerPinch(at: ProcessInfo.processInfo.systemUptime)
                if zoom * magnification > BoardPageViewport.maximumZoom {
                    zoomHaptics.prepare()
                } else {
                    zoomHaptics.cancelPreparation()
                }
            }
            .onEnded { magnification in
                cardTapGate.registerPinch(at: ProcessInfo.processInfo.systemUptime)
                let requestedZoom = zoom * magnification
                if let settlement = BoardPageViewport.maximumZoomSettlement(for: requestedZoom) {
                    // Commit the scrollable layout directly at its final size.
                    // Only the centered render scale animates back from overshoot,
                    // so the scroll view has no intermediate size to reanchor.
                    zoom = settlement.committedZoom
                    maximumZoomReleaseScale = settlement.visualScale
                    DispatchQueue.main.async {
                        zoomHaptics.impact()
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                            maximumZoomReleaseScale = 1
                        }
                    }
                    return
                }

                maximumZoomReleaseScale = 1
                let committedZoom = BoardPageViewport.clampedZoom(requestedZoom)
                zoom = committedZoom

                let committedViewport = BoardPageViewport(pageSize: pageSize, cellSize: cellSize,
                                                          viewport: viewportSize, zoom: committedZoom)
                guard let settledZoom = committedViewport.settledZoom,
                      abs(settledZoom - committedZoom) > 0.001 else {
                    zoomHaptics.cancelPreparation()
                    return
                }
                // First commit the exact visual pinch scale. Starting the fit on
                // the next update avoids a discontinuity as GestureState resets.
                zoomHaptics.prepare()
                DispatchQueue.main.async {
                    zoomHaptics.impact()
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                        zoom = settledZoom
                    }
                }
            }
    }

    private func pageContent(_ page: BoardRenderedPage, displaySize: CGSize,
                             liveMagnification: CGFloat) -> some View {
        let preparedPageScale = displaySize.width / max(page.displaySize.width, 1)
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
        // Keep the scroll view's layout stable during the high-frequency gesture.
        // The committed zoom resizes it once on end, preserving the same visual scale.
        .scaleEffect(preparedPageScale * liveMagnification)
        .frame(width: displaySize.width, height: displaySize.height)
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
            guard cardTapGate.allowsTap(at: ProcessInfo.processInfo.systemUptime) else { return }
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

private struct BoardPinchState {
    var magnification: CGFloat = 1
    var isActive = false
}

/// Pinch bookkeeping deliberately publishes no changes; taps read the deadline on demand.
final class BoardCardTapGate: ObservableObject {
    static let suppressionInterval: TimeInterval = 0.3
    private var suppressUntil: TimeInterval = 0

    func registerPinch(at uptime: TimeInterval) {
        suppressUntil = uptime + Self.suppressionInterval
    }

    func allowsTap(at uptime: TimeInterval) -> Bool {
        uptime >= suppressUntil
    }
}

/// Keeps haptic preparation out of view state so a pinch does not publish updates.
final class BoardZoomHapticFeedback: ObservableObject {
    private let generator = UIImpactFeedbackGenerator(style: .soft)
    private var isPrepared = false

    func prepare() {
        guard !isPrepared else { return }
        isPrepared = true
        generator.prepare()
    }

    func impact() {
        generator.impactOccurred(intensity: 0.45)
        isPrepared = false
    }

    func cancelPreparation() {
        isPrepared = false
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
