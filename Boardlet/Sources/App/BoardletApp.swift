import SwiftUI

@main
struct BoardletApp: App {
    @StateObject private var store: BoardStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        var root = URL.documentsDirectory.appendingPathComponent("Boardlet", isDirectory: true)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            // Dedicated test library; production/development user data is never removed.
            let run = ProcessInfo.processInfo.environment["BOARDLET_TEST_RUN"] ?? "default"
            root = URL.documentsDirectory.appendingPathComponent("UITests-" + run, isDirectory: true)
        }
        #endif
        let disk = LibraryDisk(root: root)
        let legacy = ProductionMigration.source(bundleID: Bundle.main.bundleIdentifier, documents: .documentsDirectory,
                                                libraryExists: FileManager.default.fileExists(atPath: root.appendingPathComponent("library.json").path))
        _store = StateObject(wrappedValue: BoardStore(storage: disk, mediaURL: disk.mediaURL, legacyMigrationRoot: legacy))
    }
    var body: some Scene {
        WindowGroup {
            BoardsView().environmentObject(store)
                .tint(.blue)
                .task { await store.load() }
                .task(id: scenePhase) { if scenePhase != .active { await store.flush() } }
        }
    }
}
