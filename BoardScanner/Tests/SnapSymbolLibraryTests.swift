import Foundation
import SQLite3
import UIKit
import XCTest
@testable import BoardScanner

final class SnapSymbolLibraryTests: XCTestCase {
    func testSupplementPreservesEmbeddedArtworkAndRoundTrips() async throws {
        let input = try SnapTestFixture.make()
        let library = try makeLibrary()
        defer { try? FileManager.default.removeItem(at: input); try? FileManager.default.removeItem(at: library) }
        let before = try Data(contentsOf: library)
        let original = try await TDSnapImporter.load(input)
        let set = try await SnapSymbolLibrary.supplement(original, from: library)
        XCTAssertEqual(original.unavailableImageCount, 2)
        XCTAssertEqual(set.unavailableImageCount, 1)
        XCTAssertEqual(set.assets["SYM:999"]?.data, MetafileFixture.redRectangle)
        XCTAssertNotNil(set.assets["SYM:999"]?.previewPNG)
        XCTAssertEqual(set.assets["1"]?.data, original.assets["1"]?.data)
        XCTAssertEqual(set.buttons["30"]?.assetKey, "SYM:999")
        XCTAssertNil(set.assets["SYM:123"])
        let restored = try BoardStorage.decodePageSet(BoardDocument(pageSet: set).encoded())
        XCTAssertEqual(restored.assets["SYM:999"]?.previewPNG, set.assets["SYM:999"]?.previewPNG)
        let repeated = try await SnapSymbolLibrary.supplement(set, from: library)
        XCTAssertEqual(repeated.assets.count, set.assets.count)
        XCTAssertEqual(try Data(contentsOf: library), before)
    }

    func testInvalidMissingMalformedAndCancellation() async throws {
        let input = try SnapTestFixture.make()
        let library = try makeLibrary(malformed: true)
        defer { try? FileManager.default.removeItem(at: input); try? FileManager.default.removeItem(at: library) }
        let original = try await TDSnapImporter.load(input)
        do { _ = try await SnapSymbolLibrary.supplement(original, from: input); XCTFail("Wrong schema accepted") }
        catch LibraryError.invalid { }
        let set = try await SnapSymbolLibrary.supplement(original, from: library)
        XCTAssertEqual(set.unavailableImageCount, 2)
        XCTAssertNotNil(set.assets["SYM:999"]?.previewFailure)
        let task = Task {
            while !Task.isCancelled { await Task.yield() }
            return try await SnapSymbolLibrary.supplement(original, from: library)
        }
        task.cancel()
        do { _ = try await task.value; XCTFail("Expected cancellation") } catch is CancellationError { }
    }

