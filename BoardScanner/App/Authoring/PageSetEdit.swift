import Foundation

enum PageSetEdit: Sendable {
    case addPage(title: String, rows: Int, columns: Int, id: String = "user-" + UUID().uuidString.lowercased())
    case updatePage(id: String, layoutID: Int, title: String, rows: Int, columns: Int, home: Bool)
    case deletePage(id: String)
    case upsertButton(pageID: String, layoutID: Int, button: SnapButton, placement: SnapPlacement, artwork: ArtworkChange)
    case removeButton(pageID: String, layoutID: Int, placementID: Int)

    var successMessage: String {
        switch self {
        case .upsertButton: "Button updated · Saved"
        case .removeButton: "Button removed · Saved"
        case .addPage: "Page added · Saved"
        case .updatePage: "Page updated · Saved"
        case .deletePage: "Page deleted · Saved"
        }
    }
}
