import Foundation

public enum AACStandardAgeGroup: String, Codable, CaseIterable, Sendable {
    case child, youth, adult, all
}

public struct AACStandardSearchRequest: Equatable, Sendable {
    public var term: String
    public var language: String
    /// nil leaves filtering to the service; `.all` sends the explicit API value.
    public var ageGroup: AACStandardAgeGroup?
    public var limit: Int
    public var offset: Int

    public init(term: String, language: String = "en", ageGroup: AACStandardAgeGroup? = nil,
                limit: Int = 50, offset: Int = 0) {
        self.term = term
        self.language = language
        self.ageGroup = ageGroup
        self.limit = limit
        self.offset = offset
    }

    /// Accepts locale identifiers such as es-ES or en_GB. Unknown codes pass through to the API.
    public var languageCode: String {
        let code = language.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init)?.lowercased() ?? "en"
        return code.count == 2 && code.allSatisfy { $0.isASCII && $0.isLetter } ? code : "en"
    }
}

public struct AACStandardSearchPage: Sendable {
    public let symbols: [AACStandardSymbol]
    /// The API has no total or has-more field. A full page may require one final empty request.
    public let nextOffset: Int?

    public init(symbols: [AACStandardSymbol], nextOffset: Int?) {
        self.symbols = symbols
        self.nextOffset = nextOffset
    }
}

/// Injectable service boundary, following Dynavox's async search-service pattern.
public protocol AACStandardServing: Sendable {
    func search(_ request: AACStandardSearchRequest) async throws -> AACStandardSearchPage
    func download(_ symbols: [AACStandardSymbol]) async throws -> [AACStandardSelection]
}
