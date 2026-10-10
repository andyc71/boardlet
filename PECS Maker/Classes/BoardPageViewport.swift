import SwiftUI

/// Screen placement only; the canonical page and exported layout are unchanged.
struct BoardPageViewport {
    static let inset: CGFloat = 12
    /// Approximately four cards across a 402-point iPhone, allowing page insets.
    /// Keep this stable while resizing so a smaller window does not shrink targets.
    static let minimumCardSide: CGFloat = 94
    /// Relative to the fitted/fill presentation, so users can make cards
    /// substantially smaller without changing the initial board size.
    static let minimumZoom: CGFloat = 0.25
    static let fitZoom: CGFloat = 1
    static let maximumZoom: CGFloat = 2
    static let maximumZoomOvershoot: CGFloat = 0.35
    static let accessibilityZoomStep: CGFloat = 0.25

    let scale: CGFloat
    let displaySize: CGSize
    let scrollAxes: Axis.Set
    let availableSize: CGSize
    let zoomToFitAvailableSpace: CGFloat

    struct Overflow: Equatable {
        var left = false
        var right = false
        var top = false
        var bottom = false

        init() {}

        init(contentFrame: CGRect, viewport: CGSize, axes: Axis.Set) {
            guard !contentFrame.isEmpty else { return }
            left = axes.contains(.horizontal) && contentFrame.minX < -1
            right = axes.contains(.horizontal) && contentFrame.maxX > viewport.width + 1
            top = axes.contains(.vertical) && contentFrame.minY < -1
            bottom = axes.contains(.vertical) && contentFrame.maxY > viewport.height + 1
        }
    }

    struct ScrollSettlement {
        let anchor: UnitPoint
        let closesEdgeGap: Bool
    }

    struct MaximumZoomSettlement {
        let committedZoom: CGFloat
        let visualScale: CGFloat
    }

    init(pageSize: CGSize, cellSize: CGSize, viewport: CGSize, zoom: CGFloat) {
        availableSize = CGSize(width: max(viewport.width - 2 * Self.inset, 1),
                               height: max(viewport.height - 2 * Self.inset, 1))
        let widthScale = availableSize.width / max(pageSize.width, 1)
        let heightScale = availableSize.height / max(pageSize.height, 1)
        let fit = min(widthScale, heightScale)
        let readableScale = Self.minimumCardSide / max(min(cellSize.width, cellSize.height), 1)
        // Each candidate fills one axis, preserving the page's aspect ratio.
        // Choose the readable candidate with the least travel in viewport lengths.
        // When even the larger candidate cannot reach the card-size target, use
        // that candidate: the fitted axis stays locked even in a very small window.
        let candidates = [widthScale, heightScale].filter { $0 >= readableScale }
        func travel(_ scale: CGFloat) -> CGFloat {
            max(0, (pageSize.width * scale + Self.inset - viewport.width) / max(viewport.width, 1))
                + max(0, (pageSize.height * scale + Self.inset - viewport.height) / max(viewport.height, 1))
        }
        let baseScale = fit >= readableScale ? fit
            : candidates.min(by: { travel($0) < travel($1) }) ?? max(widthScale, heightScale)
        zoomToFitAvailableSpace = Self.clampedZoom(fit / baseScale)
        scale = baseScale * Self.clampedDisplayZoom(zoom)
        displaySize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
        var axes: Axis.Set = []
        // Ignore subpixel rounding on the fitted axis.
        if displaySize.width > availableSize.width + 0.5 { axes.insert(.horizontal) }
        if displaySize.height > availableSize.height + 0.5 { axes.insert(.vertical) }
        scrollAxes = axes
    }

    /// When the entire page has room around every edge, grow it to the largest
    /// size that still fits the usable viewport while preserving its aspect ratio.
    var settledZoom: CGFloat? {
        guard displaySize.width < availableSize.width - 0.5,
              displaySize.height < availableSize.height - 0.5 else { return nil }
        return zoomToFitAvailableSpace
    }

