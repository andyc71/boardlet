import Foundation

struct BuiltinSymbol: Identifiable, Sendable {
    let label: String
    let name: String
    var id: String { name }

    static let choices: [Self] = [
        .init(label: "Yes", name: "checkmark.circle.fill"), .init(label: "No", name: "xmark.circle.fill"),
        .init(label: "I want", name: "hand.point.up.left.fill"), .init(label: "More", name: "plus.circle.fill"),
        .init(label: "Help", name: "hand.raised.fill"), .init(label: "Stop", name: "stop.circle.fill"),
        .init(label: "Water", name: "drop.fill"), .init(label: "Eat", name: "fork.knife"),
        .init(label: "Toilet", name: "toilet.fill"), .init(label: "Home", name: "house.fill"),
        .init(label: "People", name: "person.2.fill"), .init(label: "Happy", name: "face.smiling.fill"),
        .init(label: "Love", name: "heart.fill"), .init(label: "Sleep", name: "bed.double.fill"),
        .init(label: "Play", name: "figure.play"), .init(label: "Book", name: "book.fill"),
        .init(label: "Music", name: "music.note"), .init(label: "Outside", name: "sun.max.fill"),
        .init(label: "Go", name: "arrow.right.circle.fill"), .init(label: "Wait", name: "clock.fill"),
        .init(label: "Speak", name: "speaker.wave.2.fill"), .init(label: "Back", name: "arrow.uturn.backward.circle.fill"),
        .init(label: "Type", name: "keyboard"), .init(label: "Clear", name: "xmark.bin.fill")
    ]
}
