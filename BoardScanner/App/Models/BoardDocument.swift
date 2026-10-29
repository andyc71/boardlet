import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let tdSnapPageSet = UTType(importedAs: "com.brightblue.tdsnap-pageset", conformingTo: .data)
    static let scannedBoard = UTType(exportedAs: "com.brightblue.boardscan", conformingTo: .json)
}

struct BoardDocument: FileDocument, Sendable {
    static var readableContentTypes: [UTType] { [.scannedBoard] }
    var board: ScannedBoard?
    var pageSet: SnapPageSet?

    init(board: ScannedBoard) { self.board = board }
    init(pageSet: SnapPageSet) { self.pageSet = pageSet }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw ScanError.invalidBoard }
        if try BoardStorage.isPageSet(data) { pageSet = try BoardStorage.decodePageSet(data) }
        else { board = try BoardStorage.decode(data) }
    }

    var title: String { pageSet?.title ?? board?.title ?? "Choice board" }
    var summary: String {
        if let pageSet { return "\(pageSet.pages.count) pages" }
        if let board { return "\(board.cards.filter { $0.included && $0.isEmpty != true }.count) cards" }
        return "Board"
    }

    func renamed(_ title: String) -> Self {
        var result = self
        result.board?.title = title
        result.pageSet?.title = title
        return result
    }

    func encoded() throws -> Data {
        let data: Data
        if let pageSet {
            try pageSet.validate()
            data = try JSONEncoder().encode(ScannerArchive(pageSet: pageSet))
        } else if let board {
            try board.validate()
            data = try JSONEncoder().encode(board)
        } else { throw ScanError.invalidBoard }
        guard data.count <= 80_000_000 else { throw ScanError.oversizedFile }
        return data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try encoded())
    }
}
