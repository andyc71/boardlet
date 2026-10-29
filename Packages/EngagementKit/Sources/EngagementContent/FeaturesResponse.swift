import Foundation

public struct FeaturesResponse: Codable {
    public var releaseID: String?
    public var campaignID: String?
    public var lastModified: Date
    public var title: String
    public var header: String?
    public var footer: String?
    public var buttonTitle: String
    public var features: [Feature]

    // Compatibility for existing clients; both forms use the same release-ID policy.
    public var effectiveReleaseID: String {
        releaseID ?? "legacy-date:\(lastModified.timeIntervalSince1970)"
    }

    public static func load(for locale: String, in bundle: Bundle, subdirectory: String? = nil,
                     fileNamePrefix: String? = nil) throws -> FeaturesResponse {
        let prefix = fileNamePrefix ?? "Features"
        let normalized = locale.replacingOccurrences(of: "_", with: "-")
        let language = normalized.split(separator: "-").first.map(String.init) ?? locale
        var candidates: [String] = []
        for candidate in [locale, normalized, language, "en"] where !candidates.contains(candidate) {
            candidates.append(candidate)
        }
        var lastError: VotingPromptError?
        for candidate in candidates {
            guard let url = bundle.url(forResource: "\(prefix)_\(candidate)", withExtension: "json",
                                       subdirectory: subdirectory) else { continue }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let response = try decoder.decode(Self.self, from: Data(contentsOf: url))
                if let id = response.releaseID, id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw CocoaError(.fileReadCorruptFile)
                }
                return response
            } catch {
                lastError = .jsonDecodingError(error: error, locale: candidate)
            }
        }
        throw lastError ?? .jsonNotFound(locale: locale)
    }
}
