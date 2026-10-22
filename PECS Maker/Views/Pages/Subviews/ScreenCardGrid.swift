import SwiftUI

/// Native grid placement shared by PhotoListView2 and the topic screen.
/// Slots identify positions; callers can supply item identity within each slot.
struct ScreenCardGrid<Content: View>: View {
    let geometry: ScreenCardGridGeometry
    var usesIntrinsicRowHeight = false
    @ViewBuilder let content: (Int) -> Content

    var body: some View {
        Grid(horizontalSpacing: geometry.spacing, verticalSpacing: geometry.spacing) {
            ForEach(0..<geometry.rows, id: \.self) { row in
                GridRow {
                    ForEach(0..<geometry.columns, id: \.self) { column in
                        content(row * geometry.columns + column)
                            .frame(width: geometry.cardSize.width,
                                   height: usesIntrinsicRowHeight ? nil : geometry.cardSize.height)
                    }
                }
            }
        }
        .frame(width: geometry.pageSize.width,
               height: usesIntrinsicRowHeight ? nil : geometry.pageSize.height)
    }
}
