import Foundation

/// Uses the same localized release-note resources as the existing feature framework.
struct ReleaseNotes: Decodable {
    struct Feature: Decodable, Identifiable {
        let id: String
        let systemIcon: String
        let name: String
        let description: String
    }
    let title: String
    let header: String?
    let footer: String?
    let buttonTitle: String
    let features: [Feature]

    static func load(locale: String, bundle: Bundle = .main) -> ReleaseNotes? {
        for language in [locale, String(locale.prefix(2)), "en"] {
            if let url = bundle.url(forResource: "WhatsNew_\(language)", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let notes = try? JSONDecoder().decode(Self.self, from: data) {
                return notes
            }
        }
        return nil
    }
}
