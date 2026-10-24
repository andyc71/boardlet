import Foundation

/// BCP-47 lookup is bounded by the tag's components, never by the number of translations.
enum BoardLanguage {
    static let unassigned = "und"
    static var appLanguage: String { normalize(Bundle.main.preferredLocalizations.first ?? "en") }

    static func normalize(_ language: String) -> String {
        Locale.canonicalLanguageIdentifier(from: language.replacingOccurrences(of: "_", with: "-"))
            .replacingOccurrences(of: "_", with: "-")
    }

    static func candidates(for language: String) -> [String] {
        let normalized = normalize(language)
        var parts = normalized.split(separator: "-").map(String.init)
        // Extensions/private use are not translation languages.
        if let extensionIndex = parts.dropFirst().firstIndex(where: { $0.count == 1 }) {
            parts = Array(parts.prefix(extensionIndex))
        }
        var result = [parts.joined(separator: "-")]
        // A region can imply a script (zh-TW → zh-Hant) without permitting a
        // fallback to an unrelated regional translation (zh-CN).
        if parts.count > 1, !parts.contains(where: { $0.count == 4 }),
           let script = Locale(identifier: normalized).language.script?.identifier {
            result.append("\(parts[0])-\(script)")
        }
        while parts.count > 1 {
            parts.removeLast()
            let tag = parts.joined(separator: "-")
            if !result.contains(tag) { result.append(tag) }
        }
        return result
    }
}

struct BoardText: Codable, Equatable {
    var key: String
    var sourceLanguage: String
    /// Kept in memory; board encoding writes these into per-language string tables.
    var values: [String: String] = [:]

    enum CodingKeys: String, CodingKey { case key, sourceLanguage, values }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        sourceLanguage = try container.decode(String.self, forKey: .sourceLanguage)
        values = try container.decodeIfPresent([String: String].self, forKey: .values) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(sourceLanguage, forKey: .sourceLanguage)
        if encoder.userInfo[.boardStringTables] == nil { try container.encode(values, forKey: .values) }
    }

    init(key: String = UUID().uuidString, sourceLanguage: String, text: String?) {
        self.key = key
        self.sourceLanguage = BoardLanguage.normalize(sourceLanguage)
        if let text { values[self.sourceLanguage] = text }
    }

    func resolve(language: String) -> (text: String?, language: String?) {
        for candidate in BoardLanguage.candidates(for: language) {
            if let value = values[candidate] { return (value, candidate) }
        }
        if let value = values[sourceLanguage] { return (value, sourceLanguage == BoardLanguage.unassigned ? nil : sourceLanguage) }
        return (nil, nil)
    }

    mutating func edit(_ text: String?, language: String) {
        let language = BoardLanguage.normalize(language)
        if values.isEmpty, text != nil { sourceLanguage = language }
        values[language] = text
    }

    mutating func load(tables: [String: [String: String]]) {
        values = tables.compactMapValues { $0[key] }
    }
}

struct BoardLocalization: Codable {
    var title: BoardText
    /// nil means Follow app language; source languages remain independent.
    var preferredLanguage: String?
    var languages: [String]
    var tableFiles: [String: String]?
}

extension CodingUserInfoKey {
    static let boardStringTables = CodingUserInfoKey(rawValue: "boardStringTables")!
    static let boardEditingLanguage = CodingUserInfoKey(rawValue: "boardEditingLanguage")!
}
