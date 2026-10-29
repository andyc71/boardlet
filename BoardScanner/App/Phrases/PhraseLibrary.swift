import Combine
import Foundation

/// A small text-only collection, independent of the active board and conversation.
@MainActor
final class PhraseLibrary: ObservableObject {
    @Published private(set) var phrases: [SavedPhrase] = []
    @Published private(set) var loadError: String?
    @Published private(set) var recentlyDeleted: SavedPhrase?
    private let defaults: UserDefaults
    private static let key = "communication.phrases.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        guard let data = defaults.data(forKey: Self.key) else {
            phrases = SavedPhrase.starters
            if let encoded = try? JSONEncoder().encode(phrases) { defaults.set(encoded, forKey: Self.key) }
            return
        }
        do {
            guard data.count <= 1_000_000 else { throw CocoaError(.coderInvalidValue) }
            let decoded = try JSONDecoder().decode([SavedPhrase].self, from: data)
            try Self.validate(decoded)
            phrases = decoded
        } catch {
            loadError = "Saved phrases could not be read. Their stored data has been kept. You can reset phrases to start again."
        }
    }

    func save(_ phrase: SavedPhrase) -> String? {
        var value = phrase
        value.text = value.text.trimmingCharacters(in: .whitespacesAndNewlines)
        value.title = value.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.title.isEmpty { value.title = String(value.text.prefix(200)) }
        var updated = phrases
        if let index = updated.firstIndex(where: { $0.id == value.id }) { updated[index] = value }
        else { updated.append(value) }
        return persist(updated)
    }

    func delete(_ phrase: SavedPhrase) -> String? {
        guard phrases.contains(where: { $0.id == phrase.id }) else { return nil }
        let failure = persist(phrases.filter { $0.id != phrase.id })
        if failure == nil { recentlyDeleted = phrase }
        return failure
    }

    func restoreDeleted() -> String? {
        guard let phrase = recentlyDeleted else { return nil }
        let failure = save(phrase)
        if failure == nil { recentlyDeleted = nil }
        return failure
    }

    func move(from offsets: IndexSet, to destination: Int) -> String? {
        guard offsets.allSatisfy({ phrases.indices.contains($0) }), (0...phrases.count).contains(destination) else { return nil }
        let moving = offsets.sorted().map { phrases[$0] }
        var updated = phrases.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
        updated.insert(contentsOf: moving, at: destination - offsets.filter { $0 < destination }.count)
        return persist(updated)
    }

    func resetUnreadableData() {
        guard loadError != nil else { return }
        // Keep the unreadable payload for recovery; never silently overwrite it on launch.
        if let data = defaults.data(forKey: Self.key) { defaults.set(data, forKey: Self.key + ".recovery") }
        loadError = nil
        _ = persist(SavedPhrase.starters)
    }

    private func persist(_ updated: [SavedPhrase]) -> String? {
        guard loadError == nil else { return loadError }
        do {
            try Self.validate(updated)
            let data = try JSONEncoder().encode(updated)
            guard data.count <= 1_000_000 else { return "The phrase library is full. Shorten or remove a phrase before adding more." }
            defaults.set(data, forKey: Self.key)
            phrases = updated
            return nil
        } catch { return "Enter a message of up to 10,000 characters and a name of up to 200 characters. The library holds up to 500 phrases." }
    }

    private static func validate(_ values: [SavedPhrase]) throws {
        guard values.count <= 500, Set(values.map(\.id)).count == values.count,
              values.allSatisfy({ !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.text.count <= 10_000 && $0.title.count <= 200 }) else {
            throw CocoaError(.coderInvalidValue)
        }
    }
}
