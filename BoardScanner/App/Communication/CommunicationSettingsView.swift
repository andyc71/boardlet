import SwiftUI
import AVFoundation
import VoicePickerUI

struct CommunicationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var session: CommunicationSession
    @ObservedObject var speech: SpeechController

    @ObservedObject var access: AccessController

    @State private var showVoicePicker = false

    var body: some View {
        NavigationStack {
            Form {
                AccessSettingsSection(access: access)
                Section("Speaking") {
                    Toggle("Speak each selection", isOn: $session.settings.speakOnSelection)
                    Toggle("Clear message after Speak", isOn: $session.settings.clearAfterSpeaking)
                    Button("Change Voice") { speech.stop(); showVoicePicker = true }
                    if !session.settings.voiceIdentifier.isEmpty,
                        !speech.voices.contains(where: {
                            $0.identifier == session.settings.voiceIdentifier
                        })
                    {
                        Text("Your selected voice is unavailable. The system voice will be used.")
                            .font(
                                .footnote)
                    }
                    VStack(alignment: .leading) {
                        Text("Speaking speed")
                        Slider(value: $session.settings.rate, in: 0.25...0.65, step: 0.05) {
                            Text("Speaking speed")
                        } minimumValueLabel: {
                            Text("Slower")
                        } maximumValueLabel: {
                            Text("Faster")
                        }
                    }
                    Button("Test voice") {
                        speech.speak("This is my voice.", settings: session.settings)
                    }
                }
                Section {
                    Text(
                        "Voices are supplied by your device. Add voices in your device’s accessibility speech settings. Voice availability and offline support depend on the installed voice."
                    )
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { SpeechStatusBar(speech: speech) }
            .sheet(isPresented: $showVoicePicker) {
                VoicePicker(voiceIdentifier: $session.settings.voiceIdentifier,
                            voiceLocale: Binding(get: { session.settings.voiceLocale ?? "" },
                                                 set: { session.settings.voiceLocale = $0 }),
                            defaultVoice: { AVSpeechSynthesisVoice(language: $0) },
                            preview: { voice in
                                var settings = session.settings
                                settings.voiceIdentifier = voice.identifier
                                speech.speak("1, 2, 3.", settings: settings)
                            }, stopPreview: { speech.stop() })
            }
            .navigationTitle("Communication")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
