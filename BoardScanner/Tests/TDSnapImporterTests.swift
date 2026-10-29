import XCTest
import SQLite3
@testable import BoardScanner

final class TDSnapImporterTests: XCTestCase {
    func testSourceColoursAndGridSurviveArchiveAndMissingStyleRemainsCompatible() async throws {
        let input = try SnapTestFixture.make(extraSQL: """
            CREATE TABLE ElementReference(Id, BackgroundColor, ForegroundColor);
            INSERT INTO ElementReference VALUES(10,-11514285,-132102),(20,NULL,NULL);
            ALTER TABLE Button ADD COLUMN BorderColor;
            UPDATE Button SET BorderColor=-7828852 WHERE Id=1;
            ALTER TABLE Page ADD COLUMN BackgroundColor;
            UPDATE Page SET BackgroundColor=-14146006 WHERE Id=1;
            ALTER TABLE PageSetProperties ADD COLUMN PageBackgroundColor;
            UPDATE PageSetProperties SET PageBackgroundColor=-14146006;
            """)
        defer { try? FileManager.default.removeItem(at: input) }
        let set = try await TDSnapImporter.load(input)
        let restored = try BoardStorage.decodePageSet(BoardDocument(pageSet: set).encoded())
        XCTAssertEqual(restored.buttons["10"]?.backgroundARGB, 0xff504e53)
        XCTAssertEqual(restored.buttons["10"]?.foregroundARGB, 0xfffdfbfa)
        XCTAssertEqual(restored.buttons["10"]?.borderARGB, 0xff888a8c)
        XCTAssertEqual(restored.page("home")?.backgroundARGB, 0xff28262a)
        XCTAssertEqual(restored.backgroundARGB, 0xff28262a)
        XCTAssertNil(restored.buttons["20"]?.backgroundARGB)
        XCTAssertEqual(restored.page("home")?.preferredLayout?.columns, 3)
        // Older archives have no colour fields and remain readable.
        let old = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: old) }
        let legacy = try await TDSnapImporter.load(old)
        XCTAssertNil(try BoardStorage.decodePageSet(BoardDocument(pageSet: legacy).encoded()).backgroundARGB)
    }
    func testHierarchyKeepsCyclesSharedChildrenDisconnectedAndMissingPages() async throws {
        let url = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: url) }
        let set = try await TDSnapImporter.load(url)
        XCTAssertEqual(set.pages.count, 4)
        XCTAssertEqual(set.homePageID, "home")
        XCTAssertEqual(set.page("home")?.preferredLayout?.columns, 3)
        XCTAssertEqual(set.page("home")?.layouts.count, 2)
        XCTAssertEqual(set.buttons["10"]?.destinationIDs, ["child"])
        XCTAssertEqual(set.buttons["20"]?.destinationIDs, ["home", "shared", "missing"])
        XCTAssertEqual(set.buttons["30"]?.destinationIDs, ["child"])
        XCTAssertNotNil(set.page("orphan"))
        XCTAssertEqual(set.missingLinkCount, 1)
        XCTAssertEqual(set.buttons["10"]?.label, "Go to café 🗣️")
        XCTAssertEqual(set.buttons["10"]?.message, "Hello")
        let placements = try XCTUnwrap(set.page("home")?.preferredLayout?.placements)
        XCTAssertEqual(placements[0].columnSpan, 2)
        XCTAssertEqual(placements[1].row, 3) // scrolling content outside the 2-row viewport
        XCTAssertFalse(placements[1].visible)
        XCTAssertEqual(set.page("home")?.preferredLayout?.contentRows, 4)
        XCTAssertEqual(set.assets["1"]?.data, Data([0xd7, 0xcd, 0xc6, 0x9a]))
        XCTAssertNil(set.assets["1"]?.previewPNG)
        XCTAssertEqual(set.unavailableImageCount, 2) // retained WMF and absent library symbol
    }

    func testWholePageSetExportSaveAndRestore() async throws {
        let input = try SnapTestFixture.make()
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".boardscan")
        defer { try? FileManager.default.removeItem(at: input); try? FileManager.default.removeItem(at: output) }
        let set = try await TDSnapImporter.load(input)
        let document = BoardDocument(pageSet: set)
        try await BoardStorage.saveDocument(document, to: output)
        let reopened = try await BoardStorage.openDocument(output)
        let restored = try XCTUnwrap(reopened.pageSet)
        XCTAssertNil(reopened.board)
        XCTAssertEqual(restored.pages.map(\.id), set.pages.map(\.id))
        XCTAssertEqual(restored.buttons["20"]?.destinationIDs, set.buttons["20"]?.destinationIDs)
        XCTAssertEqual(restored.buttons["20"]?.serializedCommands, set.buttons["20"]?.serializedCommands)
        XCTAssertEqual(restored.assets["1"]?.data, set.assets["1"]?.data)
    }

    func testMalformedAndUnsupportedFilesAreRejected() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sps")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not SQLite".utf8).write(to: url)
        do { _ = try await TDSnapImporter.load(url); XCTFail("Expected rejection") }
        catch ScanError.invalidPageSet { }
        let malformed = try SnapTestFixture.make(extraSQL: "UPDATE ElementPlacement SET GridSpan='-1,2'")
        defer { try? FileManager.default.removeItem(at: malformed) }
        do { _ = try await TDSnapImporter.load(malformed); XCTFail("Expected rejection") }
        catch ScanError.invalidPageSet { }
    }

    func testInvalidHomeDuplicateIDsAndInvalidArchiveAreRejected() async throws {
        for sql in ["UPDATE PageSetProperties SET DefaultHomePageUniqueId='absent'", "UPDATE Page SET UniqueId='same'"] {
            let url = try SnapTestFixture.make(extraSQL: sql)
            defer { try? FileManager.default.removeItem(at: url) }
            do { _ = try await TDSnapImporter.load(url); XCTFail("Expected rejection") }
            catch ScanError.invalidPageSet { }
        }
        let url = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: url) }
        var archive = ScannerArchive(pageSet: try await TDSnapImporter.load(url))
        archive.version = 99
        XCTAssertThrowsError(try BoardStorage.decodePageSet(JSONEncoder().encode(archive)))
    }

    func testCancellationAndReadOnlySource() async throws {
        let url = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: url) }
        let before = try Data(contentsOf: url)
        _ = try await TDSnapImporter.load(url)
        XCTAssertEqual(try Data(contentsOf: url), before)
        let task = Task { try await TDSnapImporter.load(url) }
        task.cancel()
        do { _ = try await task.value; XCTFail("Expected cancellation") }
        catch is CancellationError { }
    }

    func testNestedConditionalDestinationsAreExtractedWithoutRunningCommands() {
        XCTAssertEqual(TDSnapImporter.commandDestinations(#"{"$values":[{"ConditionalActions":{"$values":[{"Action":{"LinkedPageId":"ABC"}},{"Action":{"LinkedPageId":"DEF"}}]}}]}"#), ["abc", "def"])
    }

    /// Optional local integration check; never embeds the user's page set in the repository.
    func testSuppliedPageSet() async throws {
        guard let path = ProcessInfo.processInfo.environment["TD_SNAP_FIXTURE"], !path.isEmpty else {
            throw XCTSkip("Set TD_SNAP_FIXTURE in the test environment for the supplied-file integration check.")
        }
        let set = try await TDSnapImporter.load(URL(fileURLWithPath: path))
        for id in ["2804", "2805", "2806", "2807"] {
            let button = try XCTUnwrap(set.buttons.values.first { $0.id == id })
            XCTAssertEqual(button.backgroundARGB, 0xff504e53)
            XCTAssertEqual(button.foregroundARGB, 0xfffdfbfa)
        }
        XCTAssertEqual(set.page(set.homePageID)?.preferredLayout?.columns, 11)
        XCTAssertEqual(set.page(set.homePageID)?.preferredLayout?.rows, 6)
        XCTAssertEqual(set.pages.count, 307)
        XCTAssertEqual(set.pages.reduce(0) { $0 + $1.layouts.count }, 428)
        XCTAssertEqual(set.pages.flatMap(\.layouts).reduce(0) { $0 + $1.placements.count }, 6687)
        XCTAssertEqual(set.buttons.count, 5382)
        XCTAssertEqual(set.assets.count, 2764)
        XCTAssertEqual(set.assets.values.filter { $0.previewPNG != nil }.count, 2764)
        XCTAssertEqual(set.unavailableAssetCount, 0)
        XCTAssertEqual(set.assets.values.filter { MetafileRenderer.isMetafile($0.data) && $0.previewPNG != nil }.count, 2738)
        XCTAssertEqual(set.unavailableImageCount, 419)
        XCTAssertEqual(set.missingAssetReferenceCount, 419)
        XCTAssertEqual(set.linkCount, 700)
        XCTAssertEqual(set.page(set.homePageID)?.title, "Home Page")
        XCTAssertEqual(set.page(set.homePageID)?.preferredLayout?.columns, 11)
        XCTAssertEqual(set.page(set.homePageID)?.preferredLayout?.rows, 6)
        XCTAssertEqual(set.missingLinkCount, 165)
        XCTAssertEqual(set.unavailableNavigationLinkCount, 0)
        let pageIDs = Set(set.pages.map(\.id))
        let retainedMissing = set.buttons.values.filter { button in
            button.destinationIDs.contains { !pageIDs.contains($0) }
        }
        XCTAssertEqual(retainedMissing.filter { SnapCommunicationBehavior.resolve($0) == .action(.home) }.count, 164)
        XCTAssertEqual(retainedMissing.filter { SnapCommunicationBehavior.resolve($0) == .action(.keyboard) }.count, 1)
        let exported = try BoardDocument(pageSet: set).encoded()
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".boardscan")
        defer { try? FileManager.default.removeItem(at: output) }
        try exported.write(to: output)
        let reopened = try await BoardStorage.openDocument(output)
        let restored = try XCTUnwrap(reopened.pageSet)
        XCTAssertEqual(restored.pages.count, 307)
        XCTAssertEqual(restored.linkCount, set.linkCount)
        XCTAssertEqual(restored.missingLinkCount, 165)
        XCTAssertEqual(restored.unavailableNavigationLinkCount, 0)
        XCTAssertEqual(restored.renderedAssetCount, 2764)
        XCTAssertEqual(restored.unavailableImageCount, set.unavailableImageCount)
        XCTAssertLessThan(exported.count, 75_000_000)
        for (key, asset) in set.assets {
            XCTAssertEqual(restored.assets[key]?.data, asset.data)
            XCTAssertEqual(restored.assets[key]?.previewPNG, asset.previewPNG)
        }
        print("TD Snap integration: \(set.pages.count) pages, \(set.linkCount) links, \(set.unavailableImageCount) unavailable images, \(exported.count) export bytes")
    }

}
