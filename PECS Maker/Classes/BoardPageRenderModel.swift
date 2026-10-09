import SwiftUI

struct BoardCardPlacement: Identifiable {
    let id: String
    let photoID: UUID?
    let sourceIndex: Int
    let slot: Int
    let title: String
    let rect: CGRect
    let image: UIImage?
    let isBlank: Bool
}

struct BoardPageDecoration {
    let title: UIImage?
    let footer: UIImage?
}

struct BoardRenderedPage {
    let boardID: ObjectIdentifier
    let geometry: BoardPageGeometry
    let style: BoardRenderStyle
    let decoration: BoardPageDecoration
    let cards: [BoardCardPlacement]
    let displaySize: CGSize
}

@MainActor
final class BoardPageRenderModel: ObservableObject {
    @Published private(set) var page: BoardRenderedPage?
    let cache = BoardCardRenderCache()
    private var generation = 0
    private var decorationKey: BoardDecorationKey?
    private var decoration: BoardPageDecoration?
    private var preparedViewport: CGSize?
    private var preparedZoom: CGFloat?

    func prepare(state: PageLayoutState, pageIndex: Int, viewport: CGSize, zoom: CGFloat, displayScale: CGFloat) async {
        guard !Task.isCancelled else { return }
        generation += 1
        let request = generation
        if page?.boardID == ObjectIdentifier(state),
           preparedViewport != viewport || preparedZoom != zoom {
            // Scale cached artwork immediately; rasterize once resizing settles.
            // Wait before snapshotting inputs, so each preparation is consistent.
            do { try await Task.sleep(for: .milliseconds(150)) }
            catch { return }
            guard !Task.isCancelled, generation == request else { return }
        }
        let style = BoardRenderStyle(state.topic.formatting)
        let title = state.title
        let attribution = state.symbolAttribution
        let geometry = BoardPageGeometry(pageSize: state.pageMeasurements2.convertToPDFMeasurements(),
            layout: state.pageLayout, title: title, style: style, attribution: attribution)
        let placement = BoardPageViewport(pageSize: geometry.pageSize, cellSize: geometry.cellSize,
                                          viewport: viewport, zoom: zoom)
        let screenScale = placement.scale
        let size = placement.displaySize
        let rasterScale = screenScale * displayScale
        let photos = state.photoBrowserData.photoItems
        let count = geometry.columns * geometry.rows
        let repeating = state.repeatSinglePhoto && photos.count == 1
        // Snapshot all inputs before rendering yields. No mutable models are
        // consumed by a renderer after yielding, and cancelled results cannot publish.
        let inputs = (0..<count).map { slot -> (Int, BoardCardSnapshot?) in
            let index = repeating ? 0 : pageIndex * count + slot
            return (index, photos.indices.contains(index) ? BoardCardSnapshot(photos[index]) : nil)
        }
        let key = BoardDecorationKey(pageSize: geometry.pageSize, gridRect: geometry.gridRect,
            columns: geometry.columns, rows: geometry.rows, style: style,
            title: title, attribution: attribution, scale: rasterScale)
        let background: BoardPageDecoration
        if decorationKey == key, let decoration {
            background = decoration
        } else {
            background = BoardPageDecoration(
                title: CollageFactory.renderDecorationRegion(geometry.titleRect, geometry: geometry,
                    title: title, attribution: attribution, style: style, scale: rasterScale),
                footer: CollageFactory.renderDecorationRegion(geometry.footerRect, geometry: geometry,
                    title: title, attribution: attribution, style: style, scale: rasterScale))
            decorationKey = key
            decoration = background
        }
        var cards = [BoardCardPlacement]()
        var occurrences = [UUID: Int]()
        for (slot, input) in inputs.enumerated() {
            guard !Task.isCancelled, generation == request else { return }
            let (sourceIndex, card) = input
            let occurrence = card.map { occurrences[$0.id, default: 0] } ?? 0
            if let card { occurrences[card.id] = occurrence + 1 }
            let isBlank = card == nil || card?.isPlaceholder == true
            let image = card.flatMap { $0.isPlaceholder ? nil : cache.image(card: $0, style: style, size: geometry.cellSize, scale: rasterScale) }
            cards.append(BoardCardPlacement(
                id: card.map { "\($0.id)-\(occurrence)" } ?? "empty-\(pageIndex)-\(slot)",
                photoID: card?.id, sourceIndex: sourceIndex, slot: slot,
                title: card?.title.flatMap { $0.isEmpty ? nil : $0 } ?? (isBlank
                    ? L10n.PhotoSelectionView.emptyCard : L10n.PhotoSelectionView.untitledCell),
                rect: geometry.cellRect(slot: slot).applying(CGAffineTransform(scaleX: screenScale, y: screenScale)), image: image, isBlank: isBlank))
            await Task.yield()
        }
        guard !Task.isCancelled, generation == request else { return }
        preparedViewport = viewport
        preparedZoom = zoom
        page = BoardRenderedPage(boardID: ObjectIdentifier(state), geometry: geometry, style: style, decoration: background, cards: cards, displaySize: size)
    }
}
