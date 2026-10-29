import Foundation

struct NativeBoardFactory {
    @MainActor static func make(title: String, rows: Int, columns: Int, starter: Bool) throws -> SnapPageSet {
        var set = try PageSetAuthoring.emptyBoard(title: title, rows: rows, columns: columns)
        if starter {
            for (index, symbol) in BuiltinSymbol.choices.prefix(min(rows * columns, 9)).enumerated() {
                var draft = try PageSetAuthoring.draft(in: set, pageID: set.homePageID, layoutID: 1,
                                                       row: index / columns, column: index % columns)
                draft.button.label = symbol.label
                try PageSetAuthoring.apply(.upsertButton(pageID: set.homePageID, layoutID: 1, button: draft.button,
                                                        placement: draft.placement, artwork: .replace(try ButtonArtwork.symbol(symbol))), to: &set)
            }
        }
        return set
    }

    static func editableCopy(of board: ScannedBoard) throws -> SnapPageSet {
        var set = try PageSetAuthoring.emptyBoard(title: board.title + " editable", rows: board.rows, columns: board.columns)
        for card in board.cards where card.isEmpty != true {
            var draft = try PageSetAuthoring.draft(in: set, pageID: set.homePageID, layoutID: 1, row: card.row, column: card.column)
            draft.button.label = card.label
            draft.button.message = card.message ?? ""
            draft.placement.visible = card.included
            try PageSetAuthoring.apply(.upsertButton(pageID: set.homePageID, layoutID: 1, button: draft.button,
                                                    placement: draft.placement, artwork: .replace(card.imagePNG)), to: &set)
        }
        return set
    }
}
