import Foundation

struct ScanItem: Equatable, Identifiable {
    let id: String
    let label: String

    static let navigationActions = [
        ScanItem(id: "command:back", label: "Previous page"),
        ScanItem(id: "command:home", label: "Home page"),
    ]

    static let messageActions = [
        ScanItem(id: "command:stop", label: "Stop speaking"),
        ScanItem(id: "command:speak", label: "Speak message"),
        ScanItem(id: "command:undo", label: "Undo last word"),
        ScanItem(id: "command:clear", label: "Clear message"),
    ]

    static func cards(in board: ScannedBoard) -> [ScanItem] {
        board.cards.filter { $0.included && $0.isEmpty != true }
            .sorted { ($0.row, $0.column) < ($1.row, $1.column) }
            .map {
                ScanItem(
                    id: $0.id.uuidString, label: $0.label.isEmpty ? "Unlabelled card" : $0.label)
            }
    }

    static func placements(in layout: SnapLayout, pageSet: SnapPageSet) -> [ScanItem] {
        layout.placements.filter { $0.visible && pageSet.buttons[$0.elementID] != nil }
            .sorted { ($0.row, $0.column, $0.id) < ($1.row, $1.column, $1.id) }
            .map {
                ScanItem(
                    id: String($0.id),
                    label: pageSet.buttons[$0.elementID]?.label.nilIfEmpty ?? "Unlabelled button")
            }
    }
}

extension String {
    fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
}
