import Foundation

enum BoardTemplate: String, CaseIterable, Identifiable {
    case blank = "Blank board", firstThen = "First · Then", routine = "Routine"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .blank: "square.dashed"; case .firstThen: "arrow.right.square"; case .routine: "list.bullet.rectangle" }
    }
    func makeBoard(name: String) -> Board {
        var board = Board(name: name.isEmpty ? L("New board") : name)
        switch self {
        case .blank: break
        case .firstThen:
            board.cards = [Card(label: L("First"), systemSymbol: "1.square"), Card(label: L("Then"), systemSymbol: "2.square")]
        case .routine:
            board.cards = [Card(label: L("Wake up"), systemSymbol: "sun.max"), Card(label: L("Get dressed"), systemSymbol: "tshirt"), Card(label: L("Breakfast"), systemSymbol: "fork.knife"), Card(label: L("Go out"), systemSymbol: "figure.walk")]
        }
        return board
    }
}
