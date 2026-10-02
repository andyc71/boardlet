import Foundation
import CryptoKit

protocol LibraryStorage: Sendable {
    func load() async throws -> Library
    func save(_ library: Library, revision: Int) async throws
    func storeAsset(_ data: Data, extension ext: String) async throws -> String
    func restoreBackup() async throws -> Library
}

/// Immutable media + an atomically replaced manifest is the transaction boundary.
/// Interrupted imports can leave unreferenced media, never partially visible boards.
actor LibraryDisk: LibraryStorage {
    nonisolated let root: URL
    private var savedRevision = -1
    private let fm = FileManager.default
    nonisolated var mediaURL: URL { root.appendingPathComponent("Media", isDirectory: true) }
    private var manifest: URL { root.appendingPathComponent("library.json") }
    private var backup: URL { root.appendingPathComponent("library.previous.json") }

    init(root: URL) { self.root = root }

    func load() throws -> Library {
        guard fm.fileExists(atPath: manifest.path) else { return Library() }
        return try JSONDecoder().decode(Library.self, from: Data(contentsOf: manifest)).validated()
    }

    func save(_ library: Library, revision: Int) throws {
        guard revision > savedRevision else { return }
        let validated = try library.validated()
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(validated)
        if fm.fileExists(atPath: manifest.path) {
            let prior = try Data(contentsOf: manifest)
            _ = try JSONDecoder().decode(Library.self, from: prior).validated()
            try prior.write(to: backup, options: .atomic)
        }
        try data.write(to: manifest, options: .atomic)
        savedRevision = revision
    }

    func storeAsset(_ data: Data, extension ext: String) throws -> String {
        guard !data.isEmpty, ["png", "jpg", "jpeg", "m4a", "caf", "wav", "aiff", "mp3"].contains(ext.lowercased()) else {
            throw StorageError.invalidData
        }
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let name = digest + "." + ext.lowercased()
        try fm.createDirectory(at: mediaURL, withIntermediateDirectories: true)
        let url = mediaURL.appendingPathComponent(name)
        if !fm.fileExists(atPath: url.path) { try data.write(to: url, options: .atomic) }
        return name
    }

    func restoreBackup() throws -> Library {
        let data = try Data(contentsOf: backup)
        let restored = try JSONDecoder().decode(Library.self, from: data).validated()
        // Retain the unreadable current manifest for manual recovery.
        if fm.fileExists(atPath: manifest.path) {
            let evidence = root.appendingPathComponent("recovery-\(UUID().uuidString).json")
            try fm.copyItem(at: manifest, to: evidence)
        }
        try data.write(to: manifest, options: .atomic)
        savedRevision = -1
        return restored
    }
}
