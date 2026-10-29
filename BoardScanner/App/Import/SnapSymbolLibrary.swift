import Foundation

/// Reads only requested symbol IDs; the full library is never copied into a board.
enum SnapSymbolLibrary {
    @concurrent static func supplement(_ original: SnapPageSet, from url: URL) async throws -> SnapPageSet {
        try Task.checkCancellation()
        let accessible = url.startAccessingSecurityScopedResource()
        defer { if accessible { url.stopAccessingSecurityScopedResource() } }
        guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 1_000_000_000 else {
            throw LibraryError.tooLarge
        }
        do {
            let db = try SnapDatabase(url: url)
            // Validate the required structure even when no symbols are missing.
            try db.rows("SELECT SymbolId, Image FROM Symbol LIMIT 0") { _ in }
            var requests: [Int64: String] = [:]
            for button in original.buttons.values {
                guard let key = button.assetKey, key.hasPrefix("SYM:"),
                      original.assets[key]?.previewPNG == nil,
                      let id = Int64(key.dropFirst(4)), id > 0 else { continue }
                requests[id] = key
            }
            var result = original
            let ids = requests.keys.sorted()
            var addedBytes = 0
            for start in stride(from: 0, to: ids.count, by: 100) {
                try Task.checkCancellation()
                // Values are parsed positive integers, never source SQL or text identifiers.
                let batch = ids[start..<min(start + 100, ids.count)].map(String.init).joined(separator: ",")
                var seen = Set<Int>()
                try db.rows("SELECT SymbolId, Image FROM Symbol WHERE SymbolId IN (\(batch))", limit: 100) { row in
                    let id = SnapDatabase.integer(row, 0)
                    guard seen.insert(id).inserted, let key = requests[Int64(id)] else { throw LibraryError.invalid }
                    let bytes = SnapDatabase.data(row, 1)
                    guard !bytes.isEmpty, bytes.count <= 4_000_000 else { throw LibraryError.invalid }
                    addedBytes += bytes.count
                    guard addedBytes <= 40_000_000 else { throw LibraryError.tooLarge }
                    let asset = try SnapArtwork.preview(bytes)
                    addedBytes += asset.previewPNG?.count ?? 0
                    guard addedBytes <= 40_000_000 else { throw LibraryError.tooLarge }
                    // Preserve existing originals if an alternative library fails to render.
                    if asset.previewPNG != nil || result.assets[key] == nil { result.assets[key] = asset }
                }
            }
            try result.validate()
            // Atomic publication: keep the user's current board if the supplemented archive cannot be saved.
            _ = try BoardDocument(pageSet: result).encoded()
            try Task.checkCancellation()
            return result
        } catch is CancellationError { throw CancellationError() }
        catch ScanError.invalidPageSet { throw LibraryError.invalid }
    }
}

enum LibraryError: LocalizedError {
    case invalid, tooLarge
    var errorDescription: String? {
        switch self {
        case .invalid: "This file is not a supported TD Snap symbol library. Choose a symbol database (.db3) containing symbol IDs and images."
        case .tooLarge: "This symbol library or its requested artwork exceeds the import limits."
        }
    }
}
