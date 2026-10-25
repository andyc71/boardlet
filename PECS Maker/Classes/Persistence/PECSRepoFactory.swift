import Combine
import PersistenceFramework
import SwiftUI
import BoardLibrary

/// App-owned adapter: constructing this object never constructs a framework RepoFactory.
final class PECSRepoFactory: ObservableObject {
    static let shared = PECSRepoFactory()
    @Published var publishedTopics: [BoardSummary] = []
    @Published var allBoards: [BoardSummary] = []
    @Published var isIndexing = true
    @Published var isIndexComplete = false
    @Published var diagnostics: [String] = []
    @Published var publishedCurrentTopic: PECSRepo? {
        didSet { UserDefaults.standard.set(publishedCurrentTopic?.id.uuidString, forKey: "BoardLibrary.currentID") }
    }
    var currentTopic: PECSRepo? { get { publishedCurrentTopic } set { publishedCurrentTopic = newValue } }
    var documentsDirectory: URL { RepoHelper.documentsDirectory }
    private(set) var store: BoardLibraryStore?
    private var observers: [NSObjectProtocol] = []
    private var filePresenter: BoardLibraryPresenter?
    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = UUID()
    private var needsInitialRestoration = true
    private var appliedGeneration: UInt64 = 0
    private var cache: [UUID: PECSRepo] = [:]
    private var cacheFingerprints: [UUID: String] = [:]
    private static let topicOrderDefaultsKey = "PECSRepoFactory.topicOrder"
    private init() {
        let root = documentsDirectory.appendingPathComponent("topics")
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let database = support.appendingPathComponent("BoardCatalog/\(DocumentPaths.provisionalID(root.path)).sqlite")
        let language = BoardLanguage.appLanguage
        let legacyCatalog = Bundle.main.url(forResource: "StarterBoards", withExtension: nil)
        let initialization = Task.detached(priority: .userInitiated) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let defaultTitleTables = try Bundle.main.localizations.compactMap { language -> Data? in
                guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
                      let bundle = Bundle(path: path) else { return nil }
                let title = bundle.localizedString(forKey: "Repo.defaultTopicTitle", value: nil, table: "Localizable")
                guard title != "Repo.defaultTopicTitle" else { return nil }
                return try encoder.encode(["board.title": title])
            }
            let store = try BoardLibraryStore(root: root, database: database, language: language,
                                             legacyCatalog: legacyCatalog, recoveryTables: defaultTitleTables)
            var directory = database.deletingLastPathComponent()
            var values = URLResourceValues(); values.isExcludedFromBackup = true
            try directory.setResourceValues(values)
            return store
        }
        observers.append(NotificationCenter.default.addObserver(forName: .boardDocumentSaved, object: nil, queue: .main) { [weak self] note in
            if let directory = note.object as? URL { self?.documentSaved(at: directory) }
        })
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in self?.refresh() })
        filePresenter = BoardLibraryPresenter(root: root) { [weak self] in self?.refresh() }
        Task { @MainActor [weak self] in
            do {
                let store = try await initialization.value
                guard let self else { return }
                self.store = store
                self.refresh(restore: true)
            } catch {
                self?.diagnostics = [error.localizedDescription]
                self?.isIndexing = false
            }
        }
    }
    func refresh(restore: Bool = false) {
        refreshTask?.cancel()
        let generation = UUID(); refreshGeneration = generation
        refreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            guard let store else { return }
            isIndexing = true
            do {
                let snapshot = try await store.reconcile(language: BoardLanguage.appLanguage) { [weak self] partial in
                    Task { @MainActor in
                        guard let self, self.refreshGeneration == generation, self.isIndexing else { return }
                        self.apply(partial)
                    }
                }
                try Task.checkCancellation()
                apply(snapshot)
                isIndexing = false
                if needsInitialRestoration {
                    needsInitialRestoration = false
                    let selected = UserDefaults.standard.string(forKey: "BoardLibrary.currentID")
                    let oldPath = UserDefaults.standard.string(forKey: "RepoFactory.currentTopicDir")
                    if let summary = allBoards.first(where: { $0.id.uuidString == selected || $0.relativePath == oldPath }) { publishedCurrentTopic = try open(summary) }
                    else if allBoards.isEmpty && snapshot.diagnostics.isEmpty {
                        publishedCurrentTopic = try createEmptyRepo(setActive: true)
                    }
                }
            } catch is CancellationError { }
            catch { diagnostics = [error.localizedDescription]; isIndexing = false }
        }
    }
    private func apply(_ snapshot: LibrarySnapshot) {
        guard snapshot.generation >= appliedGeneration else { return }
        appliedGeneration = snapshot.generation
        isIndexComplete = snapshot.isComplete
        allBoards = snapshot.boards
        let saved = UserDefaults.standard.stringArray(forKey: Self.topicOrderDefaultsKey) ?? []
        let order = Dictionary((saved + Self.starterOrder).enumerated().map { ($1,$0) }, uniquingKeysWith: min)
        publishedTopics = snapshot.boards.filter { $0.parentID == nil }.sorted {
            let a = order[$0.id.uuidString] ?? order[URL(fileURLWithPath: $0.relativePath).lastPathComponent] ?? Int.max
            let b = order[$1.id.uuidString] ?? order[URL(fileURLWithPath: $1.relativePath).lastPathComponent] ?? Int.max
            return a == b ? $0.id.uuidString < $1.id.uuidString : a < b
        }
        diagnostics = snapshot.diagnostics
    }
    private func documentSaved(at directory: URL) {
        guard let store else { return }
        Task { @MainActor in
            do { apply(try await store.updateBoard(at: directory)) }
            catch { refresh() }
        }
    }
    func open(_ summary: BoardSummary) throws -> PECSRepo {
        let current = allBoards.first(where: { $0.id == summary.id }) ?? summary
        let directory = try DocumentPaths.owned(current.relativePath, by: documentsDirectory.appendingPathComponent("topics"))
        // A result can outlive an external edit even before foreground reconciliation.
        let document = try BoardDocumentReader.read(directory, relativePath: current.relativePath,
            legacyCatalog: Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        guard document.id == summary.id else { refresh(); throw LibraryError.invalid("Board changed; please select it again") }
        if let repo = cache[summary.id], repo.docDir == directory, cacheFingerprints[summary.id] == document.fingerprint { return repo }
        let repo = try PECSRepo.load(directory: directory)
        guard repo.id == summary.id else { refresh(); throw LibraryError.invalid("Board changed; please select it again") }
        if cache.count >= 3 { cache.removeAll(); cacheFingerprints.removeAll() }
        cache[repo.id] = repo
        cacheFingerprints[repo.id] = document.fingerprint
        return repo
    }
    @discardableResult func createEmptyRepo(directoryURL: URL? = nil, setActive: Bool) throws -> PECSRepo {
        let directory = directoryURL ?? documentsDirectory.appendingPathComponent("topics/\(UUID().uuidString)")
        let topic = Topic(topicName: newTopicName, topicCategory: .other, topicImage: PersistenceSettings.shared.defaultTopicIcon, topicDirectoryName: directory.lastPathComponent, hasSkin: false, hasSoundTheme: false)
        let repo = try PECSRepo(directoryForNewTopic: directory, topic: topic)
        _ = PageLayoutState(newTopic: repo)
        if cache.count >= 3 { cache.removeAll(); cacheFingerprints.removeAll() }
        cache[repo.id] = repo
        if setActive { publishedCurrentTopic = repo }
        refresh(); return repo
    }
    func createChild(of parent: PECSRepo) throws -> PECSRepo {
        try parent.saveToFile()
        let repo = try createEmptyRepo(directoryURL: parent.docDir.appendingPathComponent("children/\(UUID().uuidString)"), setActive: false)
        parent.hierarchy.childOrder.append(repo.id); try parent.saveToFile(); return repo
    }
    @discardableResult func restoreDefaultBoards(from source: URL, language: String) throws -> Int {
        let count = try StarterBoardInstaller.restoreMissing(from: source, into: documentsDirectory, language: language).count
        refresh(); return count
    }
    private var newTopicName: String {
        let base = PersistenceSettings.shared.newTopicName
        var name = base; var number = allBoards.count
        while allBoards.contains(where: { $0.title == name }) { number += 1; name = "\(base) \(number)" }
        return name
    }
    @discardableResult func duplicateTopic(repo: PECSRepo) async throws -> PECSRepo {
        try repo.saveToFile()
        guard let store else { throw LibraryError.invalid("Library is unavailable") }
        _ = try await store.reconcile()
        let id = try await store.copy(repo.id)
        let directory = try await store.location(id)
        let copy = try PECSRepo.load(directory: directory)
        var number = 1
        var name = PersistenceSettings.shared.makeTopicCopyName(originalName: repo.topicName, copyNumber: number)
        while allBoards.contains(where: { $0.title == name }) { number += 1; name = PersistenceSettings.shared.makeTopicCopyName(originalName: repo.topicName, copyNumber: number) }
        copy.topicName = name; try copy.saveToFile()
        refresh(); return copy
    }
    @discardableResult func duplicateTopic(repo: BoardSummary) async throws -> PECSRepo { try await duplicateTopic(repo: open(repo)) }
    func deleteTopic(_ repo: PECSRepo) { delete(id: repo.id) }
    func deleteTopic(_ summary: BoardSummary) { delete(id: summary.id) }
    func deleteCurrentTopic() { if let id = currentTopic?.id { delete(id: id) } }
    private func delete(id: UUID) {
        guard let store else { return }
        Task { @MainActor in
            do {
                let directory = try await store.location(id)
                let removesActive = currentTopic.map { $0.docDir.path == directory.path || $0.docDir.path.hasPrefix(directory.path + "/") } ?? false
                try await store.delete(id); cache.removeAll(); cacheFingerprints.removeAll()
                if removesActive { currentTopic = nil }
                refresh()
            }
            catch { ErrorHandler.shared.setLastError(error) }
        }
    }
    func move(_ id: UUID, parent: UUID?) {
        guard let store else { return }
        Task { @MainActor in
            do {
                if let currentTopic { try currentTopic.saveToFile() }
                try await store.move(id,parent: parent)
                for repo in cache.values {
                    if let location = try? await store.location(repo.id) { repo.relocate(to: location) }
                }
                if let currentTopic, let location = try? await store.location(currentTopic.id) { currentTopic.relocate(to: location) }
                refresh()
            }
            catch { ErrorHandler.shared.setLastError(error) }
        }
    }
    @discardableResult func moveTopic(id: UUID, to targetID: UUID) -> Bool {
        guard id != targetID, let source = publishedTopics.firstIndex(where: { $0.id == id }), let destination = publishedTopics.firstIndex(where: { $0.id == targetID }) else { return false }
        let item = publishedTopics.remove(at: source); publishedTopics.insert(item, at: destination); saveTopicOrder(); return true
    }
    @discardableResult func moveTopic(id: UUID, by offset: Int) -> Bool {
        guard let source = publishedTopics.firstIndex(where: { $0.id == id }), publishedTopics.indices.contains(source + offset) else { return false }
        publishedTopics.swapAt(source,source+offset); saveTopicOrder(); return true
    }
    private func saveTopicOrder() { UserDefaults.standard.set(publishedTopics.map { $0.id.uuidString }, forKey: Self.topicOrderDefaultsKey) }
    private static let starterOrder: [String] = {
        guard let source = Bundle.main.url(forResource: "StarterBoards", withExtension: nil) else { return [] }
        let names = (try? StarterBoardInstaller.orderedDirectoryNames(from: source, language: "en")) ?? []
        let aliases = (try? StarterBoardInstaller.legacyBoards(from: source)) ?? [:]
        return names.flatMap { name in
            [name] + aliases.filter { $0.value.canonicalDirectory == name }.map(\.key).sorted()
        }
    }()

    static func orderedTopics(_ topics: [PECSRepo], savedOrder: [String]) -> [PECSRepo] {
        // A saved user order always takes precedence over the starter catalog.
        let positions = Dictionary((savedOrder + starterOrder).enumerated().map { ($1, $0) },
                                   uniquingKeysWith: min)

        return topics.enumerated().sorted { lhs, rhs in
            let lhsPosition = positions[topicOrderKey(lhs.element)]
            let rhsPosition = positions[topicOrderKey(rhs.element)]
            switch (lhsPosition, rhsPosition) {
            case let (lhs?, rhs?): return lhs < rhs
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return lhs.offset < rhs.offset
            }
        }.map(\.element)
    }

    private static func topicOrderKey(_ topic: PECSRepo) -> String { topic.topicDirectoryName ?? topic.docDir.lastPathComponent }
}
extension BoardSummary { var topicName: String { title } }

private final class BoardLibraryPresenter: NSObject, NSFilePresenter {
    let presentedItemURL: URL?
    let presentedItemOperationQueue: OperationQueue
    private let changed: () -> Void
    init(root: URL, changed: @escaping () -> Void) {
        presentedItemURL = root; self.changed = changed
        presentedItemOperationQueue = OperationQueue()
        presentedItemOperationQueue.maxConcurrentOperationCount = 1
        presentedItemOperationQueue.qualityOfService = .utility
        super.init(); NSFileCoordinator.addFilePresenter(self)
    }
    deinit { NSFileCoordinator.removeFilePresenter(self) }
    func presentedSubitemDidChange(at url: URL) { notify() }
    func presentedItemDidChange() { notify() }
    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) { notify() }
    private func notify() { DispatchQueue.main.async { [weak self] in self?.changed() } }
}
