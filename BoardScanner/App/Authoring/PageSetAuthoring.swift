import Foundation

struct PageSetAuthoring {
    static func emptyBoard(title: String, rows: Int, columns: Int) throws -> SnapPageSet {
        try checkGrid(rows: rows, columns: columns)
        let name = try checkedName(title)
        let page = SnapPage(id: newID(), title: name, pageType: 1,
                            layouts: [SnapLayout(id: 1, setting: "", columns: columns, rows: rows, placements: [])])
        return SnapPageSet(title: name, schemaVersion: "BoardScanner 1", homePageID: page.id,
                           pages: [page], buttons: [:], assets: [:])
    }

    static func draft(in set: SnapPageSet, pageID: String, layoutID: Int, row: Int, column: Int) throws -> ButtonEditDraft {
        let (pageIndex, layoutIndex) = try indices(in: set, pageID: pageID, layoutID: layoutID)
        let layout = set.pages[pageIndex].layouts[layoutIndex]
        let id = newID()
        let placement = SnapPlacement(id: try nextID(layout.placements.map(\.id)), elementID: id,
                                      column: column, row: row, columnSpan: 1, rowSpan: 1, visible: true)
        try checkPlacement(placement, in: layout)
        let button = SnapButton(id: id, label: "", message: "", destinationIDs: [], communicationAction: .addMessage, serializedCommands: "")
        return ButtonEditDraft(button: button, placement: placement, pageID: pageID, layoutID: layoutID, isNew: true)
    }

    static func apply(_ edit: PageSetEdit, to set: inout SnapPageSet) throws {
        var candidate = set
        try mutate(edit, in: &candidate)
        try candidate.validate()
        set = candidate
    }

    private static func mutate(_ edit: PageSetEdit, in set: inout SnapPageSet) throws {
        switch edit {
        case let .addPage(title, rows, columns, id):
            try checkGrid(rows: rows, columns: columns)
            let layoutID = try nextID(set.pages.flatMap(\.layouts).map(\.id))
            set.pages.append(SnapPage(id: id, title: try checkedName(title), pageType: 1,
                                     layouts: [SnapLayout(id: layoutID, setting: "", columns: columns, rows: rows, placements: [])]))
        case let .updatePage(id, layoutID, title, rows, columns, home):
            guard (1...128).contains(rows), (1...128).contains(columns) else { throw AuthoringError.invalidGrid }
            guard let p = set.pages.firstIndex(where: { $0.id == id }) else { throw AuthoringError.missingPage }
            if set.pages[p].layouts.isEmpty {
                let next = try nextID(set.pages.flatMap(\.layouts).map(\.id))
                set.pages[p].layouts.append(SnapLayout(id: next, setting: "", columns: columns, rows: rows, placements: []))
            }
            guard let l = set.pages[p].layouts.firstIndex(where: { $0.id == layoutID }) ?? (layoutID == -1 ? 0 : nil) else {
                throw AuthoringError.missingPage
            }
            set.pages[p].title = try checkedName(title)
            set.pages[p].layouts[l].rows = rows
            set.pages[p].layouts[l].columns = columns
            if home { set.homePageID = id }
        case let .deletePage(id):
            guard id != set.homePageID, set.pages.count > 1 else { throw AuthoringError.protectedHome }
            guard set.page(id) != nil else { throw AuthoringError.missingPage }
            set.pages.removeAll { $0.id == id }
            for key in Array(set.buttons.keys) {
                guard var button = set.buttons[key], button.destinationIDs.contains(id) else { continue }
                button.destinationIDs.removeAll { $0 == id }
                if button.destinationIDs.isEmpty,
                   button.communicationAction == nil || button.communicationAction == .automatic || button.communicationAction == .openPage {
                    button.communicationAction = CommunicationAction.none
                }
                set.buttons[key] = button
            }
            pruneUnusedUserContent(in: &set)
        case let .upsertButton(pageID, layoutID, original, placement, artwork):
            let (p, l) = try indices(in: set, pageID: pageID, layoutID: layoutID)
            guard !original.id.isEmpty, !placement.elementID.isEmpty else { throw AuthoringError.invalidName }
            try checkPlacement(placement, in: set.pages[p].layouts[l])
            var button = original
            if button.communicationAction == .openPage {
                guard button.destinationIDs.count == 1, let target = button.destinationIDs.first, set.page(target) != nil else {
                    throw AuthoringError.missingDestination
                }
            }
            switch artwork {
            case .unchanged: break
            case .remove: button.assetKey = nil
            case .replace(let data):
                guard data.count <= 10_000_000 else { throw AuthoringError.invalidImage }
                _ = try RasterImage(data: data, maximumDimension: 64)
                let key = newID()
                set.assets[key] = SnapAsset(data: data, previewPNG: data)
                button.assetKey = key
            }
            set.buttons[placement.elementID] = button
            if let index = set.pages[p].layouts[l].placements.firstIndex(where: { $0.id == placement.id }) {
                set.pages[p].layouts[l].placements[index] = placement
            } else { set.pages[p].layouts[l].placements.append(placement) }
            pruneUnusedUserContent(in: &set)
        case let .removeButton(pageID, layoutID, placementID):
            let (p, l) = try indices(in: set, pageID: pageID, layoutID: layoutID)
            set.pages[p].layouts[l].placements.removeAll { $0.id == placementID }
            pruneUnusedUserContent(in: &set)
        }
    }

