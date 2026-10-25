import Foundation
import CryptoKit

public enum LibraryError: Error, LocalizedError {
    case invalid(String)
    public var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}

public enum DocumentPaths {
    public static func owned(_ path: String, by root: URL) throws -> URL {
        guard !path.hasPrefix("/"), !path.split(separator: "/").contains("..") else { throw LibraryError.invalid("Unsafe document path: \(path)") }
        let base = root.resolvingSymlinksInPath().standardizedFileURL
        let url = base.appendingPathComponent(path).resolvingSymlinksInPath().standardizedFileURL
        guard url.path.hasPrefix(base.path + "/") else { throw LibraryError.invalid("Resource escapes its board: \(url.path) outside \(base.path)") }
        return url
    }
    public static func provisionalID(_ path: String) -> UUID {
        if let id = UUID(uuidString: String(URL(fileURLWithPath: path).lastPathComponent.suffix(36))) { return id }
        var bytes = Array(SHA256.hash(data: Data(path.utf8)).prefix(16))
        bytes[6] = (bytes[6] & 15) | 80; bytes[8] = (bytes[8] & 63) | 128
        return UUID(uuid: (bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]))
    }
}

public struct LibraryText: Codable, Equatable, Sendable {
    public var key: String? = nil
    public var source: String
    public var values: [String: String]
    public static func candidates(_ language: String) -> [String] {
        let normalized = Locale.canonicalLanguageIdentifier(from: language.replacingOccurrences(of: "_", with: "-")).replacingOccurrences(of: "_", with: "-")
        var parts = normalized.split(separator: "-").map(String.init)
        if let i = parts.dropFirst().firstIndex(where: { $0.count == 1 }) { parts = Array(parts.prefix(i)) }
        var result = [parts.joined(separator: "-")]
        if parts.count > 1, !parts.contains(where: { $0.count == 4 }), let script = Locale(identifier: normalized).language.script?.identifier { result.append("\(parts[0])-\(script)") }
        while parts.count > 1 { parts.removeLast(); let tag = parts.joined(separator: "-"); if !result.contains(tag) { result.append(tag) } }
        return result
    }
    public func resolve(_ language: String) -> (String, String) {
        for tag in Self.candidates(language) + [source] { if let value = values[tag] { return (value, tag) } }
        return ("", source)
    }
}

public struct LibraryCard: Codable, Sendable {
    public var id: UUID
    public var position: Int
    public var text: LibraryText
    public var image: String?
    public var imageOverrides: [String: String] = [:]
}

public struct BoardDocument: Codable, Sendable {
    public var id: UUID
    public var version: Int
    public var revision: String
    public var title: LibraryText
    public var language: String?
    public var cover: String?
    public var covers: [String: String]
    public var children: [UUID]
    public var cards: [LibraryCard]
    public var fingerprint: String
    public var resourceTables: [String]
}

