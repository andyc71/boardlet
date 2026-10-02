import XCTest
@testable import AACStandardSymbols

final class AACStandardClientTests: XCTestCase {
    func testSearchContractAndEscaping() async throws {
        let client = AACStandardClient { request in
            XCTAssertEqual(request.url?.path, "/api/v1/public/symbols/search")
            XCTAssertEqual(request.url?.host, "aacstandard.com")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            let values = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value!) })
            XCTAssertEqual(values, ["q": "gato / perro & + água?", "language": "es", "age_group": "child", "limit": "2", "offset": "4"])
            return response(request, data: searchFixture)
        }
        let page = try await client.search(.init(term: " gato / perro & + água? \n", language: "es_ES",
                                                 ageGroup: .child, limit: 2, offset: 4))
        XCTAssertEqual(page.symbols.map(\.id), [1417, 307])
        XCTAssertEqual(page.symbols.first?.title, "water")
        XCTAssertEqual(page.symbols.first?.languageCode, "en")
        XCTAssertEqual(page.symbols.first?.thumbnailURL?.pathExtension, "webp")
        XCTAssertEqual(page.nextOffset, 6)
    }

    func testCountIsNotATotalAndShortPageEndsPagination() async throws {
        let client = AACStandardClient { response($0, data: searchFixture) }
        let page = try await client.search(.init(term: "water", limit: 50, offset: 50))
        XCTAssertNil(page.nextOffset)
        XCTAssertEqual(page.symbols.count, 2)
    }

    func testEmptyAndWhitespaceSearchDoNotRequest() async throws {
        let client = AACStandardClient { _ in XCTFail("Unexpected request"); throw URLError(.badURL) }
        let results = try await client.search(" \n ", language: "en")
        XCTAssertTrue(results.isEmpty)
        let downloads = try await client.download([])
        XCTAssertTrue(downloads.isEmpty)
    }

    func testInvalidPaginationDoesNotRequest() async throws {
        let client = AACStandardClient { _ in XCTFail("Unexpected request"); throw URLError(.badURL) }
        for (limit, offset) in [(0, 0), (101, 0), (1, -1), (50, Int.max)] {
            do {
                _ = try await client.search(.init(term: "cat", limit: limit, offset: offset))
                XCTFail("Expected validation error")
            } catch { XCTAssertEqual(error as? AACStandardError, .invalidPagination) }
        }
    }

    func testLanguageNormalization() {
        for (input, expected) in [("EN-gb", "en"), ("es_ES", "es"), (" pl ", "pl"), ("fr", "fr"), ("", "en"), ("bad", "en")] {
            XCTAssertEqual(AACStandardSearchRequest(term: "cat", language: input).languageCode, expected)
        }
    }

    func testLanguagesEnvelope() async throws {
        let client = AACStandardClient { request in
            XCTAssertEqual(request.url?.path, "/api/v1/translations/languages")
            return response(request, data: Data(#"{"success":true,"data":["pl","en","es"]}"#.utf8))
        }
        let languages = try await client.supportedLanguages()
        XCTAssertEqual(languages, ["pl", "en", "es"])
    }

    func testFailureEnvelopeWithoutData() async throws {
        let client = AACStandardClient { response($0, data: Data(#"{"success":false,"error":"unavailable"}"#.utf8)) }
        do {
            _ = try await client.search("cat", language: "en")
            XCTFail("Expected service error")
        } catch { XCTAssertEqual(error as? AACStandardError, .serviceFailure) }
    }

    func testMalformedResponse() async throws {
        let client = AACStandardClient { response($0, data: Data(#"{"success":true,"data":{}}"#.utf8)) }
        do {
            _ = try await client.search("cat", language: "en")
            XCTFail("Expected decoding error")
        } catch is DecodingError {} catch { XCTFail("Unexpected: \(error)") }
    }

    func testHTTPAndThrottlingErrors() async throws {
        for status in [401, 404, 429, 503] {
            let client = AACStandardClient { response($0, status: status, headers: ["Retry-After": "60"]) }
            do {
                _ = try await client.search("cat", language: "en")
                XCTFail("Expected HTTP error")
            } catch {
                XCTAssertEqual(error as? AACStandardError, status == 429 ? .throttled(retryAfter: "60") : .httpStatus(status))
            }
        }
    }

    func testNonHTTPResponse() async throws {
        let client = AACStandardClient { (Data(), URLResponse(url: $0.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)) }
        do {
            _ = try await client.search("cat", language: "en")
            XCTFail("Expected invalid response")
        } catch { XCTAssertEqual(error as? AACStandardError, .invalidResponse) }
    }

    func testTransportErrorPropagates() async throws {
        let client = AACStandardClient { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await client.search("cat", language: "en")
            XCTFail("Expected transport error")
        } catch { XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet) }
    }

    func testDownloadDecodesPNGAndPreservesOrderAndMetadata() async throws {
        let recorder = RequestRecorder()
        let client = AACStandardClient { request in
            await recorder.append(request)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "image/png")
            return response(request, data: png)
        }
        let selections = try await client.download([symbol(2), symbol(1)])
        XCTAssertEqual(selections.map(\.symbol.id), [2, 1])
        XCTAssertEqual(selections.first?.imageData, png)
        let paths = await recorder.requests.map { $0.url!.lastPathComponent }
        XCTAssertEqual(paths, ["2.png", "1.png"])
    }

    func testDownloadRejectsHTMLAndTruncatedPNG() async throws {
        for invalid in [Data("<html>error</html>".utf8), Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])] {
            let client = AACStandardClient { response($0, data: invalid) }
            do {
                _ = try await client.download(symbol(1))
                XCTFail("Expected invalid image")
            } catch { XCTAssertEqual(error as? AACStandardError, .invalidImage) }
        }
    }

    func testInvalidImageURLDoesNotRequest() async throws {
        let client = AACStandardClient { _ in XCTFail("Unexpected request"); throw URLError(.badURL) }
        for url in ["http://example.com/a.png", "file:///tmp/a.png", "/static/a.png", "https://user:pass@example.com/a.png"] {
            let item = AACStandardSymbol(id: 1, name: "", languageCode: "en", imageURL: URL(string: url)!)
            XCTAssertNil(item.previewURL)
            do {
                _ = try await client.download(item)
                XCTFail("Expected invalid URL")
            } catch { XCTAssertEqual(error as? AACStandardError, .invalidImageURL) }
        }
    }

    func testBatchStopsOnFailureWithoutReturningPartialSelection() async throws {
        let recorder = RequestRecorder()
        let client = AACStandardClient { request in
            await recorder.append(request)
            return response(request, status: request.url!.lastPathComponent == "2.png" ? 503 : 200, data: png)
        }
        do {
            _ = try await client.download([symbol(1), symbol(2), symbol(3)])
            XCTFail("Expected whole operation to fail")
        } catch { XCTAssertEqual(error as? AACStandardError, .httpStatus(503)) }
        let count = await recorder.requests.count
        XCTAssertEqual(count, 2)
    }

    func testCancelledTaskDoesNotRequest() async throws {
        let client = AACStandardClient { _ in XCTFail("Unexpected request"); throw URLError(.badURL) }
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await client.search("water", language: "en")
        }
        do { _ = try await task.value; XCTFail("Expected cancellation") }
        catch is CancellationError {} catch { XCTFail("Unexpected: \(error)") }
    }

    func testMissingThumbnailAndMetadataRoundTrip() throws {
        let data = Data(#"{"id":1,"name":"","language_code":"en","image_url":"https://aacstandard.com/static/1.png"}"#.utf8)
        let item = try JSONDecoder().decode(AACStandardSymbol.self, from: data)
        XCTAssertEqual(item.title, "1")
        XCTAssertEqual(item.previewURL, item.imageURL)
        XCTAssertEqual(try JSONDecoder().decode(AACStandardSymbol.self, from: JSONEncoder().encode(item)), item)
    }
}

private actor RequestRecorder {
    var requests: [URLRequest] = []
    func append(_ request: URLRequest) { requests.append(request) }
}

func symbol(_ id: Int) -> AACStandardSymbol {
    AACStandardSymbol(id: id, name: "Symbol \(id)", languageCode: "en",
                      imageURL: URL(string: "https://aacstandard.com/static/\(id).png")!)
}

private func response(_ request: URLRequest, status: Int = 200, headers: [String: String]? = nil,
                      data: Data = Data()) -> (Data, URLResponse) {
    (data, HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!)
}

// Locally generated 1x1 PNG; no third-party artwork is bundled in tests.
private let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a/ZsAAAAASUVORK5CYII=")!

// Shape and fields verified against the public endpoint; URLs are not fetched by tests.
private let searchFixture = Data(#"{"success":true,"data":[{"id":1417,"name":"water","language_code":"en","image_url":"https://aacstandard.com/static/symbols/pl/aac_pl_podlewac_1783667714865.png","thumbnail_url":"https://aacstandard.com/static/thumbs/256/symbols/pl/aac_pl_podlewac_1783667714865.webp"},{"id":307,"name":"water","language_code":"en","image_url":"https://aacstandard.com/static/symbols/pl/aac_pl_woda_1775994572378.png","thumbnail_url":"https://aacstandard.com/static/thumbs/256/symbols/pl/aac_pl_woda_1775994572378.webp"}],"count":2}"#.utf8)
