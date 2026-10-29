import Foundation

struct ButtonEditDraft: Identifiable {
    var button: SnapButton
    var placement: SnapPlacement
    let pageID: String
    let layoutID: Int
    var isNew = false
    var id: String { "\(pageID)-\(layoutID)-\(placement.id)" }
}
