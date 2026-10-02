import Foundation

struct CommunicationSettings: Codable, Equatable, Sendable {
    var tap: TapBehavior = .speak
    var columns = 2
    var rows = 3
    var language = "en-GB"
    var voiceID: String?
    var protectEditing = false
    var capacity: Int { max(1, columns) * max(1, rows) }
}

enum TapBehavior: String, Codable, CaseIterable, Sendable {
    case speak, message, both
}

/// Message entries have their own identities so repetitions never collapse.
struct MessageEntry: Identifiable, Equatable {
    let id = UUID()
    let card: Card
}
