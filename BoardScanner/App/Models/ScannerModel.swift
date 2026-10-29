import Combine
import Foundation

@MainActor
final class ScannerModel: ObservableObject {
    @Published var board: ScannedBoard?
    @Published private(set) var documentID = UUID()
    @Published private(set) var libraryID: UUID?
    private(set) var openInEditor = false
    @Published private(set) var libraryEntries: [LibraryEntry] = []
    @Published private(set) var deletedEntries: [LibraryEntry] = []
    @Published var pageSet: SnapPageSet?
    @Published var source: Data?
    @Published var busy = false
    @Published private(set) var canCancel = false
    @Published var status = "Images and labels, ready to use."
    @Published var error: String?
    @Published var dirty = false
    let library: BoardLibrary
    private let savedSymbols: SavedSymbolLibraries
    private let legacySaveURL: URL
    private var operation: Task<Void, Never>?
    private var generation = UUID()
    private var restored = false
    private var queuedOpenURL: URL?

    init(libraryRoot: URL? = nil, legacySaveURL: URL? = nil) {
        let arguments = ProcessInfo.processInfo.arguments
        let testing = arguments.contains("--ui-testing")
        let base = URL.documentsDirectory.appendingPathComponent("BoardScanner")
        var name = testing ? "UITestLibrary" : "Library"
        #if DEBUG
        if testing, let index = arguments.firstIndex(of: "--library-id"), arguments.indices.contains(index + 1),
           let id = UUID(uuidString: arguments[index + 1]) { name = "UITestLibrary-" + id.uuidString }
        #endif
        let root = libraryRoot ?? base.appendingPathComponent(name)
        library = BoardLibrary(root: root)
        savedSymbols = SavedSymbolLibraries(root: root.appendingPathComponent("SymbolLibraries"))
        self.legacySaveURL = legacySaveURL ?? base.appendingPathComponent(testing ? "ui-test.boardscan" : "latest.boardscan")
    }

    func createBoard(title: String, rows: Int, columns: Int, starter: Bool) {
        perform(status: "Creating board…") { [self] in
            try await migrateLegacyBeforeImport()
            try await preserveCurrent()
            let set = try NativeBoardFactory.make(title: title, rows: rows, columns: columns, starter: starter)
            try await addCreatedBoard(set)
        }
    }

    func makeEditableCopy() {
        guard let board else { return }
        perform(status: "Creating editable copy…") { [self] in
            try await preserveCurrent()
            try await addCreatedBoard(NativeBoardFactory.editableCopy(of: board))
        }
    }

    private func addCreatedBoard(_ set: SnapPageSet) async throws {
        let document = BoardDocument(pageSet: set), id = UUID()
        try await library.save(document, id: id)
        try await library.select(id)
        install(document, id: id, openEditor: true)
        await refreshLibrary()
        status = "Board created · Saved"
    }

    func editPageSet(_ edit: PageSetEdit) -> String? {
        guard !busy else { return "Please wait for saving to finish." }
        guard var updated = pageSet else { return "Open a board first." }
        do { try PageSetAuthoring.apply(edit, to: &updated) }
        catch { return error.localizedDescription }
        pageSet = updated
        dirty = true
        perform(status: "Saving changes…") { [self] in
            try await persistCurrent()
            status = edit.successMessage
        }
        return nil
    }

    func scan(_ data: Data, grid: GridOverride? = nil) {
        perform(status: "Finding cards and reading labels…", cancellable: true) { [self] in
            try await migrateLegacyBeforeImport()
            try await preserveCurrent()
            canCancel = true
            do {
                let result = try await BoardAnalyzer.analyze(data: data, grid: grid)
                try Task.checkCancellation()
                // Grid correction updates the same saved board; a new import gets its own entry.
                let id = grid != nil && data == board?.sourcePNG ? (libraryID ?? UUID()) : UUID()
                canCancel = false
                let document = BoardDocument(board: result)
                try await library.save(document, id: id)
                try await library.select(id)
                install(document, id: id)
                await refreshLibrary()
                status = "\(result.cards.filter(\.included).count) cards · \(result.method) · Saved"
            } catch is CancellationError { throw CancellationError() }
            catch {
                // Keep the current board safe in the library while exposing the failed source for grid correction.
                source = data
                throw error
            }
        }
    }

