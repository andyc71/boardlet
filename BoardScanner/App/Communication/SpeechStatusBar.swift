import SwiftUI

/// Keeps speech cancellation reachable in sheets that can initiate an utterance.
struct SpeechStatusBar: View {
  @Environment(\.colorScheme) private var colorScheme
  @ObservedObject var speech: SpeechController

  var body: some View {
    if speech.isSpeaking || speech.error != nil {
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 12) {
          status.fixedSize()
          Spacer(minLength: 0)
          if speech.isSpeaking { stopButton(compact: false).fixedSize() }
        }
        VStack(alignment: .leading, spacing: 8) {
          status.fixedSize(horizontal: false, vertical: true)
          if speech.isSpeaking { stopButton(compact: true) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 12).padding(.vertical, 8)
      .background(.thinMaterial)
    }
  }

  @ViewBuilder private var status: some View {
    if let error = speech.error {
      Text(error).font(.callout).foregroundStyle(.red)
        .accessibilityIdentifier("speechError")
    } else {
      Label("Speaking", systemImage: "waveform")
        .accessibilityIdentifier("speechStatus")
    }
  }

  private func stopButton(compact: Bool) -> some View {
    Button(action: speech.stop) {
      Label(compact ? "Stop" : "Stop speaking", systemImage: "stop.fill")
        .frame(maxWidth: compact ? .infinity : nil, minHeight: 44)
    }
    .buttonStyle(.borderedProminent)
    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
    .keyboardShortcut(".", modifiers: .command)
    .accessibilityLabel("Stop speaking")
    .accessibilityIdentifier("stopModalSpeech")
  }
}
