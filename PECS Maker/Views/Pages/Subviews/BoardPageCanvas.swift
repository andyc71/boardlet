import SwiftUI

/// Owns scroll feedback so scrolling does not invalidate the card renderer.
struct BoardPageCanvas<Content: View>: View {
    let viewport: BoardPageViewport
    let size: CGSize
    let accessibilityID: String
    let photoCount: Int
    let isPinching: Bool
    let showsOverflowIndicators: Bool
    let content: Content
    @Namespace private var coordinateSpace
    @StateObject private var geometryState = BoardPageCanvasGeometryState()
    @State private var overflow = BoardPageViewport.Overflow()
    @State private var pendingScrollSettlement: BoardPendingScrollSettlement?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewport: BoardPageViewport, size: CGSize, accessibilityID: String, photoCount: Int,
         isPinching: Bool, showsOverflowIndicators: Bool,
         @ViewBuilder content: () -> Content) {
        self.viewport = viewport
        self.size = size
        self.accessibilityID = accessibilityID
        self.photoCount = photoCount
        self.isPinching = isPinching
        self.showsOverflowIndicators = showsOverflowIndicators
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                // Keep the native scroll axes stable during pinch and live resize.
                // Content bounds and size-based bounce lock every fitted axis.
                ScrollView([.horizontal, .vertical]) {
                    content
                        .frame(minWidth: size.width, minHeight: size.height)
                        .id("boardContent")
                        .onGeometryChange(for: CGRect.self) { geometry in
                            geometry.frame(in: .named(coordinateSpace))
                        } action: { frame in
                            let previousFrame = geometryState.contentFrame
                            geometryState.contentFrame = frame
                            let next = BoardPageViewport.Overflow(contentFrame: frame, viewport: size, axes: viewport.scrollAxes)
                            if overflow != next { overflow = next }
                            if !previousFrame.isEmpty,
                               BoardPageViewport.hasMeaningfulSizeChange(from: previousFrame.size,
                                                                        to: frame.size) {
                                let settlement = BoardPageViewport.scrollSettlement(
                                    previousFrame: previousFrame, newContentSize: frame.size, viewport: size)
                                pendingScrollSettlement = BoardPendingScrollSettlement(
                                    contentSize: frame.size,
                                    anchorX: settlement.anchor.x,
                                    anchorY: settlement.anchor.y,
                                    closesEdgeGap: settlement.closesEdgeGap)
                            }
                        }
                }
                // A ScrollView treats small changes in a two-finger pinch's
                // centroid as panning. Keep the canvas fixed during the pinch;
                // deliberate one-finger scrolling resumes as soon as it ends.
                .scrollDisabled(isPinching)
                .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
                .accessibilityIdentifier(accessibilityID)
                .accessibilityValue("\(photoCount)")
                .task(id: pendingScrollSettlement) {
                    guard let settlement = pendingScrollSettlement else { return }
                    // Do not mutate the ScrollView from its geometry callback.
                    // Yielding also lets rapid size changes coalesce by cancelling
                    // the superseded task before it commits another scroll update.
                    await Task.yield()
                    guard !Task.isCancelled,
                          pendingScrollSettlement == settlement else { return }
                    let anchor = UnitPoint(x: settlement.anchorX, y: settlement.anchorY)
                    if settlement.closesEdgeGap && !reduceMotion {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("boardContent", anchor: anchor)
                        }
                    } else {
                        // This compensates for the layout-size commit and keeps
                        // overflowing content visually stationary after the pinch.
                        proxy.scrollTo("boardContent", anchor: anchor)
                    }
                }
                if showsOverflowIndicators {
                    BoardOverflowIndicators(overflow: overflow) { direction in
                        let contentFrame = geometryState.contentFrame
                        let rangeX = max(contentFrame.width - size.width, 0)
                        let rangeY = max(contentFrame.height - size.height, 0)
                        let x = min(max(-contentFrame.minX + direction.x * size.width * 0.8, 0), rangeX)
                        let y = min(max(-contentFrame.minY + direction.y * size.height * 0.8, 0), rangeY)
                        let anchor = UnitPoint(x: rangeX > 0 ? x / rangeX : 0,
                                               y: rangeY > 0 ? y / rangeY : 0)
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                            proxy.scrollTo("boardContent", anchor: anchor)
                        }
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
            .accessibilityElement(children: .contain)
            .coordinateSpace(name: coordinateSpace)
        }
    }
}

/// High-frequency geometry bookkeeping deliberately publishes no changes.
/// Only edge-state changes or a coalesced size settlement invalidate the view.
private final class BoardPageCanvasGeometryState: ObservableObject {
    var contentFrame = CGRect.zero
}

private struct BoardPendingScrollSettlement: Equatable {
    let contentSize: CGSize
    let anchorX: CGFloat
    let anchorY: CGFloat
    let closesEdgeGap: Bool
}
