import Foundation
import CryptoKit
import BoardLibrary

/// A catalog identity is independent of the language used at installation.
enum StarterBoardInstaller {
    struct LegacyBoard: Decodable {
        struct Card: Decodable {
            var key: String
            var title: String
            var imageSHA256: String
        }
        var canonicalDirectory: String
        var language: String
        var title: String
        var cards: [String: Card]
    }

    static func legacyBoards(from root: URL) throws -> [String: LegacyBoard] {
        try JSONDecoder().decode([String: LegacyBoard].self, from: Data(contentsOf: root.appendingPathComponent("legacy.json")))
    }

    static func orderedDirectoryNames(from sourceRoot: URL, language: String) throws -> [String] {
        try JSONDecoder().decode([String].self, from: Data(contentsOf: sourceRoot.appendingPathComponent("order.json")))
    }

    private struct Installation: Codable {
        var language: String
        var installed: Set<String>
    }

    static func missingBoards(from sourceRoot: URL, into documents: URL, language: String) throws -> [URL] {
        let aliases = try legacyBoards(from: sourceRoot)
        let topics = documents.appendingPathComponent("topics")
        return try orderedDirectoryNames(from: sourceRoot, language: language).compactMap { name in
            let identities = [name] + aliases.filter { $0.value.canonicalDirectory == name }.map(\.key)
            // An unreadable folder is not an installed board: the library cannot
            // display it, and its presence must not prevent explicit recovery.
            guard !identities.contains(where: {
                (try? BoardDocumentReader.read(topics.appendingPathComponent($0), relativePath: $0)) != nil
            }) else { return nil }
            return sourceRoot.appendingPathComponent("topics").appendingPathComponent(name)
        }
    }

    private static func copy(_ board: URL, into documents: URL, fileManager: FileManager) throws -> URL {
        let topics = documents.appendingPathComponent("topics", isDirectory: true)
        try fileManager.createDirectory(at: topics, withIntermediateDirectories: true)
        let target = topics.appendingPathComponent(board.lastPathComponent)
        let staging = documents.appendingPathComponent(".starter-\(UUID().uuidString)")
        defer { try? fileManager.removeItem(at: staging) }
        try fileManager.copyItem(at: board, to: staging)
        try fileManager.moveItem(at: staging, to: target)
        return target
    }

    /// Explicit restoration ignores deletion history and preserves readable copies.
    /// Unreadable copies are retained outside the topic library for recovery.
    static func restoreMissing(from sourceRoot: URL, into documents: URL, language: String) throws -> [URL] {
        let fm = FileManager.default
        let aliases = try legacyBoards(from: sourceRoot)
        return try missingBoards(from: sourceRoot, into: documents, language: language).map { board in
            // Validate the bundled replacement before moving any existing files.
            _ = try BoardDocumentReader.read(board, relativePath: board.lastPathComponent)
            let name = board.lastPathComponent
            let identities = Set([name] + aliases.filter { $0.value.canonicalDirectory == name }.map(\.key))
            let recovery = documents.appendingPathComponent(".starter-board-recovery/\(UUID().uuidString)")
            var moved: [(original: URL, backup: URL)] = []
            do {
                for identity in identities.sorted() {
                    let original = documents.appendingPathComponent("topics").appendingPathComponent(identity)
                    guard fm.fileExists(atPath: original.path) else { continue }
                    try fm.createDirectory(at: recovery, withIntermediateDirectories: true)
                    let backup = recovery.appendingPathComponent(identity)
                    try fm.moveItem(at: original, to: backup)
                    moved.append((original, backup))
                }
                let restored = try copy(board, into: documents, fileManager: fm)
                return restored
            } catch {
                // A failed copy must leave the previous library in place.
                for entry in moved.reversed() {
                    if !fm.fileExists(atPath: entry.original.path) {
                        try fm.moveItem(at: entry.backup, to: entry.original)
                    }
                }
                throw error
            }
        }
    }

    static func install(from sourceRoot: URL, into documents: URL, language: String,
                        fileManager: FileManager = .default) throws {
        let marker = documents.appendingPathComponent(".starter-boards-v1.json")
        let aliases = try legacyBoards(from: sourceRoot)
        var installation = fileManager.fileExists(atPath: marker.path)
            ? try JSONDecoder().decode(Installation.self, from: Data(contentsOf: marker))
            : Installation(language: language, installed: [])
        // Preserve old ledger entries, including deleted boards; add canonical identities.
        installation.installed.formUnion(installation.installed.compactMap { aliases[$0]?.canonicalDirectory })
        let missing = Set(try missingBoards(from: sourceRoot, into: documents, language: language).map(\.lastPathComponent))
        try fileManager.createDirectory(at: documents, withIntermediateDirectories: true)
        for name in try orderedDirectoryNames(from: sourceRoot, language: language) {
            guard !installation.installed.contains(name) else { continue }
            let identities = [name] + aliases.filter { $0.value.canonicalDirectory == name }.map(\.key)
            let hasExistingCopy = identities.contains {
                fileManager.fileExists(atPath: documents.appendingPathComponent("topics").appendingPathComponent($0).path)
            }
            if missing.contains(name) && !hasExistingCopy {
                _ = try copy(sourceRoot.appendingPathComponent("topics").appendingPathComponent(name), into: documents, fileManager: fileManager)
            }
            installation.installed.insert(name)
            try JSONEncoder().encode(installation).write(to: marker, options: .atomic)
        }
        try JSONEncoder().encode(installation).write(to: marker, options: .atomic)
    }

    /// Only unchanged, identity-and-content-matched fields gain bundled translations.
    /// Existing structure and copies are never merged, replaced or expanded.
    static func upgradeLegacy(_ board: PECSRepo, from root: URL) throws {
        let aliases = try legacyBoards(from: root)
        guard let original = aliases[board.docDir.lastPathComponent] else { return }
        let catalog = try BoardDocumentReader.read(root.appendingPathComponent("topics").appendingPathComponent(original.canonicalDirectory), relativePath: original.canonicalDirectory)
        if board.topicName == original.title {
            var title = BoardText(key: catalog.title.key ?? "board.title", sourceLanguage: original.language, text: nil)
            title.values = catalog.title.values
            board.localization?.title = title
        }
        for card in board.photos.photoItems {
            guard let old = original.cards[card.itemID.uuidString], card.title == old.title,
                  let imageURL = card.imageURL,
                  let data = try? Data(contentsOf: imageURL),
                  SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == old.imageSHA256,
                  let projected = catalog.cards.first(where: { $0.text.key == old.key })?.text
            else { continue }
            var text = BoardText(key: card.itemID.uuidString, sourceLanguage: original.language, text: nil)
            text.values = projected.values
            card.localizedTitle = text
        }
        board.resolveLanguage()
    }
}
