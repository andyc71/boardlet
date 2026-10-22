import Foundation

/// Shared screen geometry for the photo editor and topic grids.
struct ScreenCardGridGeometry {
    let columns: Int
    let rows: Int
    let spacing: CGFloat
    let pageSize: CGSize
    let cardSize: CGSize

    private init(columns: Int, rows: Int, spacing: CGFloat, pageSize: CGSize) {
        self.columns = max(columns, 1)
        self.rows = max(rows, 1)
        self.spacing = spacing
        self.pageSize = pageSize
        cardSize = CGSize(
            width: (pageSize.width - CGFloat(self.columns - 1) * spacing) / CGFloat(self.columns),
            height: (pageSize.height - CGFloat(self.rows - 1) * spacing) / CGFloat(self.rows))
    }

    /// PhotoListView2's existing page fitting and minimum readable card size.
    static func fittingPage(_ layout: PageLayout, in viewport: CGSize,
                            cardAspectRatio: CGFloat, spacing: CGFloat = 8) -> Self {
        let columns = max(layout.width, 1)
        let rows = max(layout.height, 1)
        let fitted = layout.screenLayout(
            in: CGSize(width: viewport.width, height: viewport.height - 24),
            cardAspectRatio: cardAspectRatio)
        let scale = max(1,
            (CGFloat(columns) * 64 + CGFloat(columns - 1) * spacing) / fitted.pageSize.width,
            (CGFloat(rows) * 64 + CGFloat(rows - 1) * spacing) / fitted.pageSize.height)
        return Self(columns: columns, rows: rows, spacing: spacing,
                    pageSize: CGSize(width: fitted.pageSize.width * scale,
                                     height: fitted.pageSize.height * scale))
    }

    /// Resolve a screen preset once, using the same page fitting as Paper.
    /// Retain its aspect ratio; rendering fits that shape to the current viewport.
    static func screenPreset(_ layout: PageLayout, in viewport: CGSize,
                             spacing: CGFloat = 8, horizontalInset: CGFloat = 8) -> Self {
        // fittingPage already reserves eight points at each horizontal edge.
        let fittingViewport = CGSize(width: viewport.width - 2 * (horizontalInset - 8),
                                     height: viewport.height)
        let ratio = layout.fixedCardAspectRatio ??
            ((max(1, fittingViewport.width - 16) / CGFloat(max(layout.width, 1))) /
             (max(1, fittingViewport.height - 40) / CGFloat(max(layout.height, 1))))
        return fittingPage(layout, in: fittingViewport, cardAspectRatio: ratio, spacing: spacing)
    }

    func withRows(_ rows: Int) -> Self {
        let rows = max(rows, 1)
        return Self(columns: columns, rows: rows, spacing: spacing,
                    pageSize: CGSize(width: pageSize.width,
                                     height: CGFloat(rows) * cardSize.height + CGFloat(rows - 1) * spacing))
    }

    /// A continuous grid fills its width and grows vertically, preserving card shape.
    static func fillingWidth(_ viewportWidth: CGFloat, columns: Int, rows: Int,
                             cardAspectRatio: CGFloat, inset: CGFloat = 20,
                             spacing: CGFloat = 12) -> Self {
        let columns = max(columns, 1)
        let rows = max(rows, 1)
        let width = max(CGFloat(columns) + CGFloat(columns - 1) * spacing,
                        viewportWidth - 2 * inset)
        let cardWidth = (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        let height = CGFloat(rows) * cardWidth / max(cardAspectRatio, 0.01)
            + CGFloat(rows - 1) * spacing
        return Self(columns: columns, rows: rows, spacing: spacing,
                    pageSize: CGSize(width: width, height: height))
    }
}
