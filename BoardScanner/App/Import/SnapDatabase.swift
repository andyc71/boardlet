import Foundation
import SQLite3

/// A private read-only connection, confined to one import task. No source SQL is executed.
final class SnapDatabase {
    private var connection: OpaquePointer?

    init(url: URL) throws {
        guard sqlite3_open_v2(url.path, &connection, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK else {
            if let connection { sqlite3_close(connection) }
            connection = nil
            throw ScanError.invalidPageSet
        }
        sqlite3_limit(connection, SQLITE_LIMIT_LENGTH, 40_000_000)
        sqlite3_limit(connection, SQLITE_LIMIT_SQL_LENGTH, 10_000)
        try rows("PRAGMA query_only = ON") { _ in }
        try rows("PRAGMA trusted_schema = OFF") { _ in }
    }

    deinit { sqlite3_close(connection) }

    func rows(_ sql: String, limit: Int = 100_000, visit: (OpaquePointer) throws -> Void) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw ScanError.invalidPageSet
        }
        defer { sqlite3_finalize(statement) }
        var count = 0
        while true {
            try Task.checkCancellation()
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { return }
            guard result == SQLITE_ROW else { throw ScanError.invalidPageSet }
            count += 1
            guard count <= limit else { throw ScanError.invalidPageSet }
            try visit(statement)
        }
    }

    static func text(_ row: OpaquePointer, _ column: Int32) -> String {
        guard let value = sqlite3_column_text(row, column) else { return "" }
        return String(cString: value)
    }

    static func integer(_ row: OpaquePointer, _ column: Int32) -> Int {
        Int(sqlite3_column_int64(row, column))
    }

    func columns(in table: String) throws -> Set<String> {
        // Callers supply fixed schema names, never document contents.
        var names = Set<String>()
        try rows("PRAGMA table_info(\(table))") { names.insert(Self.text($0, 1)) }
        return names
    }

    static func argb(_ row: OpaquePointer, _ column: Int32) -> UInt32? {
        guard sqlite3_column_type(row, column) == SQLITE_INTEGER else { return nil }
        let value = sqlite3_column_int64(row, column)
        guard value >= Int32.min, value <= UInt32.max else { return nil }
        return UInt32(truncatingIfNeeded: value)
    }

    static func data(_ row: OpaquePointer, _ column: Int32) -> Data {
        guard let value = sqlite3_column_blob(row, column) else { return Data() }
        return Data(bytes: value, count: Int(sqlite3_column_bytes(row, column)))
    }
}
