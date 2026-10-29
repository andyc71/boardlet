import XCTest
@testable import BoardScanner

final class BoardLibraryTests: XCTestCase {
    func testMultipleBoardsAndSelectedBoardSurviveNewLibraryInstance() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let library = BoardLibrary(root: root)
        let first = UUID(), second = UUID()
        try await library.save(LibraryFixture.document("Meals"), id: first)
        try await library.save(LibraryFixture.document("Outdoors"), id: second)
        try await library.select(first)
        let reopened = BoardLibrary(root: root)
        let entries = try await reopened.entries()
        let selected = try await reopened.selectedID()
        let one = try await reopened.load(first), two = try await reopened.load(second)
        XCTAssertEqual(Set(entries.map(\.title)), ["Meals", "Outdoors"])
        XCTAssertEqual(selected, first)
        XCTAssertEqual(one.document.title, "Meals")
        XCTAssertEqual(two.document.title, "Outdoors")
    }

    func testCorruptLatestRevisionRecoversPreviousAndCanSaveAgain() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let library = BoardLibrary(root: root), id = UUID()
        try await library.save(LibraryFixture.document("Original"), id: id)
        try await library.save(LibraryFixture.document("Latest"), id: id)
        let folder = root.appendingPathComponent("Boards/" + id.uuidString)
        let record = try JSONDecoder().decode(LibraryRecord.self, from: Data(contentsOf: folder.appendingPathComponent("index.json")))
        try Data("broken".utf8).write(to: folder.appendingPathComponent(record.current.id.uuidString + ".boardscan"))
        let recovered = try await library.load(id)
        XCTAssertTrue(recovered.recovered)
        XCTAssertEqual(recovered.document.title, "Original")
        try await library.save(recovered.document.renamed("Recovered and edited"), id: id)
        let reopened = try await BoardLibrary(root: root).load(id)
        XCTAssertFalse(reopened.recovered)
        XCTAssertEqual(reopened.document.title, "Recovered and edited")
    }

    func testCorruptIndexUsesBackupAndUnrecoverableEntryRemainsVisible() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let library = BoardLibrary(root: root), id = UUID()
        try await library.save(LibraryFixture.document("Original"), id: id)
        try await library.save(LibraryFixture.document("Changed"), id: id)
        let folder = root.appendingPathComponent("Boards/" + id.uuidString)
        try Data("broken".utf8).write(to: folder.appendingPathComponent("index.json"))
        let recovered = try await library.load(id)
        XCTAssertTrue(recovered.recovered)
        XCTAssertEqual(recovered.document.title, "Original")
        try Data("broken".utf8).write(to: folder.appendingPathComponent("backup.json"))
        let entries = try await library.entries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.id, id)
        do { _ = try await library.load(id); XCTFail("Expected an unreadable board error") }
        catch { XCTAssertTrue(error is BoardLibraryError) }
    }

    func testInvalidAndCancelledSavesDoNotReplaceSavedRevision() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let library = BoardLibrary(root: root), id = UUID()
        try await library.save(LibraryFixture.document("Original"), id: id)
        var invalid = LibraryFixture.document("Invalid")
        invalid.pageSet?.pages = []
        do { try await library.save(invalid, id: id); XCTFail("Expected invalid document") }
        catch { }
        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await library.save(LibraryFixture.document("Cancelled"), id: id)
        }
        do { _ = try await cancelled.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        let saved = try await library.load(id)
        XCTAssertEqual(saved.document.title, "Original")
    }

    func testDeleteAndRestoreKeepBoardAndClearSelection() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let library = BoardLibrary(root: root), id = UUID()
        try await library.save(LibraryFixture.document("Meals"), id: id)
        try await library.select(id)
        try await library.delete(id)
        let active = try await library.entries(), deleted = try await library.entries(deleted: true)
        let selected = try await library.selectedID()
        XCTAssertTrue(active.isEmpty)
        XCTAssertEqual(deleted.first?.title, "Meals")
        XCTAssertNil(selected)
        try await library.restore(id)
        let restored = try await library.load(id)
        XCTAssertEqual(restored.document.title, "Meals")
        let remaining = try await library.entries(deleted: true)
        XCTAssertTrue(remaining.isEmpty)
    }

    private func temporaryRoot() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) }
}
