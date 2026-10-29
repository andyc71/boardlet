import XCTest
@testable import BoardScanner

@MainActor
final class ScannerLibraryTests: XCTestCase {
    func testLegacyMigrationCopiesOriginalAndDoesNotResurrectDeletedBoard() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("latest.boardscan")
        let original = try LibraryFixture.document("Legacy").encoded()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try original.write(to: legacy)
        let libraryRoot = root.appendingPathComponent("Library")
        let model = ScannerModel(libraryRoot: libraryRoot, legacySaveURL: legacy)
        await model.restore()
        XCTAssertEqual(model.document?.title, "Legacy")
        XCTAssertEqual(try Data(contentsOf: legacy), original)
        let entry = try XCTUnwrap(model.libraryEntries.first)
        model.delete(entry)
        await idle(model)
        XCTAssertNil(model.document)
        let relaunched = ScannerModel(libraryRoot: libraryRoot, legacySaveURL: legacy)
        await relaunched.restore()
        XCTAssertNil(relaunched.document)
        XCTAssertEqual(relaunched.deletedEntries.count, 1)
    }

    func testAutosavedEditsSurviveSwitchAndRelaunch() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = ScannerModel(libraryRoot: root, legacySaveURL: root.appendingPathComponent("missing"))
        let first = UUID(), second = UUID()
        try await model.library.save(LibraryFixture.document("First"), id: first)
        try await model.library.save(LibraryFixture.document("Second"), id: second)
        model.openSaved(first)
        await idle(model)
        var button = try XCTUnwrap(model.pageSet?.buttons["word"])
        button.message = "My edited message"
        model.update(button)
        await idle(model)
        XCTAssertFalse(model.dirty)
        model.openSaved(second)
        await idle(model)
        model.openSaved(first)
        await idle(model)
        XCTAssertEqual(model.pageSet?.buttons["word"]?.message, "My edited message")
        let relaunched = ScannerModel(libraryRoot: root, legacySaveURL: root.appendingPathComponent("missing"))
        await relaunched.restore()
        XCTAssertEqual(relaunched.pageSet?.buttons["word"]?.message, "My edited message")
        XCTAssertEqual(relaunched.libraryID, first)
    }

    func testFailedSaveBlocksReplacementAndKeepsEditsInMemory() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let blocked = root.appendingPathComponent("not-a-directory")
        try Data("occupied".utf8).write(to: blocked)
        let incoming = root.appendingPathComponent("incoming.boardscan")
        try LibraryFixture.document("New board").encoded().write(to: incoming)
        let model = ScannerModel(libraryRoot: blocked, legacySaveURL: root.appendingPathComponent("missing"))
        model.pageSet = LibraryFixture.document("Unsaved edits").pageSet
        model.dirty = true
        model.open(incoming)
        await idle(model)
        XCTAssertEqual(model.document?.title, "Unsaved edits")
        XCTAssertTrue(model.dirty)
        XCTAssertNotNil(model.error)
    }

    func testFailedImportDoesNotReplaceCurrentBoardOrCreatePhantomEntry() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = ScannerModel(libraryRoot: root, legacySaveURL: root.appendingPathComponent("missing"))
        let first = UUID()
        try await model.library.save(LibraryFixture.document("Current"), id: first)
        model.openSaved(first)
        await idle(model)
        let invalid = root.appendingPathComponent("invalid.boardscan")
        try Data("not a board".utf8).write(to: invalid)
        model.open(invalid)
        await idle(model)
        XCTAssertEqual(model.document?.title, "Current")
        XCTAssertEqual(model.libraryID, first)
        XCTAssertNotNil(model.error)
        let entries = try await model.library.entries()
        XCTAssertEqual(entries.count, 1)
    }

    func testImportBeforeStartupRestoreStillMigratesLegacySave() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let legacy = root.appendingPathComponent("latest.boardscan")
        let incoming = root.appendingPathComponent("incoming.boardscan")
        let original = try LibraryFixture.document("Legacy").encoded()
        try original.write(to: legacy)
        try LibraryFixture.document("Incoming").encoded().write(to: incoming)
        let model = ScannerModel(libraryRoot: root.appendingPathComponent("Library"), legacySaveURL: legacy)
        model.open(incoming)
        // Simulate SwiftUI's later restoration task while Open In is already active.
        await model.restore()
        await idle(model)
        XCTAssertEqual(model.document?.title, "Incoming")
        XCTAssertEqual(Set(model.libraryEntries.map(\.title)), ["Legacy", "Incoming"])
        XCTAssertEqual(try Data(contentsOf: legacy), original)
    }

    func testInvalidOpenBeforeStartupRestoreRetainsSelectedBoard() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = ScannerModel(libraryRoot: root, legacySaveURL: root.appendingPathComponent("missing"))
        let selected = UUID()
        try await model.library.save(LibraryFixture.document("My communication board"), id: selected)
        try await model.library.select(selected)
        let invalid = root.appendingPathComponent("invalid.boardscan")
        try Data("not a board".utf8).write(to: invalid)
        model.open(invalid)
        // The incoming URL starts first, before SwiftUI's restoration task.
        await model.restore()
        await idle(model)
        XCTAssertEqual(model.libraryID, selected)
        XCTAssertEqual(model.document?.title, "My communication board")
        XCTAssertNotNil(model.error, "Keep the import error available to the user")
        XCTAssertEqual(model.libraryEntries.count, 1)
    }

    private func idle(_ model: ScannerModel) async {
        let deadline = Date().addingTimeInterval(10)
        while model.busy && Date() < deadline { try? await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(model.busy, "Operation did not finish")
    }
}
