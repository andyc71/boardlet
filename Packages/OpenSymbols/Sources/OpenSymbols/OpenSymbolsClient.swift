import Foundation

/// A search result from OpenSymbols. Keep the credit fields with any saved or exported image.
public struct OpenSymbolsSymbol: Decodable, Hashable, Identifiable {
    public let id: Int
    public let symbolKey: String
    public let name: String
    public let locale: String
    public let license: String
    public let licenseURL: URL?
    public let author: String?
    public let authorURL: URL?
    public let sourceURL: URL?
    public let repositoryKey: String
    public let fileExtension: String
    public let imageURL: URL
    public let detailsPath: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, locale, license, author
        case symbolKey = "symbol_key"
        case licenseURL = "license_url"
        case authorURL = "author_url"
        case sourceURL = "source_url"
        case repositoryKey = "repo_key"
        case fileExtension = "extension"
        case imageURL = "image_url"
        case detailsPath = "details_url"
    }

    public var title: String { name.isEmpty ? symbolKey : name }

    /// OpenSymbols hosts detail paths relative to its web site.
    public var detailsURL: URL? {
        guard let detailsPath else { return nil }
        return URL(string: detailsPath, relativeTo: URL(string: "https://www.opensymbols.org"))?.absoluteURL
    }
}

public struct OpenSymbolsSelection {
    public let symbol: OpenSymbolsSymbol
    public let imageData: Data
}

public enum OpenSymbolsError: Error, LocalizedError {
    case missingAccessToken
    case invalidResponse
    case tokenExpired
    case throttled
    case httpStatus(Int)
    case unsupportedImageFormat(String)
    case invalidImageURL
    case invalidImage

    public var errorDescription: String? {
        switch self {
        case .missingAccessToken: return "An OpenSymbols access token is required."
        case .invalidResponse: return "OpenSymbols returned an invalid response."
        case .tokenExpired: return "The OpenSymbols access token expired."
        case .throttled: return "OpenSymbols is temporarily limiting requests."
        case .httpStatus(let status): return "OpenSymbols returned HTTP \(status)."
        case .unsupportedImageFormat(let format): return "OpenSymbols image format \(format) is not supported."
        case .invalidImageURL: return "OpenSymbols returned an invalid image URL."
        case .invalidImage: return "OpenSymbols returned invalid image data."
        }
    }
}

/// Searches OpenSymbols using a short-lived token supplied by the caller.
/// Obtain that token from a trusted server; never put the shared secret in an app binary.
public struct OpenSymbolsClient {
    private let session: URLSession
    private let accessTokenProvider: () async throws -> String

    public init(
        session: URLSession = .shared,
        accessTokenProvider: @escaping () async throws -> String
    ) {
        self.session = session
        self.accessTokenProvider = accessTokenProvider
    }

    public func search(_ term: String, language: String) async throws -> [OpenSymbolsSymbol] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let languageCode = language.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init)?.lowercased() ?? "en"
        let locale = languageCode.count == 2 && languageCode.allSatisfy({ $0.isASCII && $0.isLetter }) ? languageCode : "en"
        var components = URLComponents(string: "https://www.opensymbols.org/api/v2/symbols")!
        components.queryItems = [URLQueryItem(name: "q", value: trimmed), URLQueryItem(name: "locale", value: locale)]

        let token = try await accessTokenProvider()
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenSymbolsError.missingAccessToken
        }
        var request = URLRequest(url: components.url!)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data = try await perform(request)
        return try JSONDecoder().decode([OpenSymbolsSymbol].self, from: data)
    }

    /// Downloads a raster image. OpenSymbols also indexes SVG files, which UIKit cannot decode directly.
    public func download(_ symbol: OpenSymbolsSymbol) async throws -> OpenSymbolsSelection {
        let format = symbol.fileExtension.lowercased()
        guard ["png", "jpg", "jpeg", "gif"].contains(format) else {
            throw OpenSymbolsError.unsupportedImageFormat(symbol.fileExtension)
        }
        guard symbol.imageURL.scheme?.lowercased() == "https", symbol.imageURL.host != nil else {
            throw OpenSymbolsError.invalidImageURL
        }
        var request = URLRequest(url: symbol.imageURL)
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        let data = try await perform(request)
        let isPNG = data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        let isJPEG = data.starts(with: [0xFF, 0xD8, 0xFF])
        let isGIF = data.starts(with: Array("GIF87a".utf8)) || data.starts(with: Array("GIF89a".utf8))
        guard (format == "png" && isPNG) || (["jpg", "jpeg"].contains(format) && isJPEG) || (format == "gif" && isGIF) else {
            throw OpenSymbolsError.invalidImage
        }
        return OpenSymbolsSelection(symbol: symbol, imageData: data)
    }

    /// Returns every selected image in order, or throws without returning a partial result.
    public func download(_ symbols: [OpenSymbolsSymbol]) async throws -> [OpenSymbolsSelection] {
        var selections: [OpenSymbolsSelection] = []
        for symbol in symbols {
            try Task.checkCancellation()
            selections.append(try await download(symbol))
        }
        return selections
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw OpenSymbolsError.invalidResponse }
        switch response.statusCode {
        case 200..<300: return data
        case 401:
            if (try? JSONDecoder().decode(TokenError.self, from: data))?.tokenExpired == true {
                throw OpenSymbolsError.tokenExpired
            }
            throw OpenSymbolsError.httpStatus(401)
        case 429: throw OpenSymbolsError.throttled
        default: throw OpenSymbolsError.httpStatus(response.statusCode)
        }
    }
}

private struct TokenError: Decodable {
    let tokenExpired: Bool

    private enum CodingKeys: String, CodingKey { case tokenExpired = "token_expired" }
}
