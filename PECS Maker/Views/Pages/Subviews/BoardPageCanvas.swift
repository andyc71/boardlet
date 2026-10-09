import SwiftUI

/// Owns scroll feedback so scrolling does not invalidate the card renderer.
struct BoardPageCanvas<Content: View>: View {
    let viewport: BoardPageViewport
    let size: CGSize
    let accessibilityID: String
    let photoCount: Int
    let content: Content
    @Namespace private var coordinateSpace
    @State private var overflow = BoardPageViewport.Overflow()
    @State private var contentFrame = CGRect.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewport: BoardPageViewport, size: CGSize, accessibilityID: String, photoCount: Int,
         @ViewBuilder content: () -> Content) {
        self.viewport = viewport
        self.size = size
        self.accessibilityID = accessibilityID
        self.photoCount = photoCount
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                // Keep the native scroll axes stable during pinch and live resize.
                // Content bounds and size-based bounce lock every fitted axis.
                ScrollView([.horizontal, .vertical]) {
                    content
                        .padding(viewport.padding)
                        .frame(minWidth: size.width, minHeight: size.height)
                        .id("boardContent")
                        .onGeometryChange(for: CGRect.self) { geometry in
                            geometry.frame(in: .named(coordinateSpace))
                        } action: { frame in
                            contentFrame = frame
                            let next = BoardPageViewport.Overflow(contentFrame: frame, viewport: size, axes: viewport.scrollAxes)
                            if overflow != next { overflow = next }
                        }
                }
                .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
                .accessibilityIdentifier(accessibilityID)
                .accessibilityValue("\(photoCount)")
                BoardOverflowIndicators(overflow: overflow) { direction in
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
            .frame(width: size.width, height: size.height)
            .clipped()
            .accessibilityElement(children: .contain)
            .coordinateSpace(name: coordinateSpace)
        }
    }
}
