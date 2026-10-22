import Foundation

/// Text-only board context. No photos or board data are sent to a model server.
public struct ARASAACSuggestionContext: Hashable, Sendable {
    public let boardName: String
    public let cardLabels: [String]

    public init(boardName: String, cardLabels: [String]) {
        self.boardName = boardName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cardLabels = Array(Set(cardLabels.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty })).sorted()
    }

    var hasContent: Bool { !boardName.isEmpty || !cardLabels.isEmpty }

    static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Bound prompt size even when a board has many long labels.
    var promptData: String {
        let data = ["board": String(boardName.prefix(160)),
                    "cards": cardLabels.prefix(48).map { String($0.prefix(60)) }.joined(separator: ", ")]
        guard let json = try? JSONEncoder().encode(data), let text = String(data: json, encoding: .utf8) else { return "{}" }
        return text
    }

    func candidates(from generated: [String]) -> [String] {
        var seen = Set(cardLabels.map(Self.normalized))
        return generated.prefix(12).compactMap { term in
            let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty, cleaned.count <= 60,
                  !cleaned.contains(where: { $0.isNewline }),
                  cleaned.split(whereSeparator: \.isWhitespace).count <= 4,
                  seen.insert(Self.normalized(cleaned)).inserted else { return nil }
            return cleaned
        }
    }
}
