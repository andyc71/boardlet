import Foundation

struct Library: Codable, Equatable, Sendable {
    var schemaVersion = 1
    var boards: [Board] = []
    var defaults = AppPreferences()

    func validated() throws -> Library {
        guard schemaVersion == 1 else { throw StorageError.unsupportedVersion }
        guard Set(boards.map(\.id)).count == boards.count else { throw StorageError.invalidData }
        for board in boards {
            guard Set(board.cards.map(\.id)).count == board.cards.count,
                  (1...12).contains(board.print.columns), (1...12).contains(board.print.rows),
                  (1...6).contains(board.communication.columns), (1...8).contains(board.communication.rows),
                  (0...0.3).contains(board.print.marginFraction),
                  (0.05...0.6).contains(board.print.labelFraction),
                  (0...0.4).contains(board.print.titleFraction),
                  (0...12).contains(board.print.borderWidth), (0...12).contains(board.print.categoryBorderWidth),
                  board.print.fixedCardAspectRatio == nil || (0.05...20).contains(board.print.fixedCardAspectRatio ?? 1) else { throw StorageError.invalidData }
            for path in board.cards.flatMap({ [$0.image, $0.originalImage, $0.recording] }) + [board.cover] {
                if let path { try AssetPath.validate(path) }
            }
        }
        return self
    }
}

struct AppPreferences: Codable, Equatable, Sendable {
    var communication = CommunicationSettings()
    var print = PrintSettings()
    var highContrast = false
}

enum StorageError: LocalizedError {
    case unsupportedVersion, invalidData, unsafePath, missingAsset(String), corruptLibrary
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: L("This library was created by a newer version of Boardlet.")
        case .invalidData: L("The board data is invalid. The original files have been kept.")
        case .unsafePath: L("A media path is unsafe. Import was cancelled.")
        case .missingAsset(let name): L("A media file is missing or damaged:") + " " + name
        case .corruptLibrary: L("The library could not be read. Restore the previous save or import a backup.")
        }
    }
}

enum AssetPath {
    static func validate(_ path: String) throws {
        guard !path.isEmpty, path == URL(fileURLWithPath: path).lastPathComponent,
              path != ".", path != "..", !path.contains("\\") else { throw StorageError.unsafePath }
    }
}
