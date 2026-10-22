import XCTest
#if canImport(FoundationModels)
import FoundationModels
#endif
@testable import ARASAACSymbols

final class ARASAACSuggestionTests: XCTestCase {
    func testContextIsStableAcrossCardOrderAndBlankCards() {
        let first = ARASAACSuggestionContext(boardName: " Breakfast ", cardLabels: ["toast", "", " milk ", "toast"])
        let second = ARASAACSuggestionContext(boardName: "Breakfast", cardLabels: ["milk", "toast"])
        XCTAssertEqual(first, second)
        XCTAssertFalse(ARASAACSuggestionContext(boardName: " ", cardLabels: [" "]).hasContent)
    }

    func testCandidatesExcludeExistingLabelsDuplicatesAndLongOutput() {
        let context = ARASAACSuggestionContext(boardName: "Breakfast", cardLabels: ["Milk", "café"])
        let candidates = context.candidates(from: ["milk", " CAFE ", "spoon", "Spoon", "", "help\nplease", "a very long sentence with instructions", "finished"])
        XCTAssertEqual(candidates, ["spoon", "finished"])
    }

    func testPromptBoundsBoardDataAndPreservesJSONEscaping() throws {
        let context = ARASAACSuggestionContext(boardName: String(repeating: "x", count: 500),
                                             cardLabels: (0..<100).map { "\($0)\"" + String(repeating: "a", count: 100) })
        let json = try JSONDecoder().decode([String: String].self, from: Data(context.promptData.utf8))
        XCTAssertEqual(json["board"]?.count, 160)
        XCTAssertLessThan(context.promptData.count, 3500)
    }

    func testValidatorOmitsEmptySearchesAndLimitsToSix() async throws {
        var requests: [String] = []
        let result = try await ARASAACSuggestionValidator.validate(["missing", "1", "2", "3", "4", "5", "6", "7"]) { term in
            requests.append(term)
            return term != "missing"
        }
        XCTAssertEqual(result, ["1", "2", "3", "4", "5", "6"])
        XCTAssertEqual(requests.count, 7)
    }

    func testValidationDoesNotSwallowNetworkFailure() async {
        do {
            _ = try await ARASAACSuggestionValidator.validate(["help"]) { _ in
                throw URLError(.notConnectedToInternet)
            }
            XCTFail("Expected network failure")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    func testCancellationStopsFurtherValidation() async {
        let task = Task {
            try await ARASAACSuggestionValidator.validate(["help", "finished"]) { _ in
                withUnsafeCurrentTask { $0?.cancel() }
                return true
            }
        }
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    @MainActor
    func testUnavailableModelReturnsNoSuggestions() async throws {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard case .unavailable = SystemLanguageModel.default.availability else {
                throw XCTSkip("This device has an available model; fallback test requires an unavailable model.")
            }
        }
        #endif
        let terms = await ARASAACSuggestionService.shared.suggestions(
            context: .init(boardName: "Breakfast", cardLabels: ["toast"]), language: "en", client: ARASAACClient())
        XCTAssertTrue(terms.isEmpty)
    }

    @MainActor
    func testEmptyContextNeedsNoModelOrNetwork() async {
        let terms = await ARASAACSuggestionService.shared.suggestions(
            context: .init(boardName: "", cardLabels: []), language: "en", client: ARASAACClient())
        XCTAssertTrue(terms.isEmpty)
    }
}
