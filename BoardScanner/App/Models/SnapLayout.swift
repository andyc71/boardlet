import Foundation

struct SnapLayout: Codable, Identifiable, Sendable {
    var id: Int
    var setting: String
    var columns: Int
    var rows: Int
    var placements: [SnapPlacement]
    // TD Snap supports scrolling content beyond the declared viewport grid.
    var contentColumns: Int { max(columns, placements.map { $0.column + $0.columnSpan }.max() ?? columns) }
    var contentRows: Int { max(rows, placements.map { $0.row + $0.rowSpan }.max() ?? rows) }
}
