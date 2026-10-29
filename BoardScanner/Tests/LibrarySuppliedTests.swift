import XCTest
@testable import BoardScanner

final class LibrarySuppliedTests: XCTestCase {
    func testSuppliedPageSetAndArtworkSurviveLibrarySaveAndReopen() async throws {
        guard let path = ProcessInfo.processInfo.environment["TD_SNAP_FIXTURE"], !path.isEmpty else {
            throw XCTSkip("Set TD_SNAP_FIXTURE to verify the full supplied page set in the library.")
        }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let original = try await TDSnapImporter.load(URL(fileURLWithPath: path))
        let id = UUID(), library = BoardLibrary(root: root)
        try await library.save(BoardDocument(pageSet: original), id: id)
        try await library.select(id)
        let reopened = try await BoardLibrary(root: root).load(id)
        let restored = try XCTUnwrap(reopened.document.pageSet)
        XCTAssertFalse(reopened.recovered)
        XCTAssertEqual(restored.pages.count, 307)
        XCTAssertEqual(restored.pages.map(\.id), original.pages.map(\.id))
        XCTAssertEqual(restored.buttons.mapValues(\.message), original.buttons.mapValues(\.message))
        XCTAssertEqual(restored.buttons.mapValues(\.destinationIDs), original.buttons.mapValues(\.destinationIDs))
        XCTAssertEqual(restored.assets.mapValues(\.data), original.assets.mapValues(\.data))
        XCTAssertEqual(restored.assets.mapValues(\.previewPNG), original.assets.mapValues(\.previewPNG))
        XCTAssertEqual(restored.linkCount, original.linkCount)
        XCTAssertEqual(restored.renderedAssetCount, 2_764)
    }
}
