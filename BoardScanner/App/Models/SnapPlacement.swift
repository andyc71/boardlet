import Foundation

struct SnapPlacement: Codable, Identifiable, Sendable {
    var id: Int
    var elementID: String
    var column: Int
    var row: Int
    var columnSpan: Int
    var rowSpan: Int
    var visible: Bool
}
