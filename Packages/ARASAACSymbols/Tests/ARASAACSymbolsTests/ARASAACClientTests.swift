import XCTest
@testable import ARASAACSymbols

final class ARASAACClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testSearchEncodesQueryAndDecodesPictograms() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.host, "api.arasaac.org")
            XCTAssertEqual(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.percentEncodedPath, "/v1/pictograms/es/search/gato%20%2F%20perro")
            let data = Data("[{\"_id\":123,\"keywords\":[{\"keyword\":\"gato\"}]}]".utf8)
            return (200, data)
        }

        let results = try await client().search(" gato / perro ", language: "es-ES")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "gato")
        XCTAssertEqual(results.first?.thumbnailURL.absoluteString, "https://static.arasaac.org/pictograms/123/123_300.png")
    }

    func testEmptySearchDoesNotRequest() async throws {
        MockURLProtocol.handler = { _ in XCTFail("Unexpected request"); return (200, Data()) }
        let results = try await client().search("  ", language: "en")
        XCTAssertTrue(results.isEmpty)
    }

    func testUnknownLanguageFallsBackToEnglish() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/v1/pictograms/en/search/cat")
            return (200, Data("[]".utf8))
        }
        let results = try await client().search("cat", language: "fr-FR")
        XCTAssertTrue(results.isEmpty)
    }

    func testMalformedSearchResponseThrowsDecodingError() async {
        MockURLProtocol.handler = { _ in (200, Data("{\"results\":[]}".utf8)) }
        do {
            _ = try await client().search("cat", language: "en")
            XCTFail("Expected decoding to fail")
        } catch is DecodingError {
            // The endpoint must return a top-level array of pictograms.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNetworkFailurePropagates() async {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await client().search("cat", language: "en")
            XCTFail("Expected a transport error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHTTPFailureIsReported() async {
        MockURLProtocol.handler = { _ in (503, Data()) }
        do {
            _ = try await client().search("cat", language: "en")
            XCTFail("Expected an HTTP error")
        } catch ARASAACError.httpStatus(let status) {
            XCTAssertEqual(status, 503)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDownloadUsesFullSizePNG() async throws {
        let symbol = try makeSymbol(id: 123)
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://static.arasaac.org/pictograms/123/123_500.png")
            return (200, Data([0x89, 0x50, 0x4E, 0x47, 0x00]))
        }
        let selection = try await client().download(symbol)
        XCTAssertEqual(selection.symbol.id, 123)
        XCTAssertEqual(selection.imageData.count, 5)
    }

    func testDownloadRejectsNonPNGResponse() async throws {
        MockURLProtocol.handler = { _ in (200, Data("not a png".utf8)) }
        do {
            _ = try await client().download(makeSymbol(id: 123))
            XCTFail("Expected invalid image data")
        } catch ARASAACError.invalidImage {
            // A successful HTTP status alone is insufficient.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDownloadRejectsHTTPFailure() async throws {
        MockURLProtocol.handler = { _ in (404, Data()) }
        do {
            _ = try await client().download(makeSymbol(id: 123))
            XCTFail("Expected an HTTP error")
        } catch ARASAACError.httpStatus(let status) {
            XCTAssertEqual(status, 404)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDownloadSelectionPreservesOrder() async throws {
        let symbols = try [makeSymbol(id: 111), makeSymbol(id: 222)]
        var requestedIDs: [Int] = []
        MockURLProtocol.handler = { request in
            let id = Int(request.url!.deletingLastPathComponent().lastPathComponent)!
            requestedIDs.append(id)
            return (200, Data([0x89, 0x50, 0x4E, 0x47, UInt8(id % 256)]))
        }
        let selections = try await client().download(symbols)
        XCTAssertEqual(requestedIDs, [111, 222])
        XCTAssertEqual(selections.map(\.symbol.id), [111, 222])
    }

    func testDownloadSelectionFailsWithoutReturningPartialResults() async throws {
        let symbols = try [makeSymbol(id: 111), makeSymbol(id: 222)]
        var requestCount = 0
        MockURLProtocol.handler = { _ in
            requestCount += 1
            return requestCount == 1
                ? (200, Data([0x89, 0x50, 0x4E, 0x47]))
                : (503, Data())
        }
        do {
            _ = try await client().download(symbols)
            XCTFail("Expected the second download to fail")
        } catch ARASAACError.httpStatus(let status) {
            XCTAssertEqual(status, 503)
            XCTAssertEqual(requestCount, 2)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEmptyDownloadSelectionDoesNotRequest() async throws {
        MockURLProtocol.handler = { _ in XCTFail("Unexpected request"); return (200, Data()) }
        let selections = try await client().download([])
        XCTAssertTrue(selections.isEmpty)
    }

    private func makeSymbol(id: Int) throws -> ARASAACSymbol {
        try JSONDecoder().decode(ARASAACSymbol.self, from: Data("{\"_id\":\(id),\"keywords\":[]}".utf8))
    }

    private func client() -> ARASAACClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return ARASAACClient(session: URLSession(configuration: configuration))
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let (status, data) = try Self.handler!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