    static func freeCells(in layout: SnapLayout, limit: Int = 144) -> [Int] {
        let columns = min(layout.columns, 128), rows = min(layout.rows, 128)
        guard columns > 0, rows > 0, limit > 0 else { return [] }
        var cells: [Int] = []
        for row in 0..<rows {
            for column in 0..<columns where !layout.placements.contains(where: {
                ( $0.row..<($0.row + $0.rowSpan)).contains(row) && ($0.column..<($0.column + $0.columnSpan)).contains(column)
            }) {
                cells.append(row * columns + column)
                if cells.count >= limit { return cells }
            }
        }
        return cells
    }

    private static func checkPlacement(_ placement: SnapPlacement, in layout: SnapLayout) throws {
        guard placement.row >= 0, placement.column >= 0, (1...128).contains(placement.rowSpan),
              (1...128).contains(placement.columnSpan), placement.row <= 256 - placement.rowSpan,
              placement.column <= 256 - placement.columnSpan else { throw AuthoringError.invalidGrid }
        // Imported layouts may intentionally overlap. A words/artwork-only edit
        // must preserve that source layout; new or moved placements cannot overlap.
        if let existing = layout.placements.first(where: { $0.id == placement.id }),
           existing.elementID == placement.elementID, existing.row == placement.row,
           existing.column == placement.column, existing.rowSpan == placement.rowSpan,
           existing.columnSpan == placement.columnSpan { return }
        if layout.placements.contains(where: { other in
            other.id != placement.id
            && placement.column < other.column + other.columnSpan
            && other.column < placement.column + placement.columnSpan
            && placement.row < other.row + other.rowSpan
            && other.row < placement.row + placement.rowSpan
        }) { throw AuthoringError.occupiedCell }
    }

    private static func nextID(_ values: [Int]) throws -> Int {
        let highest = values.max() ?? 0
        guard highest < Int.max else { throw AuthoringError.invalidGrid }
        return highest + 1
    }

    private static func pruneUnusedUserContent(in set: inout SnapPageSet) {
        let usedButtons = Set(set.pages.flatMap(\.layouts).flatMap(\.placements).map(\.elementID))
        for key in Array(set.buttons.keys) where key.hasPrefix("user-") && !usedButtons.contains(key) { set.buttons[key] = nil }
        let usedAssets = Set(set.buttons.values.compactMap(\.assetKey))
        for key in Array(set.assets.keys) where key.hasPrefix("user-") && !usedAssets.contains(key) { set.assets[key] = nil }
    }

    private static func indices(in set: SnapPageSet, pageID: String, layoutID: Int) throws -> (Int, Int) {
        guard let p = set.pages.firstIndex(where: { $0.id == pageID }),
              let l = set.pages[p].layouts.firstIndex(where: { $0.id == layoutID }) else { throw AuthoringError.missingPage }
        return (p, l)
    }
    private static func newID() -> String { "user-" + UUID().uuidString.lowercased() }
    private static func checkedName(_ name: String) throws -> String {
        let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw AuthoringError.invalidName }
        return value
    }
    private static func checkGrid(rows: Int, columns: Int) throws {
        guard (1...12).contains(rows), (1...12).contains(columns) else { throw AuthoringError.invalidGrid }
    }
}
