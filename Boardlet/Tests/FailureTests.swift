import Testing
import Foundation
@testable import Boardlet

@MainActor
struct FailureTests {
    @Test func leavingEditorCancelsPendingMicrophonePermission() async {
        let permission = PendingPermission()
        let audio = AudioService(recordPermission: { await permission.request() })
        let recording = Task { await audio.startRecording() }
        await permission.waitUntilRequested()
        audio.close()
        permission.respond(true)
        await recording.value
        #expect(!audio.recording)
        #expect(audio.notice == nil)
    }
    @Test func productionMigrationGateOnlyRunsForInPlaceUpgrades() async throws {
        let documents = URL.temporaryDirectory
        #expect(ProductionMigration.source(bundleID: "com.brightblue.boardlet.development", documents: documents, libraryExists: false) == nil)
        #expect(ProductionMigration.source(bundleID: "com.brightblue.EasyPECS", documents: documents, libraryExists: true) == nil)
        #expect(ProductionMigration.source(bundleID: "com.brightblue.EasyPECSPlus", documents: documents, libraryExists: false) == documents)
        let folder = try #require(Bundle(for: FixtureBundleMarker.self).url(forResource: "Fruit", withExtension: nil))
        let disk = LibraryDisk(root: documents.appendingPathComponent(UUID().uuidString))
        let store = BoardStore(storage: disk, mediaURL: disk.mediaURL, legacyMigrationRoot: folder)
        await store.load()
        #expect(store.loaded && store.boards.count == 1)
        let reopened = BoardStore(storage: disk, mediaURL: disk.mediaURL, legacyMigrationRoot: folder)
        await reopened.load()
        #expect(reopened.boards.map(\.id) == store.boards.map(\.id))
    }
    @Test func saveFailureIsVisibleAndRetryPersistsTheLatestEdit() async {
        let disk = FailingStorage(); let store = BoardStore(storage: disk, mediaURL: URL.temporaryDirectory)
        await store.load()
        let id = store.create(name: "Original", template: .blank)
        store.edit(id) { $0.name = "Latest" }
        await store.flush()
        #expect(store.error != nil)
        #expect(store.board(id)?.name == "Latest")
        await disk.allowSaving(); store.retrySave(); await store.flush()
        #expect(store.error == nil)
        #expect(await disk.saved?.boards.first?.name == "Latest")
    }
    @Test func failedLoadCannotOverwriteExistingLibrary() async {
        let disk = FailingStorage(failLoad: true); let store = BoardStore(storage: disk, mediaURL: URL.temporaryDirectory)
        await store.load(); store.retrySave(); await store.flush()
        #expect(store.loadFailed); #expect(store.loaded == false)
        #expect(await disk.saved == nil)
    }
    @Test func aiServiceUsesHTTPSAndValidatesResponses() async throws {
        let endpoint = try #require(URL(string: "https://example.invalid/symbols"))
        let service = AISymbolService(endpoint: endpoint, execute: { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let json = try JSONDecoder().decode([String: String].self, from: request.httpBody ?? Data())
            #expect(json["prompt"] == "Water")
            return (Data("{\"imageBase64\":\"AQID\"}".utf8), HTTPURLResponse(url: endpoint, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!)
        })
        #expect(try await service.generate(prompt: "Water") == Data([1,2,3]))
        let failed = AISymbolService(endpoint: endpoint, execute: { _ in (Data(), HTTPURLResponse(url: endpoint, statusCode: 503, httpVersion: nil, headerFields: nil)!) })
        await #expect(throws: (any Error).self) { try await failed.generate(prompt: "Water") }
        let insecure = AISymbolService(endpoint: URL(string: "http://example.invalid")!)
        await #expect(throws: (any Error).self) { try await insecure.generate(prompt: "Water") }
    }
    @Test func actualLegacyFixtureMigratesAllNineCardsInStoredOrder() async throws {
        let folder = try #require(Bundle(for: FixtureBundleMarker.self).url(forResource: "Fruit", withExtension: nil))
        let root = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let disk = LibraryDisk(root: root)
        let imported = try await LegacyImporter(storage: disk).importFolder(folder, existing: [])
        let board = try #require(imported.boards.first)
        #expect(board.name == "Fruit")
        #expect(board.cards.map(\.label) == ["apple", "pear", "apricot", "lemon", "plum", "grapes", "kiwi", "banana", "cherries"])
        #expect(board.print.columns == 3 && board.print.rows == 3)
        #expect(board.cover != nil)
        #expect(board.cards.allSatisfy { $0.image != nil })
    }
}
@MainActor private final class PendingPermission {
    private var response: CheckedContinuation<Bool, Never>?
    private var started: CheckedContinuation<Void, Never>?
    func request() async -> Bool {
        await withCheckedContinuation { continuation in
            response = continuation
            started?.resume(); started = nil
        }
    }
    func waitUntilRequested() async {
        if response != nil { return }
        await withCheckedContinuation { started = $0 }
    }
    func respond(_ value: Bool) { response?.resume(returning: value); response = nil }
}
private final class FixtureBundleMarker: NSObject { }
private actor FailingStorage: LibraryStorage {
    var failLoad: Bool
    var failSave = true
    var saved: Library?
    init(failLoad: Bool = false) { self.failLoad = failLoad }
    func load() throws -> Library { if failLoad { throw StorageError.corruptLibrary }; return Library() }
    func save(_ library: Library, revision: Int) throws { if failSave { throw CocoaError(.fileWriteOutOfSpace) }; saved = library }
    func storeAsset(_ data: Data, extension ext: String) throws -> String { "asset." + ext }
    func restoreBackup() throws -> Library { throw StorageError.corruptLibrary }
    func allowSaving() { failSave = false }
}