    func open(_ url: URL) {
        if busy { queuedOpenURL = url; return }
        perform(status: "Opening file…", cancellable: true) { [self] in
            try await migrateLegacyBeforeImport()
            try await preserveCurrent()
            canCancel = true
            let document: BoardDocument
            var symbolLibraryFailures = 0
            if url.pathExtension.lowercased() == "sps" {
                var result = try await TDSnapImporter.load(url)
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if args.contains("--ui-testing"), let index = args.firstIndex(of: "--symbol-library"), args.indices.contains(index + 1) {
                    result = try await savedSymbols.rememberAndSupplement(result, from: URL(fileURLWithPath: args[index + 1]))
                }
                #endif
                let recovered = try await savedSymbols.supplement(result)
                result = recovered.pageSet
                symbolLibraryFailures = recovered.failedLibraries
                document = BoardDocument(pageSet: result)
            } else if url.pathExtension.lowercased() == "boardscan" {
                document = try await BoardStorage.openDocument(url)
            } else {
                let data = try await BoardStorage.read(url)
                do { document = BoardDocument(board: try await BoardAnalyzer.analyze(data: data)) }
                catch {
                    source = data
                    throw error
                }
            }
            try Task.checkCancellation()
            // Commit the imported document before replacing the board on screen.
            let id = UUID()
            canCancel = false
            try await library.save(document, id: id)
            try Task.checkCancellation()
            try await library.select(id)
            try Task.checkCancellation()
            install(document, id: id)
            await refreshLibrary()
            status = symbolLibraryFailures == 0 ? "Board added to library"
                : "Board added · Could not read \(symbolLibraryFailures) saved symbol libraries. Import the symbol library again to restore missing artwork."
        }
    }

    func openSaved(_ id: UUID) {
        guard id != libraryID else { return }
        perform(status: "Opening saved board…") { [self] in
            try await preserveCurrent()
            let result = try await library.load(id)
            try Task.checkCancellation()
            try await library.select(id)
            try Task.checkCancellation()
            install(result.document, id: id)
            status = result.recovered ? "Recovered a previous saved version" : "Board opened"
        }
    }

    func importSymbolLibrary(_ url: URL) {
        guard let original = pageSet else { error = "Open a TD Snap page set before importing a symbol library."; return }
        perform(status: "Restoring missing artwork…", cancellable: true) { [self] in
            let updated = try await savedSymbols.rememberAndSupplement(original, from: url)
            try Task.checkCancellation()
            canCancel = false
            pageSet = updated
            dirty = true
            try await persistCurrent()
            status = "Restored \(original.unavailableImageCount - updated.unavailableImageCount) button images · \(updated.unavailableImageCount) unavailable · Library remembered"
        }
    }

    func update(_ card: ScannedCard) {
        guard let board else { return }
        perform(status: "Updating card…") { [self] in
            let updated = try await BoardAnalyzer.recrop(source: board.sourcePNG, card: card)
            try Task.checkCancellation()
            guard let index = self.board?.cards.firstIndex(where: { $0.id == card.id }) else { return }
            self.board?.cards[index] = updated
            dirty = true
            try await persistCurrent()
            status = "Card updated · Saved"
        }
    }

    func update(_ button: SnapButton) {
        guard !busy else { return }
        guard let key = pageSet?.buttons.first(where: { $0.value.id == button.id })?.key else { return }
        pageSet?.buttons[key] = button
        dirty = true
        perform(status: "Saving button…") { [self] in
            try await persistCurrent()
            status = "Button updated · Saved"
        }
    }

    var document: BoardDocument? {
        if let pageSet { return BoardDocument(pageSet: pageSet) }
        return board.map(BoardDocument.init)
    }

    func save() {
        guard document != nil else { return }
        perform(status: "Saving board…") { [self] in
            try await persistCurrent()
            status = "Saved on this device"
        }
    }

    func rename(_ entry: LibraryEntry, title: String) {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        perform(status: "Renaming board…") { [self] in
            try await preserveCurrent()
            let result = try await library.load(entry.id)
            try Task.checkCancellation()
            let renamed = result.document.renamed(name)
            try await library.save(renamed, id: entry.id)
            try Task.checkCancellation()
            if libraryID == entry.id {
                board = renamed.board
                pageSet = renamed.pageSet
            }
            await refreshLibrary()
            status = "Board renamed"
        }
    }

    func duplicate(_ entry: LibraryEntry) {
        perform(status: "Copying board…") { [self] in
            try await preserveCurrent()
            let result = try await library.load(entry.id)
            try Task.checkCancellation()
            try await library.save(result.document.renamed(result.document.title + " copy"), id: UUID())
            try Task.checkCancellation()
            await refreshLibrary()
            status = "Board copied"
        }
    }

    func delete(_ entry: LibraryEntry) {
        perform(status: "Moving board to Recently deleted…") { [self] in
            try await preserveCurrent()
            try await library.delete(entry.id)
            try Task.checkCancellation()
            if libraryID == entry.id {
                board = nil; pageSet = nil; source = nil; libraryID = nil; dirty = false
                openInEditor = false
                documentID = UUID()
            }
            await refreshLibrary()
            status = "Moved to Recently deleted"
        }
    }

    func restoreDeleted(_ entry: LibraryEntry) {
        perform(status: "Restoring board…") { [self] in
            try await library.restore(entry.id)
            try Task.checkCancellation()
            await refreshLibrary()
            status = "Board restored"
        }
    }

