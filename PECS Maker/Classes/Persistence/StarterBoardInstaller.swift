import Foundation

/// Copies editable samples once per document library, retaining user edits and deletions.
enum StarterBoardInstaller {
    static func orderedDirectoryNames(from sourceRoot: URL, language: String) throws -> [String] {
        let url = sourceRoot.appendingPathComponent(language).appendingPathComponent("order.json")
        return try JSONDecoder().decode([String].self, from: Data(contentsOf: url))
    }

    private struct Installation: Codable {
        let language: String
        var installed: Set<String>
    }

    static func missingBoards(from sourceRoot: URL, into documents: URL, language: String) throws -> [URL] {
        let locale = language.lowercased().hasPrefix("es") ? "es" : "en"
        return try orderedDirectoryNames(from: sourceRoot, language: locale).compactMap { name in
            let destination = documents.appendingPathComponent("topics").appendingPathComponent(name)
            guard !FileManager.default.fileExists(atPath: destination.path) else { return nil }
            return sourceRoot.appendingPathComponent(locale).appendingPathComponent("topics").appendingPathComponent(name)
        }
    }

    /// Explicit user action ignores the first-launch ledger, but never replaces an existing board.
    static func restoreMissing(from sourceRoot: URL, into documents: URL, language: String) throws -> [URL] {
        let boards = try missingBoards(from: sourceRoot, into: documents, language: language)
        let destination = documents.appendingPathComponent("topics", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        var restored: [URL] = []
        for board in boards {
            let target = destination.appendingPathComponent(board.lastPathComponent)
            let staging = documents.appendingPathComponent(".starter-\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: staging) }
            try FileManager.default.copyItem(at: board, to: staging)
            try FileManager.default.moveItem(at: staging, to: target)
            restored.append(target)
        }
        return restored
    }

    static func install(from sourceRoot: URL, into documents: URL, language: String,
                        fileManager: FileManager = .default) throws {
        let marker = documents.appendingPathComponent(".starter-boards-v1.json")
        var installation: Installation
        if fileManager.fileExists(atPath: marker.path) {
            installation = try JSONDecoder().decode(Installation.self, from: Data(contentsOf: marker))
        } else {
            installation = Installation(language: language.lowercased().hasPrefix("es") ? "es" : "en",
                                        installed: [])
        }
        let source = sourceRoot.appendingPathComponent(installation.language).appendingPathComponent("topics")
        let order = try orderedDirectoryNames(from: sourceRoot, language: installation.language)
        let positions = Dictionary(order.enumerated().map { ($1, $0) }, uniquingKeysWith: min)
        let boards = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: [.isDirectoryKey])
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .sorted {
                let lhs = positions[$0.lastPathComponent] ?? .max
                let rhs = positions[$1.lastPathComponent] ?? .max
                return lhs == rhs ? $0.lastPathComponent < $1.lastPathComponent : lhs < rhs
            }
        let destination = documents.appendingPathComponent("topics", isDirectory: true)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        for board in boards {
            let name = board.lastPathComponent
            guard !installation.installed.contains(name) else { continue }
            let target = destination.appendingPathComponent(name, isDirectory: true)
            if !fileManager.fileExists(atPath: target.path) {
                // Stage outside topics so an interrupted copy cannot become a partial board.
                let staging = documents.appendingPathComponent(".starter-\(UUID().uuidString)")
                defer { try? fileManager.removeItem(at: staging) }
                try fileManager.copyItem(at: board, to: staging)
                try fileManager.moveItem(at: staging, to: target)
            }
            installation.installed.insert(name)
            try JSONEncoder().encode(installation).write(to: marker, options: .atomic)
        }
    }
}
