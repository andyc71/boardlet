import Foundation

struct Board: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var cards: [Card] = []
    var pinned = false
    var deletedAt: Date?
    var modifiedAt = Date()
    var cover: String?
    var coverAttribution: Attribution?
    var print = PrintSettings()
    var communication = CommunicationSettings()
    var legacySource: String?
    /// Exact source JSON retained for fidelity and future migration refinements.
    var legacyMetadata: Data?

    func duplicate() -> Board {
        var copy = self
        copy.id = UUID()
        copy.cards = cards.map { $0.duplicate() }
        copy.legacySource = nil
        copy.deletedAt = nil
        copy.pinned = false
        copy.modifiedAt = Date()
        return copy
    }
}
