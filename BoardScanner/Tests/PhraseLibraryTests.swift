import XCTest
@testable import BoardScanner

@MainActor
final class PhraseLibraryTests: XCTestCase {
    func testSaveEditOrderAndDeletionSurviveRelaunch() throws {
        let suite = "PhraseTests-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let library = PhraseLibrary(defaults: defaults)
        let initial = library.phrases.count
        var phrase = SavedPhrase(title: "Lunch", text: "Please bring lunch.")
        XCTAssertNil(library.save(phrase))
        phrase.text = "Please bring my lunch."
        XCTAssertNil(library.save(phrase))
        XCTAssertEqual(library.phrases.count, initial + 1)
        XCTAssertNil(library.move(from: IndexSet(integer: initial), to: 0))
        let reopened = PhraseLibrary(defaults: defaults)
        XCTAssertEqual(reopened.phrases.first, phrase)
        XCTAssertNil(reopened.delete(phrase))
        XCTAssertFalse(PhraseLibrary(defaults: defaults).phrases.contains { $0.id == phrase.id })
        XCTAssertNil(reopened.restoreDeleted())
        XCTAssertTrue(PhraseLibrary(defaults: defaults).phrases.contains(phrase))
    }

    func testEmptyLibraryStaysEmptyAndDefaultsAreSeededOnlyOnce() throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let library = PhraseLibrary(defaults: defaults)
        for phrase in library.phrases { XCTAssertNil(library.delete(phrase)) }
        XCTAssertTrue(PhraseLibrary(defaults: defaults).phrases.isEmpty)
    }

    func testInvalidEditLeavesOriginalStoredCollectionIntact() throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let library = PhraseLibrary(defaults: defaults)
        let original = library.phrases
        var invalid = try XCTUnwrap(original.first)
        invalid.text = " \n "
        XCTAssertNotNil(library.save(invalid))
        invalid.text = String(repeating: "x", count: 10_001)
        XCTAssertNotNil(library.save(invalid))
        XCTAssertEqual(library.phrases, original)
        XCTAssertEqual(PhraseLibrary(defaults: defaults).phrases, original)
        XCTAssertNil(library.save(SavedPhrase(title: "", text: "  Please wait.  ")))
        XCTAssertEqual(library.phrases.last?.title, "Please wait.")
        XCTAssertEqual(library.phrases.last?.text, "Please wait.")
    }

    func testCorruptCollectionIsPreservedUntilExplicitRecovery() throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let damaged = Data("not valid JSON".utf8)
        defaults.set(damaged, forKey: "communication.phrases.v1")
        let library = PhraseLibrary(defaults: defaults)
        XCTAssertNotNil(library.loadError)
        XCTAssertNotNil(library.save(SavedPhrase(title: "Test", text: "Words")))
        XCTAssertEqual(defaults.data(forKey: "communication.phrases.v1"), damaged)
        library.resetUnreadableData()
        XCTAssertEqual(defaults.data(forKey: "communication.phrases.v1.recovery"), damaged)
        XCTAssertNil(library.loadError)
        XCTAssertFalse(PhraseLibrary(defaults: defaults).phrases.isEmpty)
    }
}
