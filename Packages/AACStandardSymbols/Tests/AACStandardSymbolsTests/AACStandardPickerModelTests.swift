import XCTest
@testable import AACStandardSymbols

@MainActor
final class AACStandardPickerModelTests: XCTestCase {
    func testSelectionOrderLimitsAndDeselecting() {
        let model = makeModel(limit: 2)
        model.toggle(symbol(2))
        model.toggle(symbol(1))
        model.toggle(symbol(3))
        XCTAssertEqual(model.selections.map(\.id), [2, 1])
        model.toggle(symbol(2))
        model.toggle(symbol(3))
        XCTAssertEqual(model.selections.map(\.id), [1, 3])
        model.clearSelection()
        XCTAssertTrue(model.selections.isEmpty)
    }

    func testSingleSelectionReplacesAndZeroLimitSelectsNothing() {
        let model = makeModel(limit: 1)
        model.toggle(symbol(1))
        model.toggle(symbol(2))
        XCTAssertEqual(model.selections.map(\.id), [2])
        let disabled = makeModel(limit: 0)
        disabled.toggle(symbol(1))
        XCTAssertTrue(disabled.selections.isEmpty)
    }

    func testSearchKeepsSelectionsAndDeduplicatesResults() async {
        let service = ImmediateService(page: .init(symbols: [symbol(1), symbol(1), symbol(2)], nextOffset: nil))
        let model = makeModel(service: service)
        model.toggle(symbol(3))
        await model.search(.init(term: "cat"))
        XCTAssertEqual(model.results.map(\.id), [1, 2])
        XCTAssertEqual(model.selections.map(\.id), [3])
        await model.search(.init(term: ""))
        XCTAssertTrue(model.results.isEmpty)
        XCTAssertFalse(model.isSearching)
        XCTAssertEqual(model.selections.map(\.id), [3])
    }

    func testOldSearchSuccessCannotReplaceNewSearch() async {
        let service = ControlledService()
        let model = makeModel(service: service)
        let old = Task { await model.search(.init(term: "old")) }
        await service.waitForRequest("old", offset: 0)
        let new = Task { await model.search(.init(term: "new")) }
        await service.waitForRequest("new", offset: 0)
        await service.finish("new", offset: 0, result: .success(.init(symbols: [symbol(2)], nextOffset: nil)))
        await new.value
        await service.finish("old", offset: 0, result: .success(.init(symbols: [symbol(1)], nextOffset: 50)))
        await old.value
        XCTAssertEqual(model.results.map(\.id), [2])
        XCTAssertNil(model.nextOffset)
        XCTAssertNil(model.searchError)
    }

    func testOldFailureCannotReplaceNewSearch() async {
        let service = ControlledService()
        let model = makeModel(service: service)
        let old = Task { await model.search(.init(term: "old")) }
        await service.waitForRequest("old", offset: 0)
        await model.search(.init(term: ""))
        await service.finish("old", offset: 0, result: .failure(URLError(.notConnectedToInternet)))
        await old.value
        XCTAssertNil(model.searchError)
        XCTAssertFalse(model.isSearching)
    }

    func testCancelledNetworkRequestDoesNotDisplayError() async {
        let service = ControlledService()
        let model = makeModel(service: service)
        let task = Task { await model.search(.init(term: "cat")) }
        await service.waitForRequest("cat", offset: 0)
        task.cancel()
        await service.finish("cat", offset: 0, result: .failure(URLError(.cancelled)))
        await task.value
        XCTAssertNil(model.searchError)
        XCTAssertFalse(model.isSearching)
    }

