import Foundation

/// Keep this metadata with saved images so callers can identify their source.
public struct AACStandardSymbol: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let languageCode: String
    public let imageURL: URL
    public let thumbnailURL: URL?

    public init(id: Int, name: String, languageCode: String, imageURL: URL, thumbnailURL: URL? = nil) {
        self.id = id
        self.name = name
        self.languageCode = languageCode
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
    }

    private enum CodingKeys: String, CodingKey {
        case id, name
        case languageCode = "language_code"
        case imageURL = "image_url"
        case thumbnailURL = "thumbnail_url"
    }

    public var title: String { name.isEmpty ? String(id) : name }
    public var sourceURL: URL { URL(string: "https://aacstandard.com/api/v1/symbols/\(id)")! }
    public static let licenseURL = URL(string: "https://aacstandard.com/license")!
    public static let attribution = "AAC Standard · © aisay.co"

    /// Use the PNG if a thumbnail is absent or has an unsafe URL.
    public var previewURL: URL? {
        if let thumbnailURL, Self.isHTTPS(thumbnailURL) { return thumbnailURL }
        return Self.isHTTPS(imageURL) ? imageURL : nil
    }

    static func isHTTPS(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host?.isEmpty == false && url.user == nil && url.password == nil
    }
}
