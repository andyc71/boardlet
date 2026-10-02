import XCTest
@testable import OpenSymbols

final class OpenSymbolsClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testSearchEncodesQueryUsesLocaleAndAuthorizationHeader() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.scheme, "https")
            XCTAssertEqual(request.url?.host, "www.opensymbols.org")
            XCTAssertEqual(request.url?.path, "/api/v2/symbols")
            XCTAssertEqual(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "q" })?.value, "gato & perro/niño")
            XCTAssertEqual(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "locale" })?.value, "es")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "short-lived-token")
            XCTAssertFalse(request.url?.query?.contains("access_token") ?? false, "Token must stay out of the URL")
            return (200, Data(Self.sample.utf8))
        }

        let results = try await client().search(" gato & perro/niño ", language: "es-ES")
        XCTAssertEqual(results.count, 1)
        let symbol = try XCTUnwrap(results.first)
        XCTAssertEqual(symbol.id, 2211)
        XCTAssertEqual(symbol.title, "gato")
        XCTAssertEqual(symbol.license, "CC BY-NC-SA")
        XCTAssertEqual(symbol.author, "Sergio Palao")
        XCTAssertEqual(symbol.repositoryKey, "arasaac")
        XCTAssertEqual(symbol.imageURL.absoluteString, "https://cdn.example.org/gato.png")
        XCTAssertEqual(symbol.detailsURL?.absoluteString, "https://www.opensymbols.org/symbols/arasaac/gato?id=2211")
    }

    func testEmptyQueryDoesNotAskForTokenOrRequest() async throws {
        MockURLProtocol.handler = { _ in XCTFail("Unexpected request"); return (200, Data()) }
        let client = makeClient(tokenProvider: { XCTFail("Unexpected token request"); return "token" })
        let results = try await client.search(" \n ", language: "en")
        XCTAssertTrue(results.isEmpty)
    }

    func testUnknownLanguageFallsBackToEnglish() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "locale" })?.value, "en")
            return (200, Data("[]".utf8))
        }
        let results = try await client().search("cat", language: "English")
        XCTAssertTrue(results.isEmpty)
    }

    func testMissingTokenDoesNotRequest() async {
        MockURLProtocol.handler = { _ in XCTFail("Unexpected request"); return (200, Data()) }
        do {
            _ = try await makeClient(tokenProvider: { "  " }).search("cat", language: "en")
            XCTFail("Expected missing token")
        } catch OpenSymbolsError.missingAccessToken {
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testTokenProviderFailurePropagates() async {
        do {
            _ = try await makeClient(tokenProvider: { throw URLError(.userAuthenticationRequired) }).search("cat", language: "en")
            XCTFail("Expected provider failure")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .userAuthenticationRequired)
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testMalformedSearchResponseThrows() async {
        MockURLProtocol.handler = { _ in (200, Data("{\"results\":[]}".utf8)) }
        do {
            _ = try await client().search("cat", language: "en")
            XCTFail("Expected decoding failure")
        } catch is DecodingError {
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testTransportErrorPropagates() async {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await client().search("cat", language: "en")
            XCTFail("Expected network failure")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testExpiredTokenAndThrottleAreDistinguished() async {
        MockURLProtocol.handler = { _ in (401, Data("{\"token_expired\":true}".utf8)) }
        do {
            _ = try await client().search("cat", language: "en")
            XCTFail("Expected expired token")
        } catch OpenSymbolsError.tokenExpired {
        } catch { XCTFail("Unexpected error: \(error)") }

        MockURLProtocol.handler = { _ in (429, Data("{\"throttled\":true}".utf8)) }
        do {
            _ = try await client().search("cat", language: "en")
            XCTFail("Expected throttle")
        } catch OpenSymbolsError.throttled {
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testOtherHTTPFailuresAreReported() async {
        MockURLProtocol.handler = { _ in (503, Data()) }
        do {
            _ = try await client().search("cat", language: "en")
            XCTFail("Expected HTTP failure")
        } catch OpenSymbolsError.httpStatus(let status) {
            XCTAssertEqual(status, 503)
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testDownloadUsesImageURLWithoutAccessToken() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://cdn.example.org/2211.png")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            return (200, Self.png)
        }
        let selection = try await client().download(symbol())
        XCTAssertEqual(selection.symbol.id, 2211)
        XCTAssertEqual(selection.imageData, Self.png)
    }

    func testDownloadRejectsSVGWithoutRequest() async throws {
        MockURLProtocol.handler = { _ in XCTFail("Unexpected request"); return (200, Data()) }
        do {
            _ = try await client().download(symbol(extension: "svg"))
            XCTFail("Expected unsupported image")
        } catch OpenSymbolsError.unsupportedImageFormat(let format) {
            XCTAssertEqual(format, "svg")
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testDownloadRejectsInsecureImageURL() async throws {
        do {
            _ = try await client().download(symbol(imageURL: "http://cdn.example.org/gato.png"))
            XCTFail("Expected invalid image URL")
        } catch OpenSymbolsError.invalidImageURL {
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testDownloadRejectsWrongImageDataAndHTTPFailure() async throws {
        MockURLProtocol.handler = { _ in (200, Data("<html>oops</html>".utf8)) }
        do {
            _ = try await client().download(symbol())
            XCTFail("Expected invalid image")
        } catch OpenSymbolsError.invalidImage {
        } catch { XCTFail("Unexpected error: \(error)") }

        MockURLProtocol.handler = { _ in (404, Data()) }
        do {
            _ = try await client().download(symbol())
            XCTFail("Expected HTTP failure")
        } catch OpenSymbolsError.httpStatus(let status) {
            XCTAssertEqual(status, 404)
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testDownloadAcceptsJPEGAndGIFSignatures() async throws {
        MockURLProtocol.handler = { _ in (200, Data([0xFF, 0xD8, 0xFF, 0x00])) }
        let jpeg = try await client().download(symbol(extension: "jpg"))
        XCTAssertEqual(jpeg.imageData.count, 4)
        MockURLProtocol.handler = { _ in (200, Data("GIF89a".utf8)) }
        let gif = try await client().download(symbol(extension: "gif"))
        XCTAssertEqual(gif.imageData.count, 6)
    }

    func testBatchDownloadPreservesOrderAndFailsAtomically() async throws {
        let first = try symbol(id: 1)
        let second = try symbol(id: 2)
        var requests: [String] = []
        MockURLProtocol.handler = { request in
            requests.append(request.url!.lastPathComponent)
            return (200, Self.png)
        }
        let selections = try await client().download([first, second])
        XCTAssertEqual(selections.map(\.symbol.id), [1, 2])
        XCTAssertEqual(requests, ["1.png", "2.png"])

        requests = []
        MockURLProtocol.handler = { request in
            requests.append(request.url!.lastPathComponent)
            return requests.count == 1 ? (200, Self.png) : (503, Data())
        }
        do {
            _ = try await client().download([first, second])
            XCTFail("Expected second download to fail")
        } catch OpenSymbolsError.httpStatus(let status) {
            XCTAssertEqual(status, 503)
            XCTAssertEqual(requests, ["1.png", "2.png"])
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    private func client() -> OpenSymbolsClient { makeClient(tokenProvider: { "short-lived-token" }) }

    private func makeClient(tokenProvider: @escaping () async throws -> String) -> OpenSymbolsClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return OpenSymbolsClient(session: URLSession(configuration: configuration), accessTokenProvider: tokenProvider)
    }

    private func symbol(id: Int = 2211, extension fileExtension: String = "png", imageURL: String? = nil) throws -> OpenSymbolsSymbol {
        let url = imageURL ?? "https://cdn.example.org/\(id).\(fileExtension)"
        let json = Self.sample
            .replacingOccurrences(of: "2211", with: String(id))
            .replacingOccurrences(of: "https://cdn.example.org/gato.png", with: url)
            .replacingOccurrences(of: "\"extension\":\"png\"", with: "\"extension\":\"\(fileExtension)\"")
        return try JSONDecoder().decode([OpenSymbolsSymbol].self, from: Data(json.utf8))[0]
    }

    private static let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    private static let sample = """
    [{"id":2211,"symbol_key":"gato-1","name":"gato","locale":"es","license":"CC BY-NC-SA","license_url":"http://creativecommons.org/licenses/by-nc-sa/3.0/","author":"Sergio Palao","author_url":null,"source_url":null,"repo_key":"arasaac","extension":"png","image_url":"https://cdn.example.org/gato.png","details_url":"/symbols/arasaac/gato?id=2211"}]
    """
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