    func testPaginationDeduplicatesAndRetainsOffsetOnFailureForRetry() async {
        let service = ControlledService()
        let model = makeModel(service: service)
        let first = Task { await model.search(.init(term: "cat")) }
        await service.waitForRequest("cat", offset: 0)
        await service.finish("cat", offset: 0, result: .success(.init(symbols: [symbol(1)], nextOffset: 1)))
        await first.value
        let failed = Task { await model.loadMore() }
        await service.waitForRequest("cat", offset: 1)
        await service.finish("cat", offset: 1, result: .failure(AACStandardError.httpStatus(503)))
        await failed.value
        XCTAssertEqual(model.results.map(\.id), [1])
        XCTAssertEqual(model.nextOffset, 1)
        XCTAssertNotNil(model.searchError)
        let retry = Task { await model.loadMore() }
        await service.waitForRequest("cat", offset: 1)
        await service.finish("cat", offset: 1, result: .success(.init(symbols: [symbol(1), symbol(2)], nextOffset: nil)))
        await retry.value
        XCTAssertEqual(model.results.map(\.id), [1, 2])
        XCTAssertNil(model.searchError)
        XCTAssertNil(model.nextOffset)
    }

    func testOldPageCannotAppendToNewSearch() async {
        let service = ControlledService()
        let model = makeModel(service: service)
        let first = Task { await model.search(.init(term: "cat")) }
        await service.waitForRequest("cat", offset: 0)
        await service.finish("cat", offset: 0, result: .success(.init(symbols: [symbol(1)], nextOffset: 1)))
        await first.value
        let page = Task { await model.loadMore() }
        await service.waitForRequest("cat", offset: 1)
        await model.search(.init(term: ""))
        await service.finish("cat", offset: 1, result: .success(.init(symbols: [symbol(2)], nextOffset: nil)))
        await page.value
        XCTAssertTrue(model.results.isEmpty)
        XCTAssertFalse(model.isLoadingMore)
        XCTAssertNil(model.nextOffset)
    }

    func testDownloadFailureKeepsSelectionForRetry() async {
        let service = ImmediateService(downloadError: .httpStatus(503))
        let model = makeModel(service: service)
        model.toggle(symbol(2))
        let result = await model.downloadSelection()
        XCTAssertNil(result)
        XCTAssertNotNil(model.downloadError)
        XCTAssertEqual(model.selections.map(\.id), [2])
    }

    private func makeModel(service: any AACStandardServing = ImmediateService(), limit: Int? = nil) -> AACStandardPickerModel {
        AACStandardPickerModel(service: service, maxSelections: limit, debounceNanoseconds: 0)
    }
}

private struct ImmediateService: AACStandardServing {
    var page = AACStandardSearchPage(symbols: [], nextOffset: nil)
    var downloadError: AACStandardError?
    func search(_ request: AACStandardSearchRequest) async throws -> AACStandardSearchPage { page }
    func download(_ symbols: [AACStandardSymbol]) async throws -> [AACStandardSelection] {
        if let downloadError { throw downloadError }
        return symbols.map { AACStandardSelection(symbol: $0, imageData: Data()) }
    }
}

/// Explicit continuations make out-of-order response tests deterministic without sleeps.
private actor ControlledService: AACStandardServing {
    private var pending: [String: CheckedContinuation<AACStandardSearchPage, Error>] = [:]
    private var waiters: [String: CheckedContinuation<Void, Never>] = [:]

    func search(_ request: AACStandardSearchRequest) async throws -> AACStandardSearchPage {
        let key = "\(request.term)|\(request.offset)"
        return try await withCheckedThrowingContinuation { continuation in
            pending[key] = continuation
            waiters.removeValue(forKey: key)?.resume()
        }
    }

    func waitForRequest(_ term: String, offset: Int) async {
        let key = "\(term)|\(offset)"
        if pending[key] != nil { return }
        await withCheckedContinuation { waiters[key] = $0 }
    }

    func finish(_ term: String, offset: Int, result: Result<AACStandardSearchPage, Error>) {
        pending.removeValue(forKey: "\(term)|\(offset)")?.resume(with: result)
    }

    func download(_ symbols: [AACStandardSymbol]) async throws -> [AACStandardSelection] { [] }
}
