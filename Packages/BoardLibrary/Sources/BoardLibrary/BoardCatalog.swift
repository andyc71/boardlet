import Foundation
import SQLite3

public struct BoardSummary: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var parentID: UUID?
    public var relativePath: String
    public var title: String
    public var cover: String?
    public var childCount: Int
    public var fingerprint: String = ""
}
public struct LibrarySearchResult: Identifiable, Sendable {
    public var id: String { boardID.uuidString + (cardID?.uuidString ?? "") }
    public var boardID: UUID
    public var cardID: UUID?
    public var title: String
    public var matchedText: String
    public var language: String
    public var breadcrumb: String
    public var relativePath: String
    public var image: String?
    public var fingerprint: String
}

/// Access only from the owning store's serial executor. Every query is SQL-only.
final class BoardCatalog {
    static let schemaVersion = 2
    /// Inspect without modifying an older or damaged generation.
    static func isCurrent(at url: URL) -> Bool {
        var connection: OpaquePointer?
        guard sqlite3_open_v2(url.path, &connection, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(connection); return false
        }
        defer { sqlite3_close(connection) }
        func scalar(_ sql: String) -> String? {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(connection, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
            defer { sqlite3_finalize(statement) }
            guard sqlite3_step(statement) == SQLITE_ROW, let value = sqlite3_column_text(statement, 0) else { return nil }
            return String(cString: value)
        }
        return scalar("PRAGMA user_version") == String(schemaVersion) && scalar("PRAGMA quick_check(1)") == "ok"
    }
    private var db: OpaquePointer?
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open(url.path, &db) == SQLITE_OK else { throw LibraryError.invalid("Cannot open catalogue") }
        try execute("PRAGMA journal_mode=WAL")
        try execute("CREATE TABLE IF NOT EXISTS boards(id TEXT PRIMARY KEY,parent TEXT,path TEXT UNIQUE, fingerprint TEXT, document BLOB)")
        try execute("CREATE INDEX IF NOT EXISTS parent_index ON boards(parent)")
        try execute("CREATE TABLE IF NOT EXISTS unavailable(board TEXT PRIMARY KEY)")
        try execute("CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY,value TEXT)")
        try execute("CREATE TABLE IF NOT EXISTS index_state(path TEXT PRIMARY KEY, files TEXT, signature TEXT)")
        try execute("CREATE TABLE IF NOT EXISTS entities(id INTEGER PRIMARY KEY,board TEXT,card TEXT, UNIQUE(board,card))")
        try execute("CREATE TABLE IF NOT EXISTS texts(board TEXT,card TEXT,language TEXT,label TEXT,displayed INTEGER,source TEXT,entity INTEGER,PRIMARY KEY(board,card,language))")
        if !(try rows("PRAGMA table_info(texts)")).contains(where: { $0[1] == "source" }) { try execute("ALTER TABLE texts ADD COLUMN source TEXT DEFAULT 'und'") }
        if !(try rows("PRAGMA table_info(texts)")).contains(where: { $0[1] == "entity" }) {
            try execute("ALTER TABLE texts ADD COLUMN entity INTEGER")
            try execute("DELETE FROM texts"); try execute("DELETE FROM boards"); try execute("DELETE FROM index_state")
        }
        if !(try rows("PRAGMA table_info(texts)")).contains(where: { $0[1] == "folded" }) {
            try execute("ALTER TABLE texts ADD COLUMN folded TEXT")
            // Rebuild only derived rows so Unicode case folding is consistent.
            try transaction {
                try execute("DELETE FROM texts"); try execute("DELETE FROM entities")
                try execute("DELETE FROM boards"); try execute("DELETE FROM index_state")
            }
        }
        try execute("CREATE VIRTUAL TABLE IF NOT EXISTS search USING fts5(label, tokenize='unicode61 remove_diacritics 0')")
        try execute("CREATE TRIGGER IF NOT EXISTS text_delete AFTER DELETE ON texts BEGIN DELETE FROM search WHERE rowid=old.rowid; END")
        try execute("CREATE TRIGGER IF NOT EXISTS text_insert AFTER INSERT ON texts BEGIN INSERT INTO search(rowid,label) VALUES(new.rowid,new.label); END")
        if try rows("SELECT name FROM sqlite_master WHERE type='table' AND name='cards'").isEmpty {
            try transaction {
                try execute("CREATE TABLE cards(board TEXT,card TEXT,position INTEGER,image TEXT,overrides TEXT,PRIMARY KEY(board,card))")
                // Existing catalogues must reread manifests to obtain image references.
                try execute("DELETE FROM texts"); try execute("DELETE FROM entities")
                try execute("DELETE FROM boards"); try execute("DELETE FROM index_state")
            }
        }
        try execute("PRAGMA user_version=\(Self.schemaVersion)")
    }
    deinit { sqlite3_close(db) }
    @discardableResult func rows(_ sql: String, _ args: [String] = []) throws -> [[String]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { throw error() }
        defer { sqlite3_finalize(statement) }
        for (i, value) in args.enumerated() { sqlite3_bind_text(statement, Int32(i + 1), value, -1, transient) }
        var result: [[String]] = []
        while true {
            let status = sqlite3_step(statement)
            if status == SQLITE_DONE { return result }
            guard status == SQLITE_ROW else { throw error() }
            result.append((0..<sqlite3_column_count(statement)).map { i in sqlite3_column_text(statement, i).map { String(cString: $0) } ?? "" })
        }
    }
    func execute(_ sql: String, _ args: [String] = []) throws { _ = try rows(sql, args) }
    func error() -> Error { LibraryError.invalid(String(cString: sqlite3_errmsg(db))) }
    func transaction(_ body: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE")
        do { try body(); try execute("COMMIT") } catch { try? execute("ROLLBACK"); throw error }
    }
    func replace(_ document: BoardDocument, path: String, parent: UUID?, language: String) throws {
        try transaction {
            for row in try rows("SELECT id FROM boards WHERE path=? AND id<>?", [path,document.id.uuidString]) {
                try execute("DELETE FROM texts WHERE board=?", [row[0]])
                try execute("DELETE FROM entities WHERE board=?", [row[0]])
                try execute("DELETE FROM cards WHERE board=?", [row[0]])
                try execute("DELETE FROM boards WHERE id=?", [row[0]])
            }
            try execute("DELETE FROM texts WHERE board=?", [document.id.uuidString])
            var metadata = document
            metadata.cards = []
            let bytes = try JSONEncoder().encode(metadata)
            try execute("INSERT OR REPLACE INTO boards VALUES(?,?,?,?,?)", [document.id.uuidString,parent?.uuidString ?? "",path,document.fingerprint,String(decoding: bytes, as: UTF8.self)])
            try execute("DELETE FROM entities WHERE board=?", [document.id.uuidString])
            try execute("DELETE FROM cards WHERE board=?", [document.id.uuidString])
            let selected = document.language ?? language
            func insert(_ text: LibraryText, card: String) throws {
                try execute("INSERT INTO entities(board,card) VALUES(?,?)", [document.id.uuidString,card])
                let entity = String(sqlite3_last_insert_rowid(db))
                let effective = text.resolve(selected).1
                for (tag, value) in text.values.sorted(by: { ($0.key == effective ? "0" : "1") + $0.key < ($1.key == effective ? "0" : "1") + $1.key }) {
                    try execute("INSERT INTO texts(board,card,language,label,displayed,source,entity,folded) VALUES(?,?,?,?,?,?,?,?)", [document.id.uuidString,card,tag,value,tag == effective ? "1" : "0",text.source,entity,value.lowercased()])
                }
            }
            try insert(document.title, card: "")
            for card in document.cards {
                try insert(card.text, card: card.id.uuidString)
                let overrides = String(decoding: try JSONEncoder().encode(card.imageOverrides), as: UTF8.self)
                try execute("INSERT INTO cards VALUES(?,?,?,?,?)", [document.id.uuidString,card.id.uuidString,String(card.position),card.image ?? "",overrides])
            }
        }
    }
    func project(language: String) throws {
        try transaction {
        for row in try rows("SELECT id,document FROM boards") {
            let doc = try JSONDecoder().decode(BoardDocument.self, from: Data(row[1].utf8))
            let candidates = LibraryText.candidates(doc.language ?? language)
            let cases = candidates.enumerated().map { "WHEN ? THEN \($0.offset)" }.joined(separator:" ")
            let placeholders = candidates.map { _ in "?" }.joined(separator:",")
            try execute("UPDATE texts SET displayed=CASE WHEN language=(SELECT t.language FROM texts t WHERE t.board=texts.board AND t.card=texts.card AND (t.language IN (\(placeholders)) OR t.language=t.source) ORDER BY CASE t.language \(cases) ELSE 999 END LIMIT 1) THEN 1 ELSE 0 END WHERE board=?", candidates + candidates + [row[0]])
        }
        try execute("INSERT OR REPLACE INTO settings VALUES('language',?)", [language])
        }
    }
    func remove(_ id: String) throws {
        try transaction { try execute("DELETE FROM index_state WHERE path IN (SELECT path FROM boards WHERE id=?)", [id]); try execute("DELETE FROM texts WHERE board=?", [id]); try execute("DELETE FROM boards WHERE id=?", [id]); try execute("DELETE FROM entities WHERE board=?", [id]); try execute("DELETE FROM cards WHERE board=?", [id]) }
    }
    func entries() throws -> [(BoardDocument, String, UUID?)] {
        try rows("SELECT document,path,parent FROM boards ORDER BY id").map { (try JSONDecoder().decode(BoardDocument.self, from: Data($0[0].utf8)), $0[1], UUID(uuidString: $0[2])) }
    }
    func search(_ query: String, scope: UUID?, allLanguages: Bool, language fallbackLanguage: String, offset: Int) throws -> [LibrarySearchResult] {
        let terms = query.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        guard !terms.isEmpty else { return [] }
        let expression = terms.enumerated().map { "\"" + $0.element.replacingOccurrences(of: "\"", with: "\"\"") + "\"" + ($0.offset == terms.count - 1 ? "*" : "") }.joined(separator: " AND ")
        // Deduplicate translations BEFORE LIMIT/OFFSET. Stable entity ties make paging repeatable.
        // Current-language projection has exactly one displayed row per entity;
        // it does not need the all-language aggregation step.
        let chosen = allLanguages ? "COALESCE(MIN(CASE WHEN t.displayed=1 THEN t.rowid END), MIN(t.rowid))" : "t.rowid"
        let grouping = allLanguages ? " GROUP BY t.entity" : ""
        let sql = """
        WITH RECURSIVE subtree(id) AS (SELECT id FROM boards WHERE id=? UNION ALL SELECT b.id FROM boards b JOIN subtree s ON b.parent=s.id),
        matches AS (SELECT \(chosen) AS chosen
          FROM search JOIN texts t ON t.rowid=search.rowid WHERE t.board NOT IN (SELECT board FROM unavailable) AND search MATCH ? AND (?='1' OR t.displayed=1) AND (?='' OR t.board IN (SELECT id FROM subtree)) \(grouping))
        SELECT t.board,t.card,t.label,t.language FROM matches m JOIN texts t ON t.rowid=m.chosen ORDER BY CASE WHEN t.displayed=1 AND t.folded=? THEN 0 ELSE 1 END,lower(t.label),t.board,t.card LIMIT 40 OFFSET ?
        """
        sqlite3_progress_handler(db, 1000, { _ in Task.isCancelled ? 1 : 0 }, nil)
        defer { sqlite3_progress_handler(db, 0, nil, nil) }
        try execute("BEGIN DEFERRED")
        defer { try? execute("ROLLBACK") }
        let language = try rows("SELECT value FROM settings WHERE key='language'").first?.first ?? fallbackLanguage
        let found = try rows(sql, [scope?.uuidString ?? "",expression,allLanguages ? "1" : "0",scope?.uuidString ?? "",query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),String(max(0,offset))])
        return try found.map { row in
            guard let boardID = UUID(uuidString: row[0]), let entity = try rows("SELECT document,parent,path FROM boards WHERE id=?", [row[0]]).first else { throw LibraryError.invalid("Missing search board") }
            let doc = try JSONDecoder().decode(BoardDocument.self, from: Data(entity[0].utf8))
            let cardID = UUID(uuidString: row[1])
            let title = try rows("SELECT label FROM texts WHERE board=? AND card=? AND displayed=1 LIMIT 1", [row[0],row[1]]).first?.first ?? ""
            var path = [doc.title.resolve(doc.language ?? language).0]; var parent = entity[1]; var visited = Set<String>()
            while !parent.isEmpty, visited.insert(parent).inserted, let ancestor = try rows("SELECT document,parent FROM boards WHERE id=?", [parent]).first {
                let document = try JSONDecoder().decode(BoardDocument.self, from: Data(ancestor[0].utf8)); path.insert(document.title.resolve(document.language ?? language).0, at: 0); parent = ancestor[1]
            }
            let selectedLanguage = doc.language ?? language
            let image: String?
            if cardID != nil, let card = try rows("SELECT image,overrides FROM cards WHERE board=? AND card=?", [row[0],row[1]]).first {
                let overrides = try JSONDecoder().decode([String: String].self, from: Data(card[1].utf8))
                image = LibraryText.candidates(selectedLanguage).compactMap { overrides[$0] }.first ?? (card[0].isEmpty ? nil : card[0])
            } else {
                image = LibraryText.candidates(selectedLanguage).compactMap { doc.covers[$0] }.first ?? doc.cover
            }
            return LibrarySearchResult(boardID: boardID, cardID: cardID, title: title, matchedText: row[2], language: row[3], breadcrumb: path.joined(separator: " › "), relativePath: entity[2], image: image, fingerprint: doc.fingerprint)
        }
    }
}
