import Foundation

struct SnapPage: Codable, Identifiable, Sendable {
    var id: String
    var title: String
    var pageType: Int
    var layouts: [SnapLayout]
    var preferredLayoutID: Int?
    var backgroundARGB: UInt32? = nil

    var preferredLayout: SnapLayout? { layouts.first { $0.id == preferredLayoutID } ?? layouts.first }
}
