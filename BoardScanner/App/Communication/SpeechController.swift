import AVFoundation
import Combine

@MainActor
final class SpeechController: NSObject, ObservableObject, SpeechOutput, AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeaking = false
    @Published private(set) var error: String?
    private var synthesizer = AVSpeechSynthesizer()
    private var current: ObjectIdentifier?

    override init() {
        super.init()
        configureSynthesizer()
    }

    private func configureSynthesizer() {
        synthesizer.delegate = self
        // The system manages activation and ducking without blocking the UI on setActive.
        synthesizer.usesApplicationAudioSession = false
    }

    var voices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().sorted {
            ($0.language, $0.name, $0.identifier) < ($1.language, $1.name, $1.identifier)
        }
    }

    @discardableResult
    func speak(_ text: String, settings: CommunicationSettings) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        stop()
        error = nil
        guard let voice = AVSpeechSynthesisVoice(identifier: settings.voiceIdentifier)
            ?? AVSpeechSynthesisVoice(language: settings.voiceLocale.flatMap { $0.isEmpty ? nil : $0 } ?? Locale.preferredLanguages.first ?? "en-US")
            ?? AVSpeechSynthesisVoice.speechVoices().first else {
            error = "No speech voice is available. Install a voice in device Settings and try again."
            return false
        }
        let utterance = AVSpeechUtterance(attributedString: Self.speechText(text, language: voice.language))
        utterance.voice = voice
        utterance.rate = settings.validated.rate
        current = ObjectIdentifier(utterance)
        isSpeaking = true
        synthesizer.speak(utterance)
        return true
    }

    static func speechText(_ text: String, language: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text)
        // An isolated English pronoun can otherwise be expanded to "capital I".
        // Keep the original text for composition and leave sentence prosody to the voice.
        let languageCode = language.split(whereSeparator: { $0 == "-" || $0 == "_" }).first
        if languageCode?.lowercased() == "en",
           text.trimmingCharacters(in: .whitespacesAndNewlines) == "I" {
            result.addAttribute(NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute),
                                value: "aɪ", range: (text as NSString).range(of: "I"))
        }
        return result
    }

    func stop() {
        let hadRequest = current != nil
        current = nil
        if hadRequest && !synthesizer.stopSpeaking(at: .immediate) {
            // A request can still be preparing when Stop arrives. If the engine
            // cannot cancel it, discard that queue before accepting another one.
            synthesizer.delegate = nil
            synthesizer = AVSpeechSynthesizer()
            configureSynthesizer()
        }
        isSpeaking = false
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finished(ObjectIdentifier(utterance))
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finished(ObjectIdentifier(utterance))
    }

    private nonisolated func finished(_ identifier: ObjectIdentifier) {
        Task { @MainActor [weak self] in
            guard let self, self.current == identifier else { return }
            self.current = nil
            self.isSpeaking = false
        }
    }
}