/// A JSON-only projection. This module cannot import UIKit, Photos or PECSRepo.
public enum BoardDocumentReader {
    public static func read(_ directory: URL, relativePath: String, legacyCatalog: URL? = nil) throws -> BoardDocument {
        try autoreleasepool { try decode(directory, relativePath: relativePath, legacyCatalog: legacyCatalog) }
    }
    private static func decode(_ directory: URL, relativePath: String, legacyCatalog: URL?) throws -> BoardDocument {
        let data = try Data(contentsOf: DocumentPaths.owned("index.json", by: directory))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let version = json["version"] as? Int, (1...3).contains(version),
              let topic = json["topic"] as? [String: Any],
              let photos = json["photos"] as? [String: Any] else { throw LibraryError.invalid("Invalid or unsupported board at \(relativePath)") }
        let items = photos["photoItems"] as? [[String: Any]] ?? []
        let localization = json["localization"] as? [String: Any]
        var tables: [String: [String: String]] = [:]
        var digest = SHA256(); digest.update(data: data)
        for language in localization?["languages"] as? [String] ?? [] {
            let filename = (localization?["tableFiles"] as? [String: String])?[language] ?? "strings.json"
            let bytes = try Data(contentsOf: DocumentPaths.owned("locales/\(language)/\(filename)", by: directory))
            digest.update(data: bytes)
            tables[language] = try JSONDecoder().decode([String: String].self, from: bytes)
        }
        func text(_ value: Any?, legacy: String) -> LibraryText {
            guard let reference = value as? [String: Any], let key = reference["key"] as? String else { return LibraryText(source: "und", values: ["und": legacy]) }
            return LibraryText(key: key, source: reference["sourceLanguage"] as? String ?? "und", values: tables.isEmpty ? reference["values"] as? [String: String] ?? [:] : tables.compactMapValues { $0[key] })
        }
        func validateResource(_ value: String?) throws -> String? { if let value { guard value.split(separator: "/").first?.lowercased() != "children" else { throw LibraryError.invalid("A resource cannot belong to a child board") }; _ = try DocumentPaths.owned(value, by: directory) }; return value }
        var cards = try items.enumerated().compactMap { position, item -> LibraryCard? in
            if item["isPlaceholder"] as? Bool == true { return nil }
            guard let raw = item["id"] as? String, let id = UUID(uuidString: raw) else { throw LibraryError.invalid("Card has no stable identity") }
            _ = try validateResource(item["audioFileName"] as? String)
            for path in (item["imageOverrides"] as? [String: String] ?? [:]).values { _ = try validateResource(path) }
            return LibraryCard(id: id, position: position, text: text(item["localizedTitle"], legacy: item["title"] as? String ?? ""), image: try validateResource(item["imageFileName"] as? String), imageOverrides: item["imageOverrides"] as? [String: String] ?? [:])
        }
        let covers = json["coverImagePaths"] as? [String: String] ?? [:]
        for path in covers.values { _ = try validateResource(path) }
        var projectedTitle = text(localization?["title"], legacy: topic["topicName"] as? String ?? "")
        var legacyImages: [String] = []
        if localization == nil, let legacyCatalog {
            struct Legacy: Decodable {
                struct Card: Decodable { var key: String; var title: String; var imageSHA256: String }
                var canonicalDirectory: String; var language: String; var title: String; var cards: [String: Card]
            }
            let aliases = try JSONDecoder().decode([String: Legacy].self, from: Data(contentsOf:legacyCatalog.appendingPathComponent("legacy.json")))
            if let original = aliases[directory.lastPathComponent] {
                let catalog = try read(legacyCatalog.appendingPathComponent("topics").appendingPathComponent(original.canonicalDirectory), relativePath:original.canonicalDirectory)
                if topic["topicName"] as? String == original.title { projectedTitle = catalog.title; projectedTitle.source = original.language }
                for i in cards.indices {
                    guard let old = original.cards[cards[i].id.uuidString], cards[i].text.resolve("und").0 == old.title,
                          let path = cards[i].image else { continue }
                    legacyImages.append(path)
                    if let bytes = try? Data(contentsOf:DocumentPaths.owned(path,by:directory)),
                       SHA256.hash(data:bytes).map({ String(format:"%02x",$0) }).joined() == old.imageSHA256,
                       var translated = catalog.cards.first(where: { $0.text.key == old.key })?.text {
                        translated.source = original.language; cards[i].text = translated
                        digest.update(data:bytes)
                    }
                }
            }
        }
        return BoardDocument(id: (json["id"] as? String).flatMap(UUID.init(uuidString:)) ?? DocumentPaths.provisionalID(relativePath), version: version, revision: json["contentRevision"] as? String ?? "", title: projectedTitle, language: localization?["preferredLanguage"] as? String, cover: try validateResource(topic["imageFileName"] as? String), covers: covers, children: ((json["hierarchy"] as? [String: Any])?["childOrder"] as? [String] ?? []).compactMap(UUID.init(uuidString:)), cards: cards, fingerprint: digest.finalize().map { String(format: "%02x", $0) }.joined(), resourceTables: legacyImages + (localization?["languages"] as? [String] ?? []).map { language in "locales/\(language)/\((localization?["tableFiles"] as? [String: String])?[language] ?? "strings.json")" })
    }
}
