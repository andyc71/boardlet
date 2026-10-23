import XCTest
@testable import ARASAACSymbols

final class ARASAACBoardSuggestionsTests: XCTestCase {
    @MainActor
    func testTextIsPublishedBeforeAnySymbolSearchAndSelectionCanStartImmediately() async throws {
        let model = ARASAACBoardSuggestionsModel()
        let symbol = try JSONDecoder().decode(ARASAACSymbol.self,
            from: Data(#"{"_id":1,"keywords":[{"keyword":"apple"}]}"#.utf8))
        await model.load(terms: { ["apple", "pear"] }) { term in
            await MainActor.run {
                XCTAssertEqual(model.items.map(\.term), ["apple", "pear"])
                XCTAssertFalse(model.isGenerating)
                model.selectedTerms.insert(term)
            }
            return ARASAACSelection(symbol: symbol, imageData: Data())
        }
        XCTAssertTrue(model.canAdd)
        XCTAssertEqual(model.selections.count, 1, "The same symbol must not be added twice")
    }

    @MainActor
    func testMissingAndFailedSymbolsDoNotDiscardSuccessfulRows() async throws {
        let model = ARASAACBoardSuggestionsModel()
        let symbol = try JSONDecoder().decode(ARASAACSymbol.self,
            from: Data(#"{"_id":2,"keywords":[{"keyword":"pear"}]}"#.utf8))
        await model.load(terms: { ["missing", "offline", "pear"] }) { term in
            await MainActor.run { model.selectedTerms.insert(term) }
            switch term {
            case "missing": return nil
            case "offline": throw URLError(.notConnectedToInternet)
            default: return ARASAACSelection(symbol: symbol, imageData: Data())
            }
        }
        XCTAssertEqual(model.items.map(\.term), ["missing", "offline", "pear"])
        guard case .unavailable = model.items[0].status,
              case .failed = model.items[1].status,
              case .ready = model.items[2].status else { return XCTFail("Incorrect row states") }
        XCTAssertEqual(model.selectedTerms, ["pear"])
        XCTAssertTrue(model.canAdd)
        XCTAssertEqual(model.selections.map(\.symbol.id), [2])
    }

    @MainActor
    func testCancellationBeforeGenerationFinishesStartsNoSearches() async {
        let model = ARASAACBoardSuggestionsModel()
        let task = Task {
            await model.load(terms: {
                withUnsafeCurrentTask { $0?.cancel() }
                return ["apple"]
            }) { _ in
                XCTFail("A dismissed suggestion list must not start searches")
                return nil
            }
        }
        await task.value
        XCTAssertTrue(model.items.isEmpty)
        XCTAssertFalse(model.canAdd)
    }

    @MainActor
    func testPendingSelectedRowCannotBeAddedBeforeItsSymbolArrives() async {
        let model = ARASAACBoardSuggestionsModel()
        await model.load(terms: { ["apple"] }) { term in
            await MainActor.run {
                model.selectedTerms.insert(term)
                XCTAssertFalse(model.canAdd)
                XCTAssertTrue(model.selections.isEmpty)
            }
            return nil
        }
        XCTAssertFalse(model.canAdd)
    }
}
