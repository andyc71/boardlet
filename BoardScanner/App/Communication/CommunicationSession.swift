import Combine
import Foundation

@MainActor
final class CommunicationSession: ObservableObject {
    @Published private(set) var tokens: [CommunicationToken] = []
    @Published private(set) var lastMessage: [CommunicationToken] = []
    @Published var showKeyboard = false
    @Published var settings: CommunicationSettings {
        didSet {
            if let data = try? JSONEncoder().encode(settings.validated) {
                defaults.set(data, forKey: Self.settingsKey)
            }
        }
    }
    private let speaker: any SpeechOutput
    private let defaults: UserDefaults
    private static let settingsKey = "communication.settings.v1"

    init(speaker: any SpeechOutput, defaults: UserDefaults = .standard) {
        self.speaker = speaker
        self.defaults = defaults
        settings = defaults.data(forKey: Self.settingsKey)
            .flatMap { try? JSONDecoder().decode(CommunicationSettings.self, from: $0) }?.validated
            ?? CommunicationSettings()
    }

    var message: String { Self.text(for: tokens) }

    private static func text(for tokens: [CommunicationToken]) -> String {
        tokens.reduce(into: "") { result, token in
            let punctuation = token.text.first.map { ".,!?;:)]}".contains($0) } ?? false
            if !result.isEmpty && !punctuation { result += " " }
            result += token.text
        }
    }

    func append(_ text: String, imagePNG: Data? = nil) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        tokens.append(CommunicationToken(text: cleaned, imagePNG: imagePNG))
        if settings.speakOnSelection { speaker.speak(cleaned, settings: settings) }
    }

    func select(_ card: ScannedCard) {
        guard card.included, card.isEmpty != true else { return }
        let message = card.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        append(message.isEmpty ? card.label : message, imagePNG: card.imagePNG)
    }

    func select(_ button: SnapButton, in pageSet: SnapPageSet) {
        guard case .action(let action) = SnapCommunicationBehavior.resolve(button) else { return }
        let raw = button.message.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = raw.isEmpty ? button.label : raw
        switch action {
        case .addMessage:
            append(text, imagePNG: button.assetKey.flatMap { pageSet.assets[$0]?.previewPNG })
        case .speakImmediately: speakText(text)
        case .speakMessage: speak()
        case .clearMessage: clear()
        case .undo: undo()
        case .stop: speaker.stop()
        case .keyboard: showKeyboard = true
        case .automatic, .openPage, .home, .back, .none: break
        }
    }

    func stopSpeaking() { speaker.stop() }

    func speak() {
        guard !tokens.isEmpty else { return }
        if speaker.speak(message, settings: settings) {
            lastMessage = tokens
            if settings.clearAfterSpeaking { tokens.removeAll() }
        }
    }

    func undo() {
        guard !tokens.isEmpty else { return }
        speaker.stop()
        tokens.removeLast()
    }

    func clear() {
        speaker.stop()
        if !tokens.isEmpty { lastMessage = tokens }
        tokens.removeAll()
    }

    func resetConversation() {
        speaker.stop()
        tokens.removeAll()
        lastMessage.removeAll()
        showKeyboard = false
    }

    func speakText(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        if speaker.speak(cleaned, settings: settings) {
            lastMessage = [CommunicationToken(text: cleaned, imagePNG: nil)]
        }
    }

    func reuseLastMessage() {
        guard !lastMessage.isEmpty else { return }
        let reused = lastMessage.map { CommunicationToken(text: $0.text, imagePNG: $0.imagePNG) }
        tokens.append(contentsOf: reused)
        if settings.speakOnSelection { speaker.speak(Self.text(for: reused), settings: settings) }
    }

    var lastMessageText: String { Self.text(for: lastMessage) }

    func updateToken(_ id: UUID, text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let index = tokens.firstIndex(where: { $0.id == id }) else { return }
        speaker.stop()
        tokens[index].text = cleaned
    }

    func removeTokens(at offsets: IndexSet) {
        speaker.stop()
        tokens = tokens.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
    }

    func moveTokens(from offsets: IndexSet, to destination: Int) {
        guard offsets.allSatisfy({ tokens.indices.contains($0) }), (0...tokens.count).contains(destination) else { return }
        speaker.stop()
        let moving = offsets.sorted().map { tokens[$0] }
        var updated = tokens.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
        updated.insert(contentsOf: moving, at: destination - offsets.filter { $0 < destination }.count)
        tokens = updated
    }

    func moveToken(_ id: UUID, earlier: Bool) {
        guard let index = tokens.firstIndex(where: { $0.id == id }) else { return }
        let target = earlier ? index - 1 : index + 1
        guard tokens.indices.contains(target) else { return }
        moveTokens(from: IndexSet(integer: index), to: earlier ? target : target + 1)
    }
}