    func testSuppliedLibraryRecoveryAndExport() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let input = env["TD_SNAP_FIXTURE"], !input.isEmpty,
              let library = env["TD_SYMBOL_LIBRARY"], !library.isEmpty else { throw XCTSkip("Supply TD_SNAP_FIXTURE and TD_SYMBOL_LIBRARY") }
        let original = try await TDSnapImporter.load(URL(fileURLWithPath: input))
        let set = try await SnapSymbolLibrary.supplement(original, from: URL(fileURLWithPath: library))
        let recovered = set.assets.filter { original.assets[$0.key] == nil }
        print("Recovered library assets: \(recovered.count), previews: \(recovered.values.filter { $0.previewPNG != nil }.count), failures: \(recovered.filter { $0.value.previewPNG == nil }.map { ($0.key, $0.value.previewFailure ?? "") })")
        XCTAssertEqual(recovered.count, 147)
        XCTAssertEqual(set.unavailableImageCount, 1)
        XCTAssertEqual(set.missingAssetReferenceCount, 1)
        XCTAssertEqual(set.renderedAssetCount, 2911)
        XCTAssertNil(set.assets["SYM:57513"])
        XCTAssertNotNil(set.assets["SYM:43560"]?.previewPNG)
        XCTAssertNotNil(set.assets["SYM:43602"]?.previewPNG)
        // These source symbols exist but contain white glyphs on transparency.
        // Their card colours provide contrast; they are not missing artwork.
        for key in ["1495", "1496", "SYM:43561", "SYM:43557", "SYM:43560"] {
            let data = try XCTUnwrap(set.assets[key]?.previewPNG, key)
            XCTAssertNotNil(UIImage(data: data)?.cgImage, key)
        }
        for (key, asset) in original.assets { XCTAssertEqual(set.assets[key]?.data, asset.data); XCTAssertEqual(set.assets[key]?.previewPNG, asset.previewPNG) }
        XCTAssertEqual(set.pages.map(\.id), original.pages.map(\.id))
        XCTAssertEqual(set.linkCount, 700)
        let data = try BoardDocument(pageSet: set).encoded()
        let output = (env["TD_RECOVERED_OUTPUT"].flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) })
            ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".boardscan")
        try data.write(to: output, options: .atomic)
        let restored = try await BoardStorage.openDocument(output)
        XCTAssertEqual(restored.pageSet?.unavailableImageCount, 1)
        XCTAssertEqual(restored.pageSet?.assets["SYM:43560"]?.previewPNG, set.assets["SYM:43560"]?.previewPNG)
        print("Recovered board export: \(data.count) bytes at \(output.path)")
        if env["TD_RECOVERED_OUTPUT"]?.isEmpty != false { try? FileManager.default.removeItem(at: output) }
    }

    func testRememberedLibrarySurvivesSourceRemovalAndNewStore() async throws {
        let input = try SnapTestFixture.make()
        let source = try makeLibrary()
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: root)
        }
        let original = try await TDSnapImporter.load(input)
        let store = SavedSymbolLibraries(root: root)
        let empty = try await store.supplement(original)
        XCTAssertEqual(empty.pageSet.unavailableImageCount, 2)
        _ = try await store.rememberAndSupplement(original, from: source)
        _ = try await store.rememberAndSupplement(original, from: source)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path).count, 1)
        try FileManager.default.removeItem(at: source)
        let reopened = try await SavedSymbolLibraries(root: root).supplement(original)
        XCTAssertEqual(reopened.pageSet.unavailableImageCount, 1)
        XCTAssertEqual(reopened.failedLibraries, 0)
        XCTAssertEqual(reopened.pageSet.assets["SYM:999"]?.data, MetafileFixture.redRectangle)
        try Data("broken library".utf8).write(to: root.appendingPathComponent("broken.db3"))
        let partial = try await store.supplement(original)
        XCTAssertEqual(partial.pageSet.unavailableImageCount, 1)
        XCTAssertEqual(partial.failedLibraries, 1)
    }

    func testInvalidLibraryIsNotRemembered() async throws {
        let input = try SnapTestFixture.make()
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: input); try? FileManager.default.removeItem(at: root) }
        let original = try await TDSnapImporter.load(input)
        do {
            _ = try await SavedSymbolLibraries(root: root).rememberAndSupplement(original, from: input)
            XCTFail("Wrong schema accepted")
        } catch LibraryError.invalid { }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path).count, 0)
        let task = Task {
            while !Task.isCancelled { await Task.yield() }
            return try await SavedSymbolLibraries(root: root).rememberAndSupplement(original, from: input)
        }
        task.cancel()
        do { _ = try await task.value; XCTFail("Expected cancellation") } catch is CancellationError { }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path).count, 0)
    }

    private func makeLibrary(malformed: Bool = false) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".db3")
        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &db), SQLITE_OK)
        defer { sqlite3_close(db) }
        let data = malformed ? Data([0xd7, 0xcd, 0xc6, 0x9a]) : MetafileFixture.redRectangle
        let hex = data.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(sqlite3_exec(db, "CREATE TABLE Symbol(SymbolId INTEGER PRIMARY KEY, Image BLOB); INSERT INTO Symbol VALUES(999,X'\(hex)'),(123,X'\(hex)');", nil, nil, nil), SQLITE_OK)
        return url
    }
}
