import Foundation

struct BoardStorage {
    static func decode(_ data: Data) throws -> ScannedBoard {
        guard data.count <= 80_000_000 else { throw ScanError.oversizedFile }
        let board = try JSONDecoder().decode(ScannedBoard.self, from: data)
        try board.validate()
        _ = try RasterImage(data: board.sourcePNG)
        for card in board.cards { _ = try RasterImage(data: card.imagePNG, maximumDimension: 64) }
        return board
    }

    static func decodePageSet(_ data: Data) throws -> SnapPageSet {
        guard data.count <= 80_000_000 else { throw ScanError.oversizedFile }
        let archive = try JSONDecoder().decode(ScannerArchive.self, from: data)
        try archive.validate()
        for asset in archive.pageSet.assets.values {
            try Task.checkCancellation()
            if let preview = asset.previewPNG { _ = try RasterImage(data: preview, maximumDimension: 64) }
        }
        return archive.pageSet
    }

    static func isPageSet(_ data: Data) throws -> Bool {
        struct Header: Decodable { var version: Int }
        return try JSONDecoder().decode(Header.self, from: data).version == 2
    }

    @concurrent static func openDocument(_ url: URL) async throws -> BoardDocument {
        let data = try await read(url)
        if try isPageSet(data) {
            var set = try decodePageSet(data)
            try SnapArtwork.regenerateMissingPreviews(&set)
            return BoardDocument(pageSet: set)
        }
        return try BoardDocument(board: decode(data))
    }

    @concurrent static func saveDocument(_ document: BoardDocument, to url: URL) async throws {
        let data = try document.encoded()
        try Task.checkCancellation()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    @concurrent static func read(_ url: URL) async throws -> Data {
        let accessible = url.startAccessingSecurityScopedResource()
        defer { if accessible { url.stopAccessingSecurityScopedResource() } }
        return try readBounded(url)
    }

    static func readBounded(_ url: URL) throws -> Data {
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 80_000_000 else { throw ScanError.oversizedFile }
        return try Data(contentsOf: url)
    }

    @concurrent static func load(_ url: URL) async throws -> ScannedBoard {
        try decode(try await read(url))
    }

    @concurrent static func save(_ board: ScannedBoard, to url: URL) async throws {
        try board.validate()
        let data = try JSONEncoder().encode(board)
        guard data.count <= 80_000_000 else { throw ScanError.oversizedFile }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
