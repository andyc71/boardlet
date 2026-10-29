import Foundation

/// Owns all library filesystem access. Each operation is synchronous on this actor,
/// so a save cannot interleave with another save, rename, recovery or deletion.
actor BoardLibrary {
    let root: URL
    private var recoveredRevisions: [UUID: LibraryRevision] = [:]
    private let files = FileManager.default

    init(root: URL) { self.root = root }

    func entries(deleted: Bool = false) throws -> [LibraryEntry] {
        let directory = root.appendingPathComponent(deleted ? "Deleted" : "Boards")
        guard files.fileExists(atPath: directory.path) else { return [] }
        return try files.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .compactMap { folder in
                guard let id = UUID(uuidString: folder.lastPathComponent) else { return nil }
                let revision = try? record(in: folder).current
                return LibraryEntry(id: id, title: revision?.title ?? "Board needs recovery",
                                    updatedAt: revision?.updatedAt ?? .distantPast,
                                    detail: revision?.detail ?? "Open to check the saved data", isDeleted: deleted)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    @discardableResult
    func save(_ document: BoardDocument, id: UUID) throws -> LibraryEntry {
        try Task.checkCancellation()
        let data = try document.encoded()
        let folder = folder(id)
        let folderExisted = files.fileExists(atPath: folder.path)
        try files.createDirectory(at: folder, withIntermediateDirectories: true)
        let existing = try? record(in: folder)
        let previous = recoveredRevisions[id] ?? existing?.current
        let revision = LibraryRevision(id: UUID(), title: String(document.title.prefix(500)), updatedAt: Date(), detail: document.summary)
        let target = folder.appendingPathComponent(revision.id.uuidString + ".boardscan")
        do {
            try data.write(to: target, options: .atomic)
            // Cancellation before the index commit leaves the preceding revision authoritative.
            try Task.checkCancellation()
            if let existing {
                try JSONEncoder().encode(existing).write(to: folder.appendingPathComponent("backup.json"), options: .atomic)
            }
            let updated = LibraryRecord(current: revision, previous: previous)
            try JSONEncoder().encode(updated).write(to: folder.appendingPathComponent("index.json"), options: .atomic)
        } catch {
            try? files.removeItem(at: folderExisted ? target : folder)
            throw error
        }
        recoveredRevisions[id] = nil
        // Keep revisions referenced by either index. Cleanup failure cannot invalidate a committed save.
        let keep = Set([revision.id, previous?.id, existing?.current.id, existing?.previous?.id].compactMap { $0 })
        if let children = try? files.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            for child in children where child.pathExtension == "boardscan" {
                if let revisionID = UUID(uuidString: child.deletingPathExtension().lastPathComponent), !keep.contains(revisionID) {
                    try? files.removeItem(at: child)
                }
            }
        }
        return LibraryEntry(id: id, title: revision.title, updatedAt: revision.updatedAt, detail: revision.detail)
    }

    func load(_ id: UUID) throws -> LibraryLoad {
        try Task.checkCancellation()
        let directory = folder(id)
        let primary = try? readRecord(directory.appendingPathComponent("index.json"))
        let backup = try? readRecord(directory.appendingPathComponent("backup.json"))
        let candidates = [primary?.current, primary?.previous, backup?.current, backup?.previous].compactMap { $0 }
        var checked = Set<UUID>()
        for revision in candidates where checked.insert(revision.id).inserted {
            do {
                let data = try BoardStorage.readBounded(directory.appendingPathComponent(revision.id.uuidString + ".boardscan"))
                let document: BoardDocument
                if try BoardStorage.isPageSet(data) { document = BoardDocument(pageSet: try BoardStorage.decodePageSet(data)) }
                else { document = BoardDocument(board: try BoardStorage.decode(data)) }
                try Task.checkCancellation()
                let recovered = revision.id != primary?.current.id
                if recovered { recoveredRevisions[id] = revision }
                return LibraryLoad(document: document, recovered: recovered)
            } catch is CancellationError { throw CancellationError() }
            catch { continue }
        }
        throw BoardLibraryError.unreadable
    }

    func select(_ id: UUID?) throws {
        try files.createDirectory(at: root, withIntermediateDirectories: true)
        try JSONEncoder().encode(id).write(to: root.appendingPathComponent("selection.json"), options: .atomic)
    }

    func hasSavedSelection() -> Bool {
        files.fileExists(atPath: root.appendingPathComponent("selection.json").path)
    }

    func selectedID() throws -> UUID? {
        let url = root.appendingPathComponent("selection.json")
        guard files.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(UUID?.self, from: Data(contentsOf: url))
    }

    func delete(_ id: UUID) throws {
        let wasSelected = (try? selectedID()) == id
        if wasSelected { try select(nil) }
        do { try move(id, toDeleted: true) }
        catch { if wasSelected { try? select(id) }; throw error }
        recoveredRevisions[id] = nil
    }

    func restore(_ id: UUID) throws { try move(id, toDeleted: false) }

    private func move(_ id: UUID, toDeleted: Bool) throws {
        try Task.checkCancellation()
        let source = folder(id, deleted: !toDeleted)
        let destination = folder(id, deleted: toDeleted)
        try files.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try files.moveItem(at: source, to: destination)
    }

    private func folder(_ id: UUID, deleted: Bool = false) -> URL {
        root.appendingPathComponent(deleted ? "Deleted" : "Boards").appendingPathComponent(id.uuidString)
    }

    private func readRecord(_ url: URL) throws -> LibraryRecord {
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 1_000_000 else { throw BoardLibraryError.unreadable }
        return try JSONDecoder().decode(LibraryRecord.self, from: Data(contentsOf: url))
    }

    private func record(in folder: URL) throws -> LibraryRecord {
        do { return try readRecord(folder.appendingPathComponent("index.json")) }
        catch { return try readRecord(folder.appendingPathComponent("backup.json")) }
    }
}

