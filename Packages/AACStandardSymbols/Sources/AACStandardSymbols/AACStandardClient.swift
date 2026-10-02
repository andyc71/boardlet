import Foundation
import ImageIO

/// Public API client. No credentials required. Uses URLSession's HTTP cache policy.
public struct AACStandardClient: AACStandardServing {
    private let transport: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    public init(session: URLSession = .shared) {
        transport = { try await session.data(for: $0) }
    }

    // A per-client transport avoids shared mutable URLProtocol handlers in tests.
    init(transport: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) {
        self.transport = transport
    }

    /// Convenience matching ARASAACClient. Returns the first page (up to 50 symbols).
    public func search(_ term: String, language: String) async throws -> [AACStandardSymbol] {
        try await search(AACStandardSearchRequest(term: term, language: language)).symbols
    }

    public func search(_ request: AACStandardSearchRequest) async throws -> AACStandardSearchPage {
        try Task.checkCancellation()
        guard (1...100).contains(request.limit), request.offset >= 0,
              request.offset <= Int.max - request.limit else { throw AACStandardError.invalidPagination }
        let term = request.term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return AACStandardSearchPage(symbols: [], nextOffset: nil) }

        var url = URLComponents(string: "https://aacstandard.com/api/v1/public/symbols/search")!
        url.queryItems = [
            URLQueryItem(name: "q", value: term),
            URLQueryItem(name: "language", value: request.languageCode),
            URLQueryItem(name: "limit", value: String(request.limit)),
            URLQueryItem(name: "offset", value: String(request.offset))
        ]
        if let ageGroup = request.ageGroup {
            url.queryItems?.append(URLQueryItem(name: "age_group", value: ageGroup.rawValue))
        }
        let data = try await perform(url.url!, accept: "application/json")
        let symbols = try decodeEnvelope([AACStandardSymbol].self, from: data)
        return AACStandardSearchPage(symbols: symbols,
                                     nextOffset: symbols.count == request.limit ? request.offset + symbols.count : nil)
    }

    public func supportedLanguages() async throws -> [String] {
        let data = try await perform(URL(string: "https://aacstandard.com/api/v1/translations/languages")!,
                                     accept: "application/json")
        return try decodeEnvelope([String].self, from: data)
    }

    public func download(_ symbol: AACStandardSymbol) async throws -> AACStandardSelection {
        guard AACStandardSymbol.isHTTPS(symbol.imageURL) else { throw AACStandardError.invalidImageURL }
        let data = try await perform(symbol.imageURL, accept: "image/png")
        // A signature alone would accept truncated PNGs. Verify the image can actually be decoded.
        guard data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { throw AACStandardError.invalidImage }
        try Task.checkCancellation()
        return AACStandardSelection(symbol: symbol, imageData: data)
    }

    /// Preserves tap order and returns only a complete selection, as in ARASAACClient.
    public func download(_ symbols: [AACStandardSymbol]) async throws -> [AACStandardSelection] {
        try Task.checkCancellation()
        var selections: [AACStandardSelection] = []
        for symbol in symbols {
            try Task.checkCancellation()
            selections.append(try await download(symbol))
        }
        return selections
    }

    private func perform(_ url: URL, accept: String) async throws -> Data {
        try Task.checkCancellation()
        var request = URLRequest(url: url)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await transport(request)
        } catch {
            try Task.checkCancellation()
            throw error
        }
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw AACStandardError.invalidResponse }
        switch response.statusCode {
        case 200..<300: return data
        case 429: throw AACStandardError.throttled(retryAfter: response.value(forHTTPHeaderField: "Retry-After"))
        default: throw AACStandardError.httpStatus(response.statusCode)
        }
    }

    private func decodeEnvelope<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        let decoder = JSONDecoder()
        // Check success before requiring data, since error envelopes may omit it.
        guard try decoder.decode(Status.self, from: data).success else { throw AACStandardError.serviceFailure }
        return try decoder.decode(Envelope<Value>.self, from: data).data
    }
}

private struct Status: Decodable { let success: Bool }
private struct Envelope<Value: Decodable>: Decodable { let data: Value }
