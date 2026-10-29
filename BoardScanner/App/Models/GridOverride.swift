import Foundation

struct GridOverride: Sendable {
    var rows = 2
    var columns = 3
    var left = 0.0
    var top = 0.0
    var right = 0.0
    var bottom = 0.0
    var inset = 0.02

    var cells: [CGRect] {
        let width = (1 - left - right) / Double(columns)
        let height = (1 - top - bottom) / Double(rows)
        return (0..<rows).flatMap { row in
            (0..<columns).map { column in
                CGRect(x: left + Double(column) * width, y: top + Double(row) * height,
                       width: width, height: height).insetBy(dx: width * inset, dy: height * inset)
            }
        }
    }
}
