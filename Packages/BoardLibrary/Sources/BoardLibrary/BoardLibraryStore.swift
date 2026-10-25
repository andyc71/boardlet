import Foundation
import CryptoKit

public struct LibrarySnapshot: Sendable {
    public var boards: [BoardSummary]
    public var diagnostics: [String]
    public var indexedDocuments: Int
    public var generation: UInt64 = 0
    public var isComplete = false
}

/// Serial actor owns filesystem mutations and SQLite; blocking work never runs on MainActor.
public actor BoardLibraryStore {
    public let root: URL
    private let catalog: BoardCatalog
    private let catalogGeneration: CatalogGeneration
    private var rebuildPending: Bool
    private nonisolated let queryConnection: BoardSearchConnection
    private var needsLanguageProjection = false
    private var language: String
    private let legacyCatalog: URL?
    private let recoveryTables: [String: Data]
    private var summaries: [BoardSummary] = []
    private var diagnostics: [String] = []
    private var generation: UInt64 = 0
    private func snapshot(_ boards: [BoardSummary], indexed: Int) -> LibrarySnapshot {
        generation += 1
        var result = LibrarySnapshot(boards: boards,diagnostics:diagnostics,indexedDocuments:indexed)
        result.generation = generation
        result.isComplete = !rebuildPending && diagnostics.isEmpty
        return result
    }
    public init(root: URL, database: URL, language: String, legacyCatalog: URL? = nil, recoveryTables: [Data] = []) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        self.root = root.resolvingSymlinksInPath().standardizedFileURL; self.language = language; self.legacyCatalog = legacyCatalog
        self.recoveryTables = Dictionary(recoveryTables.map { data in
            ("strings-" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() + ".json", data)
        }, uniquingKeysWith: { first, _ in first })
        catalogGeneration = try CatalogGeneration(base: database)
        rebuildPending = catalogGeneration.needsPromotion
        catalog = try BoardCatalog(url: catalogGeneration.database)
        queryConnection = try BoardSearchConnection(database: catalogGeneration.database)
        needsLanguageProjection = try catalog.rows("SELECT value FROM settings WHERE key='language'").first?.first != language
    }
    public func reconcile(language newLanguage: String? = nil, progress: (@Sendable (LibrarySnapshot) -> Void)? = nil) throws -> LibrarySnapshot {
        let languageChanged = needsLanguageProjection || (newLanguage != nil && newLanguage != language)
        if let newLanguage { language = newLanguage }
        if languageChanged { needsLanguageProjection = true; try catalog.project(language: language); needsLanguageProjection = false }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        diagnostics = []
        do { try recover() } catch { diagnostics.append("Interrupted operation: \(error.localizedDescription)") }
        var found = Set<UUID>(); var paths = Set<String>(); var complete = true; var indexed = 0
        let states = Dictionary(try catalog.rows("SELECT path,files,signature FROM index_state").map { ($0[0], ($0[1],$0[2])) }, uniquingKeysWith: { first, _ in first })
        func signature(_ files: [String], _ directory: URL) throws -> String {
            try files.map { path in
                let values = try DocumentPaths.owned(path,by:directory).resourceValues(forKeys: [.contentModificationDateKey,.fileSizeKey])
                return "\(path):\(values.contentModificationDate?.timeIntervalSince1970 ?? 0):\(values.fileSize ?? 0)"
            }.joined(separator: "|")
        }
        let existingRows = try catalog.rows("SELECT id,fingerprint,path FROM boards")
        let existing = Dictionary(existingRows.map { ($0[0],$0[1]) }, uniquingKeysWith: { first, _ in first })
        let existingPaths = Dictionary(existingRows.map { ($0[0],$0[2]) }, uniquingKeysWith: { first, _ in first })
        var next: [BoardSummary] = []
        func walk(_ container: URL, parent: UUID?, order: [UUID]) throws {
            let directories: [URL]
            do { directories = try FileManager.default.contentsOfDirectory(at: container, includingPropertiesForKeys: [.isDirectoryKey,.isSymbolicLinkKey], options: [.skipsHiddenFiles]).sorted { $0.path < $1.path } }
            catch { complete = false; diagnostics.append("Unavailable: \(container.lastPathComponent): \(error.localizedDescription)"); return }
            for directory in directories {
                try Task.checkCancellation()
                let properties = try directory.resourceValues(forKeys: [.isDirectoryKey,.isSymbolicLinkKey])
                guard properties.isDirectory == true, properties.isSymbolicLink != true else { continue }
                let canonicalDirectory = directory.resolvingSymlinksInPath().standardizedFileURL
                let path = String(canonicalDirectory.path.dropFirst(root.resolvingSymlinksInPath().standardizedFileURL.path.count + 1))
                paths.insert(path)
                do {
                    let doc: BoardDocument
                    // A committed save may replace and remove an old string table or
                    // legacy image. A failed cached probe requires reading the current
                    // manifest; it does not establish that the board is unavailable.
                    if let state = states[path], let files = try? JSONDecoder().decode([String].self, from: Data(state.0.utf8)),
                       let currentSignature = try? signature(files,directory), currentSignature == state.1,
                       let stored = try catalog.rows("SELECT document FROM boards WHERE path=?", [path]).first?.first {
                        doc = try JSONDecoder().decode(BoardDocument.self, from: Data(stored.utf8))
                    } else {
                        do { doc = try BoardDocumentReader.read(directory, relativePath: path, legacyCatalog: legacyCatalog) }
                        catch {
                            guard try restoreKnownMissingTables(in: directory) else { throw error }
                            doc = try BoardDocumentReader.read(directory, relativePath: path, legacyCatalog: legacyCatalog)
                        }
                    }
                    guard found.insert(doc.id).inserted else {
                        diagnostics.append("Duplicate identity isolated: \(path)"); complete = false
                        try catalog.execute("INSERT OR REPLACE INTO unavailable VALUES(?)", [doc.id.uuidString])
                        next.removeAll { $0.id == doc.id }; continue
                    }
                    try catalog.execute("DELETE FROM unavailable WHERE board=?", [doc.id.uuidString])
                    if existing[doc.id.uuidString] != doc.fingerprint || existingPaths[doc.id.uuidString] != path {
                        try catalog.replace(doc, path: path, parent: parent, language: language); indexed += 1
                    } else {
                        try catalog.execute("UPDATE boards SET path=?,parent=? WHERE id=?", [path,parent?.uuidString ?? "",doc.id.uuidString])
                    }
                    let files = ["index.json"] + doc.resourceTables
                    let encodedFiles = String(decoding: try JSONEncoder().encode(files), as: UTF8.self)
                    try catalog.execute("INSERT OR REPLACE INTO index_state VALUES(?,?,?)", [path,encodedFiles,try signature(files,directory)])
                    let marker = directory.appendingPathComponent(".index-pending")
                    if FileManager.default.fileExists(atPath: marker.path) { try FileManager.default.removeItem(at: marker) }
                    let selected = doc.language ?? language
                    let cover = LibraryText.candidates(selected).compactMap { doc.covers[$0] }.first ?? doc.cover
                    next.append(BoardSummary(id: doc.id,parentID: parent,relativePath: path,title: doc.title.resolve(selected).0,cover: cover,childCount: 0,fingerprint: doc.fingerprint))
                    if next.count % 25 == 0 { progress?(snapshot(next,indexed:indexed)) }
                    let childRoot = directory.appendingPathComponent("children")
                    if FileManager.default.fileExists(atPath: childRoot.path) {
                        guard try childRoot.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else { throw LibraryError.invalid("Child namespace cannot be a symbolic link") }
                        _ = try DocumentPaths.owned("children", by: directory)
                        try walk(childRoot, parent: doc.id, order: doc.children)
                    }
                } catch is CancellationError { throw CancellationError() }
                catch {
                    diagnostics.append("\(path): \(error.localizedDescription)"); complete = false
                    try catalog.execute("INSERT OR REPLACE INTO unavailable SELECT id FROM boards WHERE path=? OR substr(path,1,?)=?", [path,String(path.count+1),path+"/"])
                }
            }
            let positions = Dictionary(order.enumerated().map { ($1,$0) }, uniquingKeysWith: min)
            let children = next.filter { $0.parentID == parent }.sorted {
                let a = positions[$0.id] ?? Int.max, b = positions[$1.id] ?? Int.max
                return a == b ? $0.id.uuidString < $1.id.uuidString : a < b
            }
            next.removeAll { $0.parentID == parent }; next.append(contentsOf: children)
        }
        try walk(root, parent: nil, order: [])
        if complete {
            for row in try catalog.rows("SELECT id FROM boards") where !found.contains(UUID(uuidString: row[0])!) { try catalog.remove(row[0]) }
        }
        try catalog.execute("DELETE FROM index_state WHERE path NOT IN (SELECT path FROM boards)")
        // A collision or unreadable ancestor isolates its entire subtree, including
        // descendants already visited before the second colliding root was found.
        try catalog.execute("WITH RECURSIVE hidden(id) AS (SELECT board FROM unavailable UNION SELECT b.id FROM boards b JOIN hidden h ON b.parent=h.id) INSERT OR IGNORE INTO unavailable SELECT id FROM hidden")
        let unavailable = Set(try catalog.rows("SELECT board FROM unavailable").compactMap { UUID(uuidString: $0[0]) })
        next.removeAll { unavailable.contains($0.id) }
        for i in next.indices { next[i].childCount = next.filter { $0.parentID == next[i].id }.count }
        summaries = next
        if rebuildPending && complete && diagnostics.isEmpty {
            try catalogGeneration.promote()
            rebuildPending = false
        }
        return snapshot(next,indexed:indexed)
    }
    /// Restore only exact, content-addressed bytes supplied by the app. Never
    /// substitute a default for an unknown translation or overwrite an existing file.
    private func restoreKnownMissingTables(in directory: URL) throws -> Bool {
        guard !recoveryTables.isEmpty,
              let json = try JSONSerialization.jsonObject(with: Data(contentsOf: DocumentPaths.owned("index.json", by: directory))) as? [String: Any],
              let version = json["version"] as? Int, (1...3).contains(version),
              let localization = json["localization"] as? [String: Any],
              let languages = localization["languages"] as? [String],
              let files = localization["tableFiles"] as? [String: String] else { return false }
        var restored = false
        for language in languages {
            guard let filename = files[language], let bytes = recoveryTables[filename] else { continue }
            let destination = try DocumentPaths.owned("locales/\(language)/\(filename)", by: directory)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            let temporary = destination.deletingLastPathComponent().appendingPathComponent(".recovery-\(UUID().uuidString)")
            try bytes.write(to: temporary, options: .atomic)
            defer { try? FileManager.default.removeItem(at: temporary) }
            // Linking publishes a complete file and fails if another writer won.
            // It cannot replace a file between our existence check and publication.
            do {
                try FileManager.default.linkItem(at: temporary, to: destination)
                restored = true
            } catch {
                if !FileManager.default.fileExists(atPath: destination.path) { throw error }
            }
        }
        return restored
    }
    /// App saves update one committed document. Foreground reconciliation handles external edits.
    public func updateBoard(at directory: URL) throws -> LibrarySnapshot {
        let directory = directory.resolvingSymlinksInPath().standardizedFileURL
        guard directory.path.hasPrefix(root.path + "/") else { throw LibraryError.invalid("Board is outside the library") }
        let path = String(directory.path.dropFirst(root.path.count+1))
        let doc = try BoardDocumentReader.read(directory,relativePath:path,legacyCatalog:legacyCatalog)
        if let existingPath = try catalog.rows("SELECT path FROM boards WHERE id=?", [doc.id.uuidString]).first?.first, existingPath != path { throw LibraryError.invalid("Duplicate board identity") }
        let parentPath = directory.deletingLastPathComponent().deletingLastPathComponent().path
        let parent: UUID?
        if directory.deletingLastPathComponent().lastPathComponent == "children" {
            parent = try catalog.rows("SELECT id FROM boards WHERE path=?", [String(parentPath.dropFirst(root.path.count+1))]).first?.first.flatMap(UUID.init(uuidString:))
            guard parent != nil else { return try reconcile() }
        } else { parent = nil }
        try catalog.replace(doc,path:path,parent:parent,language:language)
        try? FileManager.default.removeItem(at:directory.appendingPathComponent(".index-pending"))
        let selected = doc.language ?? language
        let cover = LibraryText.candidates(selected).compactMap { doc.covers[$0] }.first ?? doc.cover
        let summary = BoardSummary(id:doc.id,parentID:parent,relativePath:path,title:doc.title.resolve(selected).0,cover:cover,childCount:summaries.filter { $0.parentID == doc.id }.count,fingerprint:doc.fingerprint)
        summaries.removeAll { $0.relativePath == path && $0.id != doc.id }
        if let index = summaries.firstIndex(where: { $0.id == doc.id }) { summaries[index] = summary } else { summaries.append(summary) }
        let positions = Dictionary(doc.children.enumerated().map { ($1,$0) },uniquingKeysWith:min)
        let children = summaries.filter { $0.parentID == doc.id }.sorted {
            let a = positions[$0.id] ?? Int.max, b = positions[$1.id] ?? Int.max
            return a == b ? $0.id.uuidString < $1.id.uuidString : a < b
        }
        summaries.removeAll { $0.parentID == doc.id }; summaries += children
        return snapshot(summaries,indexed:1)
    }
    public nonisolated func search(_ query: String, scope: UUID? = nil, allLanguages: Bool = false, offset: Int = 0) async throws -> [LibrarySearchResult] {
        try Task.checkCancellation()
        return try await queryConnection.search(query, scope: scope, allLanguages: allLanguages, offset: offset)
    }
    public func location(_ id: UUID) throws -> URL {
        guard let path = try catalog.rows("SELECT path FROM boards WHERE id=? AND id NOT IN (SELECT board FROM unavailable)", [id.uuidString]).first?.first else { throw LibraryError.invalid("Board is no longer available") }
        return try DocumentPaths.owned(path, by: root)
    }
    public func reorder(parent: UUID, ids: [UUID]) throws {
        let directory = try location(parent)
        try updateIndex(directory) { $0["hierarchy"] = ["childOrder": ids.map(\.uuidString)] }
        _ = try reconcile()
    }
    private func updateIndex(_ directory: URL, edit: (inout [String: Any]) throws -> Void) throws {
        let file = try DocumentPaths.owned("index.json", by: directory)
        guard var json = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any] else {
            throw LibraryError.invalid("Board manifest changed during the operation")
        }
        if json["id"] == nil { json["id"] = DocumentPaths.provisionalID(String(directory.path.dropFirst(root.path.count + 1))).uuidString }
        try edit(&json); json["version"] = 3; json["contentRevision"] = UUID().uuidString
        try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]).write(to: file, options: .atomic)
    }
    private struct MoveJournal: Codable { var source: String; var destination: String; var id: UUID?; var oldParent: String?; var newParent: String? }
    private func recover() throws {
        let journals = root.appendingPathComponent(".operations")
        guard FileManager.default.fileExists(atPath: journals.path) else { return }
        for file in try FileManager.default.contentsOfDirectory(at: journals, includingPropertiesForKeys: nil) where file.pathExtension == "json" {
            let operation = try JSONDecoder().decode(MoveJournal.self, from: Data(contentsOf: file))
            let source = try DocumentPaths.owned(operation.source, by: root), destination = try DocumentPaths.owned(operation.destination, by: root)
            guard !(FileManager.default.fileExists(atPath: source.path) && FileManager.default.fileExists(atPath: destination.path)) else {
                throw LibraryError.invalid("Interrupted move destination is occupied; both boards were preserved")
            }
            if FileManager.default.fileExists(atPath: source.path), !FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: source, to: destination)
            }
            guard FileManager.default.fileExists(atPath: destination.path) else { throw LibraryError.invalid("Interrupted move needs recovery") }
            if let id = operation.id {
                let document = try BoardDocumentReader.read(destination, relativePath: operation.destination)
                guard document.id == id else { throw LibraryError.invalid("Interrupted move destination has a different board identity") }
                for (path, adding) in [(operation.oldParent,false),(operation.newParent,true)] {
                    if let path {
                        let parent = try DocumentPaths.owned(path,by:root)
                        try updateIndex(parent) { json in
                            var order = (json["hierarchy"] as? [String: Any])?["childOrder"] as? [String] ?? []
                            order.removeAll { $0 == id.uuidString }
                            if adding { order.append(id.uuidString) }
                            json["hierarchy"] = ["childOrder": order]
                        }
                    }
                }
            }
            try FileManager.default.removeItem(at: file)
        }
    }
    public func move(_ id: UUID, parent: UUID?) throws {
        let source = try location(id)
        let parentURL = try parent.map(location)
        if let parentURL, parentURL == source || parentURL.path.hasPrefix(source.path + "/") { throw LibraryError.invalid("A board cannot be moved into its descendants") }
        let destination = (parentURL?.appendingPathComponent("children") ?? root).appendingPathComponent(id.uuidString)
        guard source != destination else { return }
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw LibraryError.invalid("Destination already exists") }
        // Persist provisional identities before changing their location.
        func persistIDs(_ directory: URL) throws {
            let properties = try directory.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            guard properties.isDirectory == true, properties.isSymbolicLink != true,
                  directory.resolvingSymlinksInPath().path.hasPrefix(root.path + "/") else {
                throw LibraryError.invalid("Cannot move a subtree containing symbolic links or invalid children")
            }
            let relative = String(directory.path.dropFirst(root.path.count+1))
            let doc = try BoardDocumentReader.read(directory,relativePath:relative)
            try updateIndex(directory) { $0["id"] = doc.id.uuidString }
            let children = directory.appendingPathComponent("children")
            if FileManager.default.fileExists(atPath: children.path) {
                for child in try FileManager.default.contentsOfDirectory(at: children,includingPropertiesForKeys:nil,options:[.skipsHiddenFiles]) { try persistIDs(child) }
            }
        }
        try persistIDs(source)
        let journal = root.appendingPathComponent(".operations/\(UUID().uuidString).json")
        try FileManager.default.createDirectory(at: journal.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(MoveJournal(source: String(source.path.dropFirst(root.path.count+1)),destination: String(destination.path.dropFirst(root.path.count+1)), id: id, oldParent: source.deletingLastPathComponent().lastPathComponent == "children" ? String(source.deletingLastPathComponent().deletingLastPathComponent().path.dropFirst(root.path.count+1)) : nil, newParent: parentURL.map { String($0.path.dropFirst(root.path.count+1)) })).write(to: journal, options: .atomic)
        try recover(); _ = try reconcile()
    }
    public func delete(_ id: UUID) throws {
        let source = try location(id)
        let tombstone = root.appendingPathComponent(".deleted-\(UUID().uuidString)")
        try FileManager.default.moveItem(at: source, to: tombstone)
        _ = try reconcile()
        try FileManager.default.removeItem(at: tombstone)
    }
    public func copy(_ id: UUID, parent: UUID? = nil) throws -> UUID {
        try importSubtree(from: location(id), parent: parent)
    }
    public func importSubtree(from source: URL, parent: UUID? = nil) throws -> UUID {
        let stage = root.appendingPathComponent(".import-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: stage) }
        try FileManager.default.copyItem(at: source, to: stage)
        func remap(_ directory: URL) throws -> UUID {
            let original = try BoardDocumentReader.read(directory, relativePath: directory.lastPathComponent)
            // Reject symlinks throughout portable documents, including unreferenced resources.
            if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.isSymbolicLinkKey]) {
                for case let file as URL in enumerator where try file.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true { throw LibraryError.invalid("Portable board contains a symbolic link: \(file.lastPathComponent)") }
            }
            var childIDs: [UUID] = []
            let children = directory.appendingPathComponent("children")
            if FileManager.default.fileExists(atPath: children.path) {
                let candidates = try FileManager.default.contentsOfDirectory(at: children, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                let positions = Dictionary(original.children.enumerated().map { ($1,$0) }, uniquingKeysWith: min)
                let sorted = try candidates.map { (url: $0, id: try BoardDocumentReader.read($0,relativePath:$0.lastPathComponent).id) }.sorted {
                    let a = positions[$0.id] ?? Int.max, b = positions[$1.id] ?? Int.max
                    return a == b ? $0.id.uuidString < $1.id.uuidString : a < b
                }
                for entry in sorted {
                    let child = entry.url
                    let id = try remap(child); childIDs.append(id)
                    try FileManager.default.moveItem(at: child, to: children.appendingPathComponent(id.uuidString))
                }
            }
            let id = UUID()
            try updateIndex(directory) { json in
                json["id"] = id.uuidString; json["hierarchy"] = ["childOrder": childIDs.map(\.uuidString)]
                if var photos = json["photos"] as? [String: Any], var cards = photos["photoItems"] as? [[String: Any]] {
                    for i in cards.indices { cards[i]["id"] = UUID().uuidString }
                    photos["photoItems"] = cards; json["photos"] = photos
                }
            }
            return id
        }
        let id = try remap(stage)
        let destination = (try parent.map(location)?.appendingPathComponent("children") ?? root).appendingPathComponent(id.uuidString)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: stage, to: destination)
        _ = try reconcile(); return id
    }
    public func export(_ id: UUID, to destination: URL) throws {
        try FileManager.default.copyItem(at: location(id), to: destination)
        // Journals and pending-index markers are device-local, never portable content.
        if let enumerator = FileManager.default.enumerator(at: destination, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator where url.lastPathComponent.hasPrefix(".") {
                enumerator.skipDescendants(); try FileManager.default.removeItem(at:url)
            }
        }
    }
}

/// WAL readers see committed board transactions while the writer indexes another batch.
private actor BoardSearchConnection {
    private let catalog: BoardCatalog
    init(database: URL) throws { catalog = try BoardCatalog(url: database) }
    func search(_ query: String, scope: UUID?, allLanguages: Bool, offset: Int) throws -> [LibrarySearchResult] {
        try Task.checkCancellation()
        return try catalog.search(query, scope: scope, allLanguages: allLanguages, language: "und", offset: offset)
    }
}
