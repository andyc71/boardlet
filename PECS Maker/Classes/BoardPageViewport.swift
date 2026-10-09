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
    static let accessibilityZoomStep: CGFloat = 0.25

    let scale: CGFloat
    let displaySize: CGSize
    let scrollAxes: Axis.Set

    var padding: EdgeInsets {
        EdgeInsets(top: Self.inset, leading: Self.inset,
                   bottom: scrollAxes.contains(.vertical) ? 0 : Self.inset,
                   trailing: scrollAxes.contains(.horizontal) ? 0 : Self.inset)
    }

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

    init(pageSize: CGSize, cellSize: CGSize, viewport: CGSize, zoom: CGFloat) {
        let available = CGSize(width: max(viewport.width - 2 * Self.inset, 1),
                               height: max(viewport.height - 2 * Self.inset, 1))
        let widthScale = available.width / max(pageSize.width, 1)
        let heightScale = available.height / max(pageSize.height, 1)
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
        scale = baseScale * Self.clampedZoom(zoom)
        displaySize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
        var axes: Axis.Set = []
        // Ignore subpixel rounding on the fitted axis.
        if displaySize.width > available.width + 0.5 { axes.insert(.horizontal) }
        if displaySize.height > available.height + 0.5 { axes.insert(.vertical) }
        scrollAxes = axes
    }

    static func clampedZoom(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, minimumZoom), maximumZoom)
    }

    static func zoomedIn(from zoom: CGFloat) -> CGFloat {
        clampedZoom(zoom + accessibilityZoomStep)
    }

    static func zoomedOut(from zoom: CGFloat) -> CGFloat {
        clampedZoom(zoom - accessibilityZoomStep)
    }
}