    func refreshLibrary() async {
        do {
            let entries = try await library.entries()
            let deleted = try await library.entries(deleted: true)
            guard !Task.isCancelled else { return }
            libraryEntries = entries
            deletedEntries = deleted
        } catch { self.error = error.localizedDescription }
    }

    func restore() async {
        guard !restored else { return }
        // A document URL can arrive before SwiftUI starts restoration. Let that
        // operation settle so a failed import still reopens the saved board.
        while busy, let pendingOperation = operation {
            await pendingOperation.value
            guard !Task.isCancelled, !restored else { return }
        }
        guard !busy, !Task.isCancelled else { return }
        restored = true
        // A successful incoming import already installed the desired document.
        guard document == nil else { return }
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-testing"), let index = arguments.firstIndex(of: "--import-test-document"), arguments.indices.contains(index + 1) {
            open(URL(fileURLWithPath: arguments[index + 1])); return
        }
        #endif
        guard !ProcessInfo.processInfo.arguments.contains("--fresh-start") else { return }
        let current = generation
        busy = true
        defer {
            if current == generation { busy = false; openQueuedFile() }
        }
        do {
            let entries = try await library.entries()
            let selected = try await library.selectedID()
            if let id = selected ?? entries.first?.id {
                let result = try await library.load(id)
                guard current == generation, !Task.isCancelled else { return }
                install(result.document, id: id)
                status = result.recovered ? "Recovered a previous saved version" : "Restored your saved board"
            } else if !(await library.hasSavedSelection()), FileManager.default.fileExists(atPath: legacySaveURL.path) {
                // Migration is a copy. The original single-slot document is never removed.
                let document = try await BoardStorage.openDocument(legacySaveURL)
                guard current == generation, !Task.isCancelled else { return }
                let id = UUID()
                try await library.save(document, id: id)
                guard current == generation, !Task.isCancelled else { return }
                try await library.select(id)
                guard current == generation, !Task.isCancelled else { return }
                install(document, id: id)
                status = "Your saved board is now in the library"
            }
            await refreshLibrary()
        } catch {
            guard current == generation, !Task.isCancelled else { return }
            self.error = "Could not restore the saved board: \(error.localizedDescription)"
            await refreshLibrary()
        }
    }

    private func install(_ document: BoardDocument, id: UUID, dirty: Bool = false, openEditor: Bool = false) {
        openInEditor = openEditor
        documentID = UUID()
        libraryID = id
        board = document.board
        pageSet = document.pageSet
        source = document.board?.sourcePNG
        self.dirty = dirty
    }

    private func migrateLegacyBeforeImport() async throws {
        // Open In can arrive before the view's restoration task. Preserve the old
        // single-slot save even when the incoming file wins that startup race.
        guard document == nil, !ProcessInfo.processInfo.arguments.contains("--fresh-start"),
              !(await library.hasSavedSelection()), FileManager.default.fileExists(atPath: legacySaveURL.path) else { return }
        let legacy: BoardDocument
        do { legacy = try await BoardStorage.openDocument(legacySaveURL) }
        catch is CancellationError { throw CancellationError() }
        catch {
            self.error = "The previous saved board could not be migrated. Its original file has been kept; you can still import a new board."
            return
        }
        try Task.checkCancellation()
        canCancel = false
        let id = UUID()
        try await library.save(legacy, id: id)
        try await library.select(id)
    }

    private func preserveCurrent() async throws {
        if document != nil && (dirty || libraryID == nil) { try await persistCurrent() }
    }

    private func persistCurrent() async throws {
        guard let document else { return }
        canCancel = false
        let id = libraryID ?? UUID()
        libraryID = id
        try await library.save(document, id: id)
        try Task.checkCancellation()
        try await library.select(id)
        try Task.checkCancellation()
        dirty = false
        await refreshLibrary()
    }

    func cancel() {
        guard canCancel else { return }
        operation?.cancel()
        operation = nil
        generation = UUID()
        busy = false
        status = dirty ? "Changes are not saved. Tap Save to retry." : "Cancelled"
        canCancel = false
        openQueuedFile()
    }

    private func perform(status: String, cancellable: Bool = false, work: @escaping @MainActor () async throws -> Void) {
        guard !busy else { return }
        generation = UUID()
        canCancel = cancellable
        error = nil
        self.status = status
        busy = true
        let current = generation
        operation = Task { [weak self] in
            do { try await work() }
            catch is CancellationError { }
            catch {
                guard self?.generation == current else { return }
                self?.error = error.localizedDescription
                self?.status = self?.dirty == true ? "Changes are not saved. Tap Save to retry." : "Could not complete this operation"
            }
            guard self?.generation == current else { return }
            self?.busy = false
            self?.operation = nil
            self?.canCancel = false
            self?.openQueuedFile()
        }
    }

    private func openQueuedFile() {
        guard let url = queuedOpenURL else { return }
        queuedOpenURL = nil
        open(url)
    }

    deinit { operation?.cancel() }
}
