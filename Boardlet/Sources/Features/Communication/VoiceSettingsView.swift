import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @Binding var language: String
    @Binding var voiceID: String?
    @State private var voiceRefresh = UUID()
    var body: some View {
        Picker("Language", selection: $language) {
            Text("English (UK)").tag("en-GB"); Text("English (US)").tag("en-US"); Text("Español (España)").tag("es-ES"); Text("Español (México)").tag("es-MX")
        }
        Picker("Voice", selection: $voiceID) {
            Text("System voice").tag(String?.none)
            ForEach(AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }, id: \.identifier) { voice in
                Text(voice.name + (voice.quality == .enhanced ? " · " + L("Enhanced") : voice.quality == .premium ? " · " + L("Premium") : "")).tag(Optional(voice.identifier))
            }
        }.id(voiceRefresh)
        if #available(iOS 17, *) {
            Button("Allow Personal Voice") {
                AVSpeechSynthesizer.requestPersonalVoiceAuthorization { _ in Task { @MainActor in voiceRefresh = UUID() } }
            }
        }
        Text("Download additional voices in Settings → Accessibility → Spoken Content. If a voice is unavailable, Boardlet uses the system voice for the chosen language.").font(.footnote).foregroundStyle(.secondary)
    }
}
