import XCTest
@testable import BoardLibrary

final class BoardLibraryTests: XCTestCase {
    var base: URL!
    override func setUpWithError() throws { base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true) }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: base) }
    @discardableResult func board(_ path: String, id: UUID = UUID(), title: String = "Home", cards: Int = 1) throws -> UUID {
        let directory = base.appendingPathComponent("topics/\(path)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let json: [String: Any] = ["version":2,"id":id.uuidString,"topic":["topicName":title,"imageFileName":"images/cover.png"],"photos":["photoItems":(0..<cards).map { i in ["id":UUID().uuidString,"title":"Apple \(i)","imageFileName":"images/\(i).png"] }]]
        try JSONSerialization.data(withJSONObject: json).write(to: directory.appendingPathComponent("index.json"))
        return id
    }
    func store() throws -> BoardLibraryStore { try BoardLibraryStore(root: base.appendingPathComponent("topics"), database: base.appendingPathComponent("cache/index.sqlite"), language:"en") }
    func testReaderNeverNeedsPixelsAndDoesNotRewriteLegacy() throws {
        try board("old")
        let url = base.appendingPathComponent("topics/old")
        let before = try Data(contentsOf: url.appendingPathComponent("index.json"))
        let doc = try BoardDocumentReader.read(url, relativePath: "old")
        XCTAssertEqual(doc.version,2); XCTAssertEqual(doc.cards.count,1)
        XCTAssertEqual(try Data(contentsOf: url.appendingPathComponent("index.json")),before)
    }
    func testBoundariesAndSearch() async throws {
        let root = try board("ES",title:"ES")
        let child = try board("ES/children/Images",title:"Images")
        try board("ES/images/ignored",title:"Hidden")
        let library = try store(); let snapshot = try await library.reconcile()
        XCTAssertEqual(snapshot.boards.count,2, snapshot.diagnostics.joined(separator:"; "))
        XCTAssertEqual(snapshot.boards.first { $0.id == child }?.parentID,root)
        let result = try await library.search("App",scope:root)
        XCTAssertEqual(result.count,2)
        XCTAssertTrue(result.contains { $0.breadcrumb == "ES › Images" })
        let hidden = try await library.search("Hidden"); XCTAssertTrue(hidden.isEmpty)
    }
    func testSearchImageReferencesFollowLanguageAndMovesWithoutReadingPixels() async throws {
        let parent = try board("parent", title: "Parent")
        let child = try board("child", title: "Child")
        let manifest = base.appendingPathComponent("topics/child/index.json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: manifest)) as! [String: Any]
        var photos = json["photos"] as! [String: Any]
        var items = photos["photoItems"] as! [[String: Any]]
        items[0]["imageOverrides"] = ["es": "images/spanish.png"]
        photos["photoItems"] = items; json["photos"] = photos
        json["coverImagePaths"] = ["es": "images/spanish-cover.png"]
        let data = try JSONSerialization.data(withJSONObject: json)
        try data.write(to: manifest)
        let library = try store()
        _ = try await library.reconcile(language: "es-MX")
        // No image files exist. Search also succeeds with the manifest absent:
        // visible rows alone may request image decoding after the SQL query.
        try FileManager.default.removeItem(at: manifest)
        let cards = try await library.search("Apple", scope: child)
        XCTAssertEqual(cards.first?.image, "images/spanish.png")
        XCTAssertEqual(cards.first?.relativePath, "child")
        let boards = try await library.search("Child")
        XCTAssertEqual(boards.first?.image, "images/spanish-cover.png")
        try data.write(to: manifest)
        _ = try await library.reconcile(language: "en")
        let english = try await library.search("Apple", scope: child)
        XCTAssertEqual(english.first?.image, "images/0.png")
        try await library.move(child, parent: parent)
        let moved = try await library.search("Apple", scope: child)
        XCTAssertEqual(moved.first?.relativePath, "parent/children/" + child.uuidString)
        XCTAssertEqual(moved.first?.image, "images/0.png")
        try await library.delete(child)
        let deleted = try await library.search("Apple", scope: child)
        XCTAssertTrue(deleted.isEmpty)
    }
    func testMoveIdentityCycleAndDeleteSubtree() async throws {
        let parent = try board("parent"); let child = try board("parent/children/child")
        let library = try store(); _ = try await library.reconcile()
        do { try await library.move(parent,parent:child); XCTFail("Cycle accepted") } catch { }
        try await library.move(child,parent:nil)
        let snapshot = try await library.reconcile()
        XCTAssertEqual(snapshot.boards.first { $0.id == child }?.parentID,nil)
        try await library.move(child,parent:parent)
        try await library.delete(parent)
        let results = try await library.search("Apple"); XCTAssertTrue(results.isEmpty)
    }
    func testCopyRemapsSubtreeAndLeavesSourceUntouched() async throws {
        let parent = try board("parent"); let child = try board("parent/children/child")
        let before = try Data(contentsOf: base.appendingPathComponent("topics/parent/index.json"))
        let library = try store(); _ = try await library.reconcile(); let copied = try await library.copy(parent)
        let snapshot = try await library.reconcile()
        XCTAssertEqual(snapshot.boards.count,4); XCTAssertNotEqual(copied,parent)
        XCTAssertNotEqual(snapshot.boards.first { $0.parentID == copied }?.id,child)
        XCTAssertEqual(try Data(contentsOf: base.appendingPathComponent("topics/parent/index.json")),before)
    }
    func testExternalChangesAndStablePaging() async throws {
        try board("a",cards:83)
        let library = try store(); _ = try await library.reconcile()
        let page1 = try await library.search("Apple"), page2 = try await library.search("Apple",offset:40)
        XCTAssertEqual(page1.count,40); XCTAssertEqual(page2.count,40)
        XCTAssertTrue(Set(page1.map(\.id)).isDisjoint(with:Set(page2.map(\.id))))
        let unchanged = try await library.reconcile(); XCTAssertEqual(unchanged.indexedDocuments,0)
        let empty = try await library.search("  \" * : "); XCTAssertTrue(empty.isEmpty)
        let literal = try await library.search("Apple OR nope"); XCTAssertTrue(literal.isEmpty)
    }
    func testSymlinkEscapeAndUnknownVersion() async throws {
        try board("good")
        let bad = base.appendingPathComponent("topics/bad")
        try FileManager.default.createDirectory(at: bad, withIntermediateDirectories:true)
        try FileManager.default.createSymbolicLink(at:bad.appendingPathComponent("index.json"),withDestinationURL:base.appendingPathComponent("topics/good/index.json"))
        let library = try store(); let snapshot = try await library.reconcile()
        XCTAssertEqual(snapshot.boards.count,1); XCTAssertFalse(snapshot.diagnostics.isEmpty)
        XCTAssertThrowsError(try DocumentPaths.owned("../escape",by:bad))
    }
    func testMultilingualProjectionAndDeduplication() async throws {
        try board("a",cards:0)
        let file = base.appendingPathComponent("topics/a/index.json")
        var json = try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
        json["localization"] = ["title":["key":"title","sourceLanguage":"en","values":["en":"Apple","es":"Manzana"]],"languages":[],"preferredLanguage":"es"]
        try JSONSerialization.data(withJSONObject:json).write(to:file)
        let library = try store(); _ = try await library.reconcile()
        let hidden = try await library.search("Apple"); XCTAssertTrue(hidden.isEmpty)
        let visible = try await library.search("Manz"); XCTAssertEqual(visible.count,1)
        let all = try await library.search("Apple",allLanguages:true); XCTAssertEqual(all.count,1); XCTAssertEqual(all.first?.title,"Manzana")
    }
    func testEmptyTranslationStopsFallbackAndAccentsRemainDistinct() async throws {
        try board("a",cards:0)
        let file = base.appendingPathComponent("topics/a/index.json")
        var json = try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
        json["localization"] = ["title":["key":"title","sourceLanguage":"en","values":["en":"Niño café","es":""]],"languages":[],"preferredLanguage":"es-MX"]
        try JSONSerialization.data(withJSONObject:json).write(to:file)
        let library = try store(); _ = try await library.reconcile()
        let hidden = try await library.search("Niño"); XCTAssertTrue(hidden.isEmpty)
        let accented = try await library.search("NIÑO",allLanguages:true); XCTAssertEqual(accented.count,1)
        let distinct = try await library.search("nino",allLanguages:true); XCTAssertTrue(distinct.isEmpty)
    }
    func testDuplicateIdentityIsDiagnosed() async throws {
        let id = try board("one"); try board("two",id:id)
        let snapshot = try await store().reconcile()
        XCTAssertTrue(snapshot.diagnostics.contains { $0.contains("Duplicate identity") })
    }
    func testUnknownVersionDoesNotHideHealthySibling() async throws {
        try board("healthy"); try board("future")
        let file = base.appendingPathComponent("topics/future/index.json")
        var json = try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]; json["version"] = 999
        try JSONSerialization.data(withJSONObject:json).write(to:file)
        let snapshot = try await store().reconcile()
        XCTAssertEqual(snapshot.boards.count,1); XCTAssertEqual(snapshot.diagnostics.count,1)
    }
    func testMutableExternalStringTableReindexes() async throws {
        try board("a",cards:0)
        let directory = base.appendingPathComponent("topics/a")
        let file = directory.appendingPathComponent("index.json")
        var json = try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
        json["localization"] = ["title":["key":"title","sourceLanguage":"es"],"languages":["es"]]
        try JSONSerialization.data(withJSONObject:json).write(to:file)
        let locale = directory.appendingPathComponent("locales/es")
        try FileManager.default.createDirectory(at:locale,withIntermediateDirectories:true)
        let table = locale.appendingPathComponent("strings.json")
        try Data("{\"title\":\"Manzana\"}".utf8).write(to:table)
        let library = try store(); _ = try await library.reconcile()
        try Data("{\"title\":\"Naranja nueva\"}".utf8).write(to:table,options:.atomic)
        let snapshot = try await library.reconcile(); XCTAssertEqual(snapshot.indexedDocuments,1)
        let old = try await library.search("Manzana"); XCTAssertTrue(old.isEmpty)
        let new = try await library.search("Naranja"); XCTAssertEqual(new.count,1)
    }
    func testReplacedStringTableIsReadWhenPreviousResourceWasRemoved() async throws {
        let id = try board("a", cards: 0)
        let directory = base.appendingPathComponent("topics/a")
        let file = directory.appendingPathComponent("index.json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        json["localization"] = ["title": ["key": "title", "sourceLanguage": "es"], "languages": ["es"]]
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        let locale = directory.appendingPathComponent("locales/es")
        try FileManager.default.createDirectory(at: locale, withIntermediateDirectories: true)
        let oldTable = locale.appendingPathComponent("strings.json")
        try Data("{\"title\":\"Manzana\"}".utf8).write(to: oldTable)
        let library = try store()
        _ = try await library.reconcile()
        try Data("{\"title\":\"Naranja\"}".utf8).write(to: locale.appendingPathComponent("strings-new.json"))
        json["localization"] = ["title": ["key": "title", "sourceLanguage": "es"], "languages": ["es"], "tableFiles": ["es": "strings-new.json"]]
        try JSONSerialization.data(withJSONObject: json).write(to: file, options: .atomic)
        try FileManager.default.removeItem(at: oldTable)
        let snapshot = try await library.reconcile()
        XCTAssertEqual(snapshot.boards.map(\.id), [id])
        XCTAssertTrue(snapshot.diagnostics.isEmpty)
        XCTAssertEqual(snapshot.indexedDocuments, 1)
        let results = try await library.search("Naranja")
        XCTAssertEqual(results.count, 1)
    }
    func testKnownMissingDefaultTitleTableIsRestoredWithoutChangingManifest() async throws {
        try board("damaged")
        let directory = base.appendingPathComponent("topics/damaged")
        let manifest = directory.appendingPathComponent("index.json")
        let filename = "strings-b692830a747a74b24f30b9334740e12200231ae7ead7bc9ae3b1c6739db84c34.json"
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: manifest)) as! [String: Any]
        json["localization"] = ["title": ["key": "board.title", "sourceLanguage": "en"], "languages": ["en"], "tableFiles": ["en": filename]]
        let original = try JSONSerialization.data(withJSONObject: json)
        try original.write(to: manifest)
        let broken = try await store().reconcile()
        XCTAssertEqual(broken.boards.count, 0, "The damaged board is absent from the visible/deletable board list")
        XCTAssertFalse(broken.diagnostics.isEmpty)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let bytes = try encoder.encode(["board.title": "New Board"])
        let library = try BoardLibraryStore(root: base.appendingPathComponent("topics"), database: base.appendingPathComponent("cache/index.sqlite"), language: "es", recoveryTables: [bytes])
        let recovered = try await library.reconcile()
        XCTAssertTrue(recovered.isComplete)
        XCTAssertTrue(recovered.diagnostics.isEmpty)
        XCTAssertEqual(recovered.boards.first?.title, "New Board")
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("locales/en/" + filename)), bytes)
        XCTAssertEqual(try Data(contentsOf: manifest), original)
        let reopened = try await store().reconcile()
        XCTAssertTrue(reopened.diagnostics.isEmpty)
        XCTAssertEqual(reopened.boards.count, 1)
    }
    func testTableRecoveryNeverGuessesOrOverwritesExistingData() async throws {
        try board("damaged")
        let directory = base.appendingPathComponent("topics/damaged")
        let manifest = directory.appendingPathComponent("index.json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: manifest)) as! [String: Any]
        let unknown = "strings-" + String(repeating: "a", count: 64) + ".json"
        json["localization"] = ["title": ["key": "board.title", "sourceLanguage": "en"], "languages": ["en"], "tableFiles": ["en": unknown]]
        try JSONSerialization.data(withJSONObject: json).write(to: manifest)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let bytes = try encoder.encode(["board.title": "New Board"])
        let library = try BoardLibraryStore(root: base.appendingPathComponent("topics"), database: base.appendingPathComponent("cache/index.sqlite"), language: "en", recoveryTables: [bytes])
        let unknownResult = try await library.reconcile()
        XCTAssertFalse(unknownResult.isComplete)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("locales/en/" + unknown).path))
        let known = "strings-b692830a747a74b24f30b9334740e12200231ae7ead7bc9ae3b1c6739db84c34.json"
        json["localization"] = ["title": ["key": "board.title", "sourceLanguage": "en"], "languages": ["en"], "tableFiles": ["en": known]]
        try JSONSerialization.data(withJSONObject: json).write(to: manifest)
        let existing = directory.appendingPathComponent("locales/en/" + known)
        try FileManager.default.createDirectory(at: existing.deletingLastPathComponent(), withIntermediateDirectories: true)
        let original = Data("preserve existing bytes".utf8)
        try original.write(to: existing)
        let existingResult = try await library.reconcile()
        XCTAssertFalse(existingResult.isComplete)
        XCTAssertEqual(try Data(contentsOf: existing), original)
    }
    func testJournalRecoveryBeforeAndAfterRename() async throws {
        let id = try board("source")
        let operations = base.appendingPathComponent("topics/.operations")
        try FileManager.default.createDirectory(at:operations,withIntermediateDirectories:true)
        let journal: [String:Any] = ["source":"source","destination":"destination","id":id.uuidString]
        let file = operations.appendingPathComponent("move.json")
        try JSONSerialization.data(withJSONObject:journal).write(to:file)
        let library = try store(); let snapshot = try await library.reconcile()
        XCTAssertEqual(snapshot.boards.first?.relativePath,"destination")
        XCTAssertEqual(snapshot.boards.first?.id,id)
        try JSONSerialization.data(withJSONObject:journal).write(to:file)
        _ = try await library.reconcile()
        XCTAssertFalse(FileManager.default.fileExists(atPath:file.path))
    }
    func testPendingSaveMarkerSurvivesUntilIndexCommit() async throws {
        try board("a")
        let marker = base.appendingPathComponent("topics/a/.index-pending")
        try Data("pending".utf8).write(to:marker)
        _ = try await store().reconcile()
        XCTAssertFalse(FileManager.default.fileExists(atPath:marker.path))
    }
    func testMoveRecoveryPreservesUnexpectedDestinationAndRetriesAfterConflictRemoved() async throws {
        let id = try board("source")
        let conflictID = try board("destination")
        let operations = base.appendingPathComponent("topics/.operations")
        try FileManager.default.createDirectory(at: operations, withIntermediateDirectories: true)
        let file = operations.appendingPathComponent("move.json")
        try JSONSerialization.data(withJSONObject: ["source": "source", "destination": "destination", "id": id.uuidString]).write(to: file)
        let library = try store()
        let conflicted = try await library.reconcile()
        XCTAssertFalse(conflicted.isComplete)
        XCTAssertEqual(Set(conflicted.boards.map(\.id)), [id, conflictID])
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        try FileManager.default.moveItem(at: base.appendingPathComponent("topics/destination"), to: base.appendingPathComponent("preserved-conflict"))
        let recovered = try await library.reconcile()
        XCTAssertTrue(recovered.isComplete)
        XCTAssertEqual(recovered.boards.first?.id, id)
        XCTAssertEqual(recovered.boards.first?.relativePath, "destination")
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        let cards = try await library.search("Apple")
        XCTAssertEqual(cards.map(\.boardID), [id])
    }
    func testRebuildCorruptDatabase() async throws {
        try board("a")
        try FileManager.default.createDirectory(at:base.appendingPathComponent("cache"),withIntermediateDirectories:true)
        try Data("broken sqlite".utf8).write(to:base.appendingPathComponent("cache/index.sqlite"))
        let library = try store(); let snapshot = try await library.reconcile()
        XCTAssertEqual(snapshot.boards.count,1)
        XCTAssertTrue(snapshot.isComplete)
        XCTAssertEqual(try Data(contentsOf: base.appendingPathComponent("cache/index.sqlite")), Data("broken sqlite".utf8))
        XCTAssertTrue(FileManager.default.fileExists(atPath: base.appendingPathComponent("cache/index.sqlite.active").path))
    }
    func testPartialGenerationResumesAndPromotesOnlyAfterCompleteReconciliation() async throws {
        try board("good")
        try board("bad")
        let manifest = base.appendingPathComponent("topics/bad/index.json")
        let original = try Data(contentsOf: manifest)
        try Data("unavailable".utf8).write(to: manifest)
        let active = base.appendingPathComponent("cache/index.sqlite.active")
        let pending = base.appendingPathComponent("cache/index.sqlite.pending")
        let first = try store()
        let partial = try await first.reconcile()
        XCTAssertFalse(partial.isComplete)
        XCTAssertEqual(partial.boards.count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: active.path))
        let generation = try Data(contentsOf: pending)
        let second = try store()
        XCTAssertEqual(try Data(contentsOf: pending), generation)
        try original.write(to: manifest)
        let completed = try await second.reconcile()
        XCTAssertTrue(completed.isComplete)
        XCTAssertEqual(completed.indexedDocuments, 1, "Committed batches must survive a relaunch")
        XCTAssertEqual(completed.boards.count, 2)
        XCTAssertEqual(try Data(contentsOf: active), generation)
        XCTAssertFalse(FileManager.default.fileExists(atPath: pending.path))
        let relaunched = try store()
        let unchanged = try await relaunched.reconcile()
        XCTAssertEqual(unchanged.indexedDocuments, 0)
        XCTAssertTrue(unchanged.isComplete)
    }
    func testGenerationPointersRejectEscapingPaths() async throws {
        try board("good")
        let cache = base.appendingPathComponent("cache")
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        let pointer = cache.appendingPathComponent("index.sqlite.pending")
        try JSONEncoder().encode("../outside.sqlite").write(to: pointer)
        let library = try store()
        let snapshot = try await library.reconcile()
        XCTAssertTrue(snapshot.isComplete)
        let name = try JSONDecoder().decode(String.self, from: Data(contentsOf: cache.appendingPathComponent("index.sqlite.active")))
        XCTAssertTrue(name.hasPrefix("index.sqlite.generation-"))
        XCTAssertFalse(name.contains("/"))
    }
    func testSchemaReplacementRetainsPreviousGenerationUntilPromotion() async throws {
        try board("good")
        let cache = base.appendingPathComponent("cache")
        let old = cache.appendingPathComponent("index.sqlite.generation-" + UUID().uuidString)
        do {
            let catalog = try BoardCatalog(url: old)
            let document = try BoardDocumentReader.read(base.appendingPathComponent("topics/good"), relativePath: "good")
            try catalog.replace(document, path: "good", parent: nil, language: "en")
            try catalog.execute("PRAGMA user_version=1")
        }
        let active = cache.appendingPathComponent("index.sqlite.active")
        let oldPointer = try JSONEncoder().encode(old.lastPathComponent)
        try oldPointer.write(to: active)
        let library = try store()
        XCTAssertEqual(try Data(contentsOf: active), oldPointer)
        let snapshot = try await library.reconcile()
        XCTAssertTrue(snapshot.isComplete)
        XCTAssertNotEqual(try Data(contentsOf: active), oldPointer)
        XCTAssertTrue(FileManager.default.fileExists(atPath: old.path))
        XCTAssertFalse(BoardCatalog.isCurrent(at: old), "Opening a replacement must not migrate the old database in place")
        let cards = try await library.search("Apple")
        XCTAssertEqual(cards.count, 1)
    }
    func testFailedPromotionRetainsCommittedGenerationForRetry() async throws {
        try board("good")
        let library = try store()
        let active = base.appendingPathComponent("cache/index.sqlite.active")
        try FileManager.default.createDirectory(at: active, withIntermediateDirectories: true)
        do { _ = try await library.reconcile(); XCTFail("Promotion unexpectedly replaced a directory") } catch { }
        XCTAssertTrue(FileManager.default.fileExists(atPath: base.appendingPathComponent("cache/index.sqlite.pending").path))
        try FileManager.default.removeItem(at: active)
        let retry = try await library.reconcile()
        XCTAssertTrue(retry.isComplete)
        XCTAssertEqual(retry.indexedDocuments, 0)
        let cards = try await library.search("Apple")
        XCTAssertEqual(cards.count, 1)
    }
    func testProvisionalIdentityPersistsAcrossMoveAndRebuild() async throws {
        try board("legacy")
        let file = base.appendingPathComponent("topics/legacy/index.json")
        var json = try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]; json.removeValue(forKey:"id")
        try JSONSerialization.data(withJSONObject:json).write(to:file)
        let library = try store(); let first = try await library.reconcile(); let id = try XCTUnwrap(first.boards.first?.id)
        try await library.move(id,parent:nil)
        let second = try await library.reconcile(); XCTAssertEqual(second.boards.first?.id,id)
        let document = try BoardDocumentReader.read(await library.location(id),relativePath:"changed")
        XCTAssertEqual(document.id,id); XCTAssertEqual(document.version,3)
    }

    func testLanguageSwitchProjectsWithoutDocumentReplacement() async throws {
        try board("a",cards:0)
        let file = base.appendingPathComponent("topics/a/index.json")
        var json = try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
        json["localization"] = ["title":["key":"title","sourceLanguage":"en","values":["en":"Apple","es":"Manzana"]],"languages":[]]
        try JSONSerialization.data(withJSONObject:json).write(to:file)
        let library = try store(); _ = try await library.reconcile()
        let switched = try await library.reconcile(language:"es-MX")
        XCTAssertEqual(switched.indexedDocuments,0)
        let hidden = try await library.search("Apple"); XCTAssertTrue(hidden.isEmpty)
        let visible = try await library.search("Manz"); XCTAssertEqual(visible.count,1)
    }
    func testSingleSaveUpdateAndReplacedIdentityDoNotLeaveSearchOrphans() async throws {
        try board("a",title:"Old")
        let library = try store(); _ = try await library.reconcile()
        let file = base.appendingPathComponent("topics/a/index.json")
        var json = try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
        json["topic"] = ["topicName":"Changed","imageFileName":"cover.png"]
        try JSONSerialization.data(withJSONObject:json).write(to:file)
        let update = try await library.updateBoard(at:file.deletingLastPathComponent())
        XCTAssertEqual(update.indexedDocuments,1)
        let changed = try await library.search("Changed"); XCTAssertEqual(changed.count,1)
        json["id"] = UUID().uuidString
        try JSONSerialization.data(withJSONObject:json).write(to:file)
        _ = try await library.reconcile()
        let cards = try await library.search("Apple"); XCTAssertEqual(cards.count,1)
    }
    func testExportAndImportPreserveAllTablesAndCopyIdentity() async throws {
        let id = try board("a"); try board("a/children/b")
        let directory = base.appendingPathComponent("topics/a/children/b")
        let file = directory.appendingPathComponent("index.json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        json["localization"] = ["title": ["key": "title", "sourceLanguage": "en"], "languages": ["en", "es"]]
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        for (language, title) in [("en", "Original child"), ("es", "Niño del árbol")] {
            let locale = directory.appendingPathComponent("locales/" + language)
            try FileManager.default.createDirectory(at: locale, withIntermediateDirectories: true)
            try JSONEncoder().encode(["title": title]).write(to: locale.appendingPathComponent("strings.json"))
        }
        let library = try store(); _ = try await library.reconcile()
        let destination = base.appendingPathComponent("export")
        try await library.export(id,to:destination)
        let copied = try await library.importSubtree(from:destination)
        XCTAssertNotEqual(copied,id)
        let snapshot = try await library.reconcile(); XCTAssertEqual(snapshot.boards.count,4)
        let importedChild = try XCTUnwrap(snapshot.boards.first { $0.parentID == copied })
        let importedDirectory = try await library.location(importedChild.id)
        for language in ["en", "es"] {
            let path = "locales/" + language + "/strings.json"
            XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent(path)), try Data(contentsOf: importedDirectory.appendingPathComponent(path)))
        }
        let translated = try await library.search("Niño", scope: copied, allLanguages: true)
        XCTAssertEqual(translated.count, 1)
        XCTAssertEqual(translated.first?.boardID, importedChild.id)
    }

    func testLanguageSwitchKeepsExactDisplayedMatchFirst() async throws {
        let exact = try board("exact", cards: 0)
        try board("prefix", title: "Apple aardvark", cards: 0)
        let file = base.appendingPathComponent("topics/exact/index.json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        json["localization"] = ["title": ["key": "title", "sourceLanguage": "en", "values": ["en": "Apple zebra", "es": "Apple"]], "languages": []]
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        let library = try store()
        _ = try await library.reconcile()
        _ = try await library.reconcile(language: "es")
        let result = try await library.search("Apple", allLanguages: true)
        XCTAssertEqual(result.first?.boardID, exact)
        XCTAssertEqual(result.first?.matchedText, "Apple")
        XCTAssertEqual(result.first?.language, "es")
    }

    func testCollidingAncestorsIsolateTheirDescendantsUntilResolved() async throws {
        let id = try board("a")
        try board("a/children/child", title: "Isolated")
        try board("b", id: id)
        let library = try store()
        let collision = try await library.reconcile()
        XCTAssertTrue(collision.boards.isEmpty)
        let hidden = try await library.search("Isolated")
        XCTAssertTrue(hidden.isEmpty)
        do { _ = try await library.location(id); XCTFail("Unavailable identity resolved") } catch { }
        try FileManager.default.removeItem(at: base.appendingPathComponent("topics/b"))
        let recovered = try await library.reconcile()
        XCTAssertEqual(recovered.boards.count, 2)
        let visible = try await library.search("Isolated")
        XCTAssertEqual(visible.count, 1)
    }

    func testCancelledIndexResumesWithoutChangingDocuments() async throws {
        for index in 0..<40 { try board("b-\(index)") }
        let library = try store()
        let task = Task { try Task.checkCancellation(); return try await library.reconcile() }
        task.cancel()
        do { _ = try await task.value; XCTFail("Cancelled indexing completed") } catch is CancellationError { }
        let resumed = try await library.reconcile()
        XCTAssertEqual(resumed.boards.count, 40)
        XCTAssertTrue(resumed.diagnostics.isEmpty)
        let result = try await library.search("Apple")
        XCTAssertEqual(result.count, 40)
    }

    func testMoveDoesNotFollowSymbolicChildIntoAnotherLibrary() async throws {
        let parent = try board("a")
        let outside = base.appendingPathComponent("outside")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        let original = try Data(contentsOf: base.appendingPathComponent("topics/a/index.json"))
        try original.write(to: outside.appendingPathComponent("index.json"))
        let children = base.appendingPathComponent("topics/a/children")
        try FileManager.default.createDirectory(at: children, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: children.appendingPathComponent("link"), withDestinationURL: outside)
        let library = try store(); _ = try await library.reconcile()
        do { try await library.move(parent, parent: nil); XCTFail("Unsafe child accepted") } catch { }
        XCTAssertEqual(try Data(contentsOf: outside.appendingPathComponent("index.json")), original)
    }

    func testSpanishCaseFoldingRanksExactDisplayedLabelFirst() async throws {
        let exact = try board("exact", title: "niño", cards: 0)
        try board("prefix", title: "NIÑO extra", cards: 0)
        let library = try store(); _ = try await library.reconcile()
        let results = try await library.search("NIÑO")
        XCTAssertEqual(results.first?.boardID, exact)
    }

    func testSearchReadsCommittedBatchWhileIndexingIsPaused() async throws {
        for index in 0..<40 { try board("board-\(index)") }
        let library = try store()
        let paused = expectation(description: "First batch committed")
        let resume = DispatchSemaphore(value: 0)
        let indexing = Task {
            try await library.reconcile { snapshot in
                if snapshot.boards.count == 25 {
                    paused.fulfill()
                    _ = resume.wait(timeout: .now() + 5)
                }
            }
        }
        await fulfillment(of: [paused], timeout: 5)
        let partial = try await library.search("Apple")
        resume.signal()
        XCTAssertEqual(partial.count, 25, "Search must not wait for the writer to finish all 40 boards")
        let complete = try await indexing.value
        XCTAssertEqual(complete.boards.count, 40)
    }

    func testRelaunchProjectsChangedAppLanguageWithoutReindexing() async throws {
        try board("a", cards: 0)
        let file = base.appendingPathComponent("topics/a/index.json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        json["localization"] = ["title": ["key": "title", "sourceLanguage": "en", "values": ["en": "Apple", "es": "Manzana"]], "languages": []]
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        let first = try store(); _ = try await first.reconcile()
        let relaunched = try BoardLibraryStore(root: base.appendingPathComponent("topics"), database: base.appendingPathComponent("cache/index.sqlite"), language: "es")
        let snapshot = try await relaunched.reconcile()
        XCTAssertEqual(snapshot.indexedDocuments, 0)
        let hidden = try await relaunched.search("Apple")
        let visible = try await relaunched.search("Manzana")
        XCTAssertTrue(hidden.isEmpty); XCTAssertEqual(visible.count, 1)
    }

}
