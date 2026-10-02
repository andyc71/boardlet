import XCTest
@testable import ARASAACSymbols

final class ARASAACSelectionStateTests: XCTestCase {
    func testMultipleSelectionPreservesTapOrderAcrossSearches() throws {
        let cat = try symbol(id: 1, title: "cat")
        let dog = try symbol(id: 2, title: "dog")
        var state = ARASAACSelectionState()

        state.toggle(dog, maxSelections: nil)
        state.toggle(cat, maxSelections: nil)

        XCTAssertEqual(state.ids, [2, 1])
        XCTAssertEqual(state.symbols.map(\.title), ["dog", "cat"])
        XCTAssertTrue(state.contains(1))
    }

    func testTappingSelectedSymbolDeselectsIt() throws {
        let cat = try symbol(id: 1, title: "cat")
        var state = ARASAACSelectionState()
        state.toggle(cat, maxSelections: nil)
        state.toggle(cat, maxSelections: nil)

        XCTAssertTrue(state.isEmpty)
        XCTAssertFalse(state.contains(1))
        XCTAssertTrue(state.symbols.isEmpty)
    }

    func testSingleSelectionReplacesPriorSymbol() throws {
        let cat = try symbol(id: 1, title: "cat")
        let dog = try symbol(id: 2, title: "dog")
        var state = ARASAACSelectionState()
        state.toggle(cat, maxSelections: 1)
        state.toggle(dog, maxSelections: 1)

        XCTAssertEqual(state.ids, [2])
        XCTAssertFalse(state.contains(1))
        XCTAssertEqual(state.symbols.map(\.title), ["dog"])
    }

    func testSelectionLimitKeepsEarlierSelections() throws {
        let symbols = try (1...3).map { try symbol(id: $0, title: "symbol \($0)") }
        var state = ARASAACSelectionState()
        symbols.forEach { state.toggle($0, maxSelections: 2) }

        XCTAssertEqual(state.ids, [1, 2])
        XCTAssertFalse(state.contains(3))
    }

    func testDeselectingFreesASelectionSlot() throws {
        let symbols = try (1...3).map { try symbol(id: $0, title: "symbol \($0)") }
        var state = ARASAACSelectionState()
        state.toggle(symbols[0], maxSelections: 2)
        state.toggle(symbols[1], maxSelections: 2)
        state.toggle(symbols[0], maxSelections: 2)
        state.toggle(symbols[2], maxSelections: 2)

        XCTAssertEqual(state.ids, [2, 3])
    }

    func testSymbolWithoutKeywordsUsesIDAsTitle() throws {
        let untitled = try JSONDecoder().decode(ARASAACSymbol.self, from: Data("{\"_id\":42,\"keywords\":[]}".utf8))
        XCTAssertEqual(untitled.title, "42")
        XCTAssertEqual(untitled.imageURL.absoluteString, "https://static.arasaac.org/pictograms/42/42_500.png")
    }

    private func symbol(id: Int, title: String) throws -> ARASAACSymbol {
        let data = Data("{\"_id\":\(id),\"keywords\":[{\"keyword\":\"\(title)\"}]}".utf8)
        return try JSONDecoder().decode(ARASAACSymbol.self, from: data)
    }
}
