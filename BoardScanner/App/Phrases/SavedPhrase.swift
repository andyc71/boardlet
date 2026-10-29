import Foundation

struct SavedPhrase: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var text: String

    static var starters: [Self] {
        ["Please give me time to respond.", "I use this device to communicate.",
         "I need help.", "Please say that again.", "I have something to say.", "Thank you."]
            .map { Self(title: $0, text: $0) }
    }
}
