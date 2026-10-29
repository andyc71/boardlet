import Foundation

struct TDSnapImporter {
    @concurrent static func load(_ url: URL) async throws -> SnapPageSet {
        try Task.checkCancellation()
        let accessible = url.startAccessingSecurityScopedResource()
        defer { if accessible { url.stopAccessingSecurityScopedResource() } }
        guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 80_000_000 else {
            throw ScanError.oversizedFile
        }
        let db = try SnapDatabase(url: url)
        var title = "", schema = "", home = "", defaultGrid = ""
        try db.rows("SELECT FriendlyName, SchemaVersion, DefaultHomePageUniqueId, GridDimension FROM PageSetProperties", limit: 1) { row in
            title = SnapDatabase.text(row, 0)
            schema = SnapDatabase.text(row, 1)
            home = SnapDatabase.text(row, 2).lowercased()
            defaultGrid = SnapDatabase.text(row, 3)
        }
        guard !home.isEmpty, !schema.isEmpty else { throw ScanError.invalidPageSet }
        var assets: [String: SnapAsset] = [:]
        var symbolAssets: [String: String] = [:]
        var totalBytes = 0
        try db.rows("SELECT Id, Identifier, Data FROM PageSetData") { row in
            let bytes = SnapDatabase.data(row, 2)
            totalBytes += bytes.count
            guard totalBytes <= 80_000_000 else { throw ScanError.oversizedFile }
            let asset = try SnapArtwork.preview(bytes)
            assets[String(SnapDatabase.integer(row, 0))] = asset
            let identifier = SnapDatabase.text(row, 1)
            if identifier.hasPrefix("SYM:") { symbolAssets[identifier] = String(SnapDatabase.integer(row, 0)) }
        }
        var links: [Int: [String]] = [:]
        try db.rows("SELECT ButtonId, PageUniqueId FROM ButtonPageLink ORDER BY Id") { row in
            links[SnapDatabase.integer(row, 0), default: []].append(SnapDatabase.text(row, 1).lowercased())
        }
        var commands: [Int: String] = [:]
        try db.rows("SELECT ButtonId, SerializedCommands FROM CommandSequence ORDER BY Id") { row in
            commands[SnapDatabase.integer(row, 0)] = SnapDatabase.text(row, 1)
        }
        var buttons: [String: SnapButton] = [:]
        var colours: [String: (UInt32?, UInt32?)] = [:]
        let elementColumns = try db.columns(in: "ElementReference")
        if elementColumns.isSuperset(of: ["Id", "BackgroundColor", "ForegroundColor"]) {
            try db.rows("SELECT Id, BackgroundColor, ForegroundColor FROM ElementReference") { row in
                colours[String(SnapDatabase.integer(row, 0))] = (SnapDatabase.argb(row, 1), SnapDatabase.argb(row, 2))
            }
        }
        var borders: [String: UInt32] = [:]
        if try db.columns(in: "Button").contains("BorderColor") {
            try db.rows("SELECT Id, BorderColor FROM Button") { row in
                borders[String(SnapDatabase.integer(row, 0))] = SnapDatabase.argb(row, 1)
            }
        }
        try db.rows("SELECT Id, ElementReferenceId, Label, Message, LibrarySymbolId, PageSetImageId FROM Button") { row in
            let buttonID = SnapDatabase.integer(row, 0)
            let elementID = String(SnapDatabase.integer(row, 1))
            guard buttons[elementID] == nil else { throw ScanError.invalidPageSet }
            let serialized = commands[buttonID] ?? ""
            let allLinks = (links[buttonID] ?? []) + commandDestinations(serialized)
            var seen = Set<String>()
            let imageID = SnapDatabase.integer(row, 5), symbolID = SnapDatabase.integer(row, 4)
            let assetKey = imageID != 0 ? String(imageID) : (symbolID != 0 ? (symbolAssets["SYM:\(symbolID)"] ?? "SYM:\(symbolID)") : nil)
            buttons[elementID] = SnapButton(id: String(buttonID), label: SnapDatabase.text(row, 2),
                                          message: SnapDatabase.text(row, 3), assetKey: assetKey,
                                          destinationIDs: allLinks.filter { !$0.isEmpty && seen.insert($0).inserted },
                                          serializedCommands: serialized,
                                          backgroundARGB: colours[elementID]?.0,
                                          foregroundARGB: colours[elementID]?.1,
                                          borderARGB: borders[String(buttonID)])
        }
        var placements: [Int: [SnapPlacement]] = [:]
        try db.rows("SELECT Id, ElementReferenceId, GridPosition, GridSpan, Visible, PageLayoutId FROM ElementPlacement", limit: 200_000) { row in
            let position = try pair(SnapDatabase.text(row, 2), allowZero: true)
            let span = try pair(SnapDatabase.text(row, 3))
            placements[SnapDatabase.integer(row, 5), default: []].append(
                SnapPlacement(id: SnapDatabase.integer(row, 0), elementID: String(SnapDatabase.integer(row, 1)),
                              column: position.0, row: position.1, columnSpan: span.0, rowSpan: span.1,
                              visible: SnapDatabase.integer(row, 4) != 0))
        }
        var layouts: [Int: [SnapLayout]] = [:]
        try db.rows("SELECT Id, PageId, PageLayoutSetting FROM PageLayout ORDER BY Id") { row in
            let setting = SnapDatabase.text(row, 2)
            let size = try pair(setting)
            let id = SnapDatabase.integer(row, 0)
            layouts[SnapDatabase.integer(row, 1), default: []].append(
                SnapLayout(id: id, setting: setting, columns: size.0, rows: size.1, placements: placements[id] ?? []))
        }
        var pages: [SnapPage] = []
        var pageColours: [String: UInt32] = [:]
        if try db.columns(in: "Page").contains("BackgroundColor") {
            try db.rows("SELECT UniqueId, BackgroundColor FROM Page") { row in
                pageColours[SnapDatabase.text(row, 0).lowercased()] = SnapDatabase.argb(row, 1)
            }
        }
        var backgroundARGB: UInt32?
        if try db.columns(in: "PageSetProperties").contains("PageBackgroundColor") {
            try db.rows("SELECT PageBackgroundColor FROM PageSetProperties", limit: 1) { backgroundARGB = SnapDatabase.argb($0, 0) }
        }
        try db.rows("SELECT Id, UniqueId, Title, PageType, GridDimension FROM Page ORDER BY Id", limit: 5_000) { row in
            let pageLayouts = layouts[SnapDatabase.integer(row, 0)] ?? []
            let pageGrid = SnapDatabase.text(row, 4)
            let desired = (try? pair(pageGrid.isEmpty ? defaultGrid : pageGrid))
            let preferred = pageLayouts.first {
                $0.columns == desired?.0 && $0.rows == desired?.1 && $0.setting.split(separator: ",").dropFirst(2).first == "True"
            } ?? pageLayouts.first { $0.columns == desired?.0 && $0.rows == desired?.1 } ?? pageLayouts.first
            pages.append(SnapPage(id: SnapDatabase.text(row, 1).lowercased(), title: SnapDatabase.text(row, 2),
                                  pageType: SnapDatabase.integer(row, 3), layouts: pageLayouts, preferredLayoutID: preferred?.id,
                                  backgroundARGB: pageColours[SnapDatabase.text(row, 1).lowercased()]))
        }
        let result = SnapPageSet(title: title.isEmpty ? url.deletingPathExtension().lastPathComponent : title,
                                 schemaVersion: schema, homePageID: home, pages: pages, buttons: buttons, assets: assets,
                                 backgroundARGB: backgroundARGB)
        try result.validate()
        try Task.checkCancellation()
        return result
    }

    private static func pair(_ string: String, allowZero: Bool = false) throws -> (Int, Int) {
        let parts = string.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count >= 2, let x = Int(parts[0]), let y = Int(parts[1]),
              ((allowZero ? 0 : 1)...128).contains(x), ((allowZero ? 0 : 1)...128).contains(y) else {
            throw ScanError.invalidPageSet
        }
        return (x, y)
    }

    /// Conditional links are offered as destinations; TD Snap expressions are never executed.
    static func commandDestinations(_ commands: String) -> [String] {
        guard let data = commands.data(using: .utf8), let value = try? JSONSerialization.jsonObject(with: data) else { return [] }
        func walk(_ value: Any, depth: Int) -> [String] {
            guard depth < 32 else { return [] }
            if let object = value as? [String: Any] {
                var result = (object["LinkedPageId"] as? String).map { [$0.lowercased()] } ?? []
                for key in object.keys.sorted() where key != "LinkedPageId" { result += walk(object[key]!, depth: depth + 1) }
                return result
            }
            if let array = value as? [Any] { return array.flatMap { walk($0, depth: depth + 1) } }
            return []
        }
        return walk(value, depth: 0)
    }
}
