import Foundation

/// A generation keeps a stable filename for the lifetime of its WAL connections.
/// Promotion replaces only a small pointer file, never an open SQLite database.
struct CatalogGeneration {
    let database: URL
    let needsPromotion: Bool
    private let active: URL
    private let pending: URL

    init(base: URL) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: base.deletingLastPathComponent(), withIntermediateDirectories: true)
        active = URL(fileURLWithPath: base.path + ".active")
        pending = URL(fileURLWithPath: base.path + ".pending")
        let prefix = base.lastPathComponent + ".generation-"
        func referencedDatabase(_ pointer: URL) -> URL? {
            guard let data = try? Data(contentsOf: pointer),
                  let name = try? JSONDecoder().decode(String.self, from: data),
                  name.hasPrefix(prefix), UUID(uuidString: String(name.dropFirst(prefix.count))) != nil,
                  let url = try? DocumentPaths.owned(name, by: base.deletingLastPathComponent()),
                  BoardCatalog.isCurrent(at: url) else { return nil }
            return url
        }
        if let current = referencedDatabase(active) {
            database = current; needsPromotion = false
        } else if let interrupted = referencedDatabase(pending) {
            database = interrupted; needsPromotion = true
        } else if BoardCatalog.isCurrent(at: base) {
            database = base; needsPromotion = false
        } else {
            database = base.deletingLastPathComponent().appendingPathComponent(prefix + UUID().uuidString)
            needsPromotion = true
            // A crash before schema creation is harmless: the next launch makes
            // a fresh generation; a committed batch resumes from this pointer.
            try JSONEncoder().encode(database.lastPathComponent).write(to: pending, options: .atomic)
        }
    }

    func promote() throws {
        guard needsPromotion else { return }
        try JSONEncoder().encode(database.lastPathComponent).write(to: active, options: .atomic)
        // If removal fails, the active pointer still wins on the next launch.
        try? FileManager.default.removeItem(at: pending)
    }
}
