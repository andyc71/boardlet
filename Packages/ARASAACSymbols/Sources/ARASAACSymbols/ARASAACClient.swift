import Foundation

/// A pictogram returned by ARASAAC's public search API.
public struct ARASAACSymbol: Decodable, Hashable, Identifiable, Sendable {
    public struct Keyword: Decodable, Hashable, Sendable {
        public let keyword: String
    }

    public let id: Int
    public let keywords: [Keyword]

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case keywords
    }

    public var title: String { keywords.first?.keyword ?? String(id) }

    /// Compare the displayed words, ignoring case, accents and punctuation.
    func matchesSuggestion(_ term: String) -> Bool {
        guard let label = keywords.first?.keyword else { return false }
        return !Self.suggestionForms(label).isDisjoint(with: Self.suggestionForms(term))
    }

    private static func suggestionForms(_ text: String) -> Set<String> {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                  locale: Locale(identifier: "en_US_POSIX"))
        let withoutApostrophes = folded.filter { !["'", "’", "‘", "ʼ"].contains($0) }
        let pieces = withoutApostrophes.components(separatedBy: .punctuationCharacters)
        // Punctuation can be omitted (ice-cream / icecream) or separate words
        // (ice-cream / ice cream). Ordinary word boundaries remain significant.
        return Set([pieces.joined(), pieces.joined(separator: " ")].map {
            $0.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        }.filter { !$0.isEmpty })
    }

    public var thumbnailURL: URL {
        URL(string: "https://static.arasaac.org/pictograms/\(id)/\(id)_300.png")!
    }

    public var imageURL: URL {
        URL(string: "https://static.arasaac.org/pictograms/\(id)/\(id)_500.png")!
    }
}

public struct ARASAACSelection: Sendable {
    public let symbol: ARASAACSymbol
    public let imageData: Data
}

public enum ARASAACError: Error, LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case invalidImage

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "ARASAAC returned an invalid response."
        case .httpStatus(let status): return "ARASAAC returned HTTP \(status)."
        case .invalidImage: return "ARASAAC returned invalid image data."
        }
    }
}

/// Searches ARASAAC and downloads pictograms without an API key.
public struct ARASAACClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(_ term: String, language: String) async throws -> [ARASAACSymbol] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let locale = language.lowercased().hasPrefix("es") ? "es" : "en"
        // Encode the search term as one path segment, including any slashes or punctuation.
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let url = URL(string: "https://api.arasaac.org/v1/pictograms/\(locale)/search/\(encoded)")!
        let data: Data
        do {
            data = try await request(url)
        } catch ARASAACError.httpStatus(404) {
            // ARASAAC uses 404 for searches with no matching pictograms.
            // Keep this handling here so a missing image still reports an error.
            return []
        }
        return try JSONDecoder().decode([ARASAACSymbol].self, from: data)
    }

    public func download(_ symbol: ARASAACSymbol) async throws -> ARASAACSelection {
        let data = try await request(symbol.imageURL)
        guard data.starts(with: [0x89, 0x50, 0x4E, 0x47]) else {
            throw ARASAACError.invalidImage
        }
        return ARASAACSelection(symbol: symbol, imageData: data)
    }

    /// Downloads a complete selection in order. A failed download throws instead of returning a partial selection.
    public func download(_ symbols: [ARASAACSymbol]) async throws -> [ARASAACSelection] {
        var selections: [ARASAACSelection] = []
        for symbol in symbols {
            try Task.checkCancellation()
            selections.append(try await download(symbol))
        }
        return selections
    }

    private func request(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("application/json, image/png", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else {
            throw ARASAACError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw ARASAACError.httpStatus(response.statusCode)
        }
        return data
    }
}
