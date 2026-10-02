import SwiftUI
import Combine

/// ObservableObject is intentional: Observation requires iOS 17; this app supports 16.6.
@MainActor
final class BoardStore: ObservableObject {
    @Published private(set) var library = Library()
    @Published private(set) var loaded = false
    @Published private(set) var saving = false
    @Published var error: String?
    @Published private(set) var loadFailed = false
    @Published var notice: String?
    let storage: any LibraryStorage
    let mediaURL: URL
    private let legacyMigrationRoot: URL?
    private var revision = 0
    private var undoHistory: [UUID: [Board]] = [:]
    private var redoHistory: [UUID: [Board]] = [:]
    private var pendingSave: Task<Void, Never>?

    init(storage: any LibraryStorage, mediaURL: URL, legacyMigrationRoot: URL? = nil) {
        self.storage = storage; self.mediaURL = mediaURL; self.legacyMigrationRoot = legacyMigrationRoot
    }

    func load() async {
        guard !loaded else { return }
        do {
            var restored = try await storage.load()
            if let legacyMigrationRoot, LegacyImporter.containsBoards(legacyMigrationRoot) {
                let result = try await LegacyImporter(storage: storage).importFolder(legacyMigrationRoot, existing: restored.boards)
                if !result.boards.isEmpty {
                    restored.boards.append(contentsOf: result.boards)
                    revision += 1
                    try await storage.save(restored, revision: revision)
                }
            }
            library = restored; loaded = true; loadFailed = false
        }
        catch { self.error = error.localizedDescription; loadFailed = true }
    }
    func restore() async {
        do { library = try await storage.restoreBackup(); loaded = true; loadFailed = false; error = nil }
        catch { self.error = error.localizedDescription }
    }
    var boards: [Board] { library.boards.filter { $0.deletedAt == nil } }
    func board(_ id: UUID) -> Board? { library.boards.first { $0.id == id } }
    func assetURL(_ name: String?) -> URL? {
        guard let name, (try? AssetPath.validate(name)) != nil else { return nil }
        return mediaURL.appendingPathComponent(name)
    }
    func create(name: String, template: BoardTemplate) -> UUID {
        var board = template.makeBoard(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        board.print = library.defaults.print
        board.communication = library.defaults.communication
        if template == .firstThen { board.print.columns = 2; board.print.rows = 1; board.communication.columns = 2; board.communication.rows = 1 }
        library.boards.append(board); save()
        return board.id
    }
    func edit(_ id: UUID, _ change: (inout Board) -> Void) {
        guard let index = library.boards.firstIndex(where: { $0.id == id }), !loadFailed else { return }
        let old = library.boards[index]
        var updated = old; change(&updated)
        guard updated != old else { return }
        undoHistory[id, default: []].append(old)
        if undoHistory[id, default: []].count > 100 { undoHistory[id]?.removeFirst() }
        redoHistory[id] = []
        updated.modifiedAt = Date(); library.boards[index] = updated
        save()
    }
    func canUndo(_ id: UUID) -> Bool { !(undoHistory[id] ?? []).isEmpty }
    func canRedo(_ id: UUID) -> Bool { !(redoHistory[id] ?? []).isEmpty }
    func undo(_ id: UUID) {
        guard let index = library.boards.firstIndex(where: { $0.id == id }), let prior = undoHistory[id]?.popLast() else { return }
        redoHistory[id, default: []].append(library.boards[index]); library.boards[index] = prior; save()
    }
    func redo(_ id: UUID) {
        guard let index = library.boards.firstIndex(where: { $0.id == id }), let next = redoHistory[id]?.popLast() else { return }
        undoHistory[id, default: []].append(library.boards[index]); library.boards[index] = next; save()
    }
    func duplicate(_ id: UUID) {
        guard let board = board(id) else { return }
        var copy = board.duplicate(); copy.name = L("Copy of") + " " + board.name
        library.boards.append(copy); save()
    }
    func moveBoard(_ id: UUID, offset: Int) {
        guard let from = library.boards.firstIndex(where: { $0.id == id }) else { return }
        let to = min(max(0, from + offset), library.boards.count - 1)
        guard to != from else { return }
        let board = library.boards.remove(at: from); library.boards.insert(board, at: to); save()
    }
    func moveCard(_ card: UUID, board id: UUID, offset: Int) {
        edit(id) { board in
            guard let from = board.cards.firstIndex(where: { $0.id == card }) else { return }
            let to = min(max(0, from + offset), board.cards.count - 1)
            guard to != from else { return }
            let value = board.cards.remove(at: from); board.cards.insert(value, at: to)
        }
    }
    func copyCards(_ ids: Set<UUID>, from source: UUID, to target: UUID) {
        guard let board = board(source) else { return }
        let cards = board.cards.filter { ids.contains($0.id) }.map { $0.duplicate() }
        edit(target) { $0.cards.append(contentsOf: cards) }
    }
    func preferences(_ change: (inout AppPreferences) -> Void) { change(&library.defaults); save() }
    func importLegacy(_ url: URL) async {
        do {
            let result = try await LegacyImporter(storage: storage).importFolder(url, existing: library.boards)
            library.boards.append(contentsOf: result.boards)
            save(); await flush()
            notice = "\(result.boards.count) " + L("boards imported") + "; \(result.skipped) " + L("already imported")
        } catch { self.error = error.localizedDescription }
    }
    func mergeArchive(_ archive: Library) {
        let ids = Set(library.boards.map(\.id))
        library.boards.append(contentsOf: archive.boards.filter { !ids.contains($0.id) })
        save()
    }
    func retrySave() { save() }
    func flush() async { await pendingSave?.value }
    private func save() {
        guard !loadFailed else { return }
        revision += 1
        let rev = revision; let snapshot = library
        saving = true
        let previous = pendingSave
        pendingSave = Task {
            // Serialize manifests even when multiple edit tasks enter storage concurrently.
            await previous?.value
            do {
                try await storage.save(snapshot, revision: rev)
                if revision == rev { saving = false; error = nil }
            } catch {
                if revision == rev { saving = false; self.error = error.localizedDescription }
            }
        }
    }
}
