import Foundation

struct Card: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var label: String
    var image: String?
    var originalImage: String?
    var recording: String?
    var voice: VoiceSource = .speech
    var language: String?
    var voiceID: String?
    var attribution: Attribution?
    var originalAttribution: Attribution?
    var category = "none"
    var systemSymbol: String?

    func duplicate() -> Card {
        var copy = self
        copy.id = UUID()
        return copy
    }
}

enum VoiceSource: String, Codable, CaseIterable, Sendable {
    case speech, recording, silent
}