    static func clampedZoom(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, minimumZoom), maximumZoom)
    }

    /// Adds resistance above the persistent maximum while still allowing a
    /// small amount of visual travel for a natural pinch boundary.
    static func rubberBandedZoom(_ zoom: CGFloat) -> CGFloat {
        guard zoom > maximumZoom else { return clampedZoom(zoom) }
        let overflow = zoom - maximumZoom
        let resistedOverflow = overflow / (1 + overflow / maximumZoomOvershoot)
        return maximumZoom + resistedOverflow
    }

    /// Keeps scroll geometry fixed at the maximum while the visual overshoot
    /// settles. Animating the scroll content size would cause a second reanchor.
    static func maximumZoomSettlement(for requestedZoom: CGFloat) -> MaximumZoomSettlement? {
        guard requestedZoom > maximumZoom else { return nil }
        return MaximumZoomSettlement(
            committedZoom: maximumZoom,
            visualScale: rubberBandedZoom(requestedZoom) / maximumZoom
        )
    }

    private static func clampedDisplayZoom(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, minimumZoom), maximumZoom + maximumZoomOvershoot)
    }

    static func zoomedIn(from zoom: CGFloat) -> CGFloat {
        clampedZoom(zoom + accessibilityZoomStep)
    }

    static func zoomedOut(from zoom: CGFloat) -> CGFloat {
        clampedZoom(zoom - accessibilityZoomStep)
    }

    /// Returns the `ScrollViewReader` anchor that keeps the same content point
    /// under the viewport's center after the scrollable content changes size.
    /// Clamping the anchor also closes a newly exposed gap at either edge.
    static func centerPreservingScrollAnchor(previousFrame: CGRect, newContentSize: CGSize,
                                             viewport: CGSize) -> UnitPoint {
        scrollSettlement(previousFrame: previousFrame, newContentSize: newContentSize,
                         viewport: viewport).anchor
    }

    static func scrollSettlement(previousFrame: CGRect, newContentSize: CGSize,
                                 viewport: CGSize) -> ScrollSettlement {
        let horizontal = axisScrollSettlement(previousOrigin: previousFrame.minX,
                                               previousLength: previousFrame.width,
                                               newLength: newContentSize.width,
                                               viewportLength: viewport.width)
        let vertical = axisScrollSettlement(previousOrigin: previousFrame.minY,
                                             previousLength: previousFrame.height,
                                             newLength: newContentSize.height,
                                             viewportLength: viewport.height)
        return ScrollSettlement(anchor: UnitPoint(x: horizontal.anchor, y: vertical.anchor),
                                closesEdgeGap: horizontal.closesEdgeGap || vertical.closesEdgeGap)
    }

    /// Filters subpixel layout noise so it cannot repeatedly request the same
    /// scroll settlement during an animated size transition.
    static func hasMeaningfulSizeChange(from previous: CGSize, to next: CGSize,
                                        tolerance: CGFloat = 0.5) -> Bool {
        abs(previous.width - next.width) > tolerance ||
            abs(previous.height - next.height) > tolerance
    }

    private static func axisScrollSettlement(previousOrigin: CGFloat, previousLength: CGFloat,
                                             newLength: CGFloat, viewportLength: CGFloat)
        -> (anchor: CGFloat, closesEdgeGap: Bool) {
        guard previousLength > 0, viewportLength > 0 else { return (0.5, false) }
        let previousCenter = viewportLength / 2 - previousOrigin
        let centerFraction = min(max(previousCenter / previousLength, 0), 1)
        let newScrollRange = newLength - viewportLength
        guard newScrollRange > 0.5 else { return (0.5, false) }
        let newOffset = centerFraction * newLength - viewportLength / 2
        let closesEdgeGap = newOffset < -0.5 || newOffset > newScrollRange + 0.5
        return (min(max(newOffset / newScrollRange, 0), 1), closesEdgeGap)
    }
}
