import XCTest
#if canImport(FoundationModels)
import FoundationModels
#endif
@testable import ARASAACSymbols

/// Opt-in integration coverage: requires a ready Apple model and ARASAAC network access.
/// Run with TEST_RUNNER_ARASAAC_LIVE_MODEL_TESTS=1 and -only-testing:ARASAACSymbolsTests/ARASAACLiveSuggestionTests.
final class ARASAACLiveSuggestionTests: XCTestCase {
    @MainActor
    func testContextualSuggestionsInEnglishAndSpanish() async throws {
        guard ProcessInfo.processInfo.environment["ARASAAC_LIVE_MODEL_TESTS"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_ARASAAC_LIVE_MODEL_TESTS=1 to exercise the real on-device model and ARASAAC.")
        }
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { throw XCTSkip("Requires iOS 26") }
        guard case .available = SystemLanguageModel.default.availability else {
            throw XCTSkip("Apple Intelligence model is unavailable")
        }
        for (language, name, labels) in [
            ("en", "Trip to the swimming pool", ["swimsuit", "towel", "goggles"]),
            ("es", "Desayuno", ["leche", "pan", "cereales"]),
            ("en", "Places to Go", []),
            ("en", "Places to Go", ["park", "school", "shop"]),
            ("es", "Lugares para ir", ["parque", "escuela", "tienda"]),
            ("en", "Feelings", ["happy", "sad", "angry"])
        ] {
            let context = ARASAACSuggestionContext(boardName: name, cardLabels: labels)
            let terms = await ARASAACSuggestionService.shared.suggestions(context: context, language: language, client: ARASAACClient())
            print("Live suggestions (\(language), \(name), existing \(labels)): \(terms)")
            XCTAssertFalse(terms.isEmpty, "Expected model suggestions with real ARASAAC matches for \(language)")
            XCTAssertLessThanOrEqual(terms.count, 6)
            XCTAssertEqual(context.candidates(from: terms), terms)
            if language == "es" {
                let englishLeakage: Set<String> = ["jam", "fruit", "door", "book", "beach", "restaurant", "library"]
                XCTAssertTrue(Set(terms.map(ARASAACSuggestionContext.normalized)).isDisjoint(with: englishLeakage))
            }
            if name == "Places to Go" || name == "Lugares para ir" {
                // Regression examples: an object associated with a destination is not a destination.
                let unrelatedObjects: Set<String> = ["door", "book", "puerta", "libro", "lugar publico", "public place"]
                XCTAssertTrue(Set(terms.map(ARASAACSuggestionContext.normalized)).isDisjoint(with: unrelatedObjects))
            }
        }
        #else
        throw XCTSkip("Foundation Models SDK unavailable")
        #endif
    }
}
