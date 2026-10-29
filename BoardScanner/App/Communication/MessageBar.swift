import SwiftUI

struct MessageBar: View {
  @ObservedObject var session: CommunicationSession
  @ObservedObject var speech: SpeechController
  @ObservedObject var phrases: PhraseLibrary
  @ObservedObject var access: AccessController
  var cardSize = CGSize(width: 64, height: 64)
  var gridColumns: Int? = nil
  var availableWidth: CGFloat? = nil
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var showPhrases = false
  @State private var showEditing = false
  @State private var typedMessage = ""
  @State private var viewportWidth: CGFloat = 320
  @State private var wordsWidth: CGFloat = 0

  private var compactScale: CGFloat { verticalSizeClass == .compact ? 2.0 / 3 : 1 }
  private var actionWidth: CGFloat { cardSize.width * compactScale }
  private var stripHeight: CGFloat { cardSize.height * compactScale }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Color.clear
        .frame(height: stripHeight)
        .onGeometryChange(for: CGFloat.self) { $0.size.width + 8 } action: { viewportWidth = $0 }
        .overlay(alignment: .leading) {
        HStack(spacing: 8) {
          speechCard
          messageRow
            .frame(width: messageWidth, height: stripHeight)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(.secondary.opacity(0.4)) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Message")
            .accessibilityValue(session.message.isEmpty ? "Empty" : session.message)
            .accessibilityIdentifier("communicationMessage")
          actions
        }
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
      .frame(height: stripHeight)
      if let error = speech.error { Text(error).font(.caption).foregroundStyle(.red) }
    }
    .buttonStyle(.plain)
    .foregroundStyle(.primary)
    .padding(.horizontal, 4).padding(.vertical, 4).background(.thinMaterial)
    .frame(maxWidth: .infinity, alignment: .leading)
    .onChange(of: showPhrases || showEditing || session.showKeyboard) {
      access.suspend("composer", while: $0)
      if $0 { speech.stop() }
    }
    .onDisappear { access.suspend("composer", while: false) }
    .sheet(isPresented: $showPhrases) {
      PhraseLibraryView(library: phrases, session: session, speech: speech)
    }
    .sheet(isPresented: $showEditing) { MessageEditor(session: session, speech: speech) }
    .sheet(isPresented: $session.showKeyboard) {
      NavigationStack {
        Form {
          TextField("Your message", text: $typedMessage, axis: .vertical)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2...3 : 3...8)
            .accessibilityIdentifier("typedMessage")
        }
        .navigationTitle("Type a message")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { session.showKeyboard = false }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Add") {
              session.append(typedMessage)
              typedMessage = ""
              session.showKeyboard = false
            }
            .disabled(
              typedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
        }
      }
    }
  }

  private var messageRow: some View {
    HStack {
      ScrollViewReader { proxy in
        ScrollView(wordsWidth > messageWidth + 0.5 ? .horizontal : []) {
          HStack(spacing: 8) {
            ForEach(session.tokens) { token in
              HStack {
                Text(token.text).font(.headline).lineLimit(1)
              }
              .padding(4).background(
                .background, in: RoundedRectangle(cornerRadius: 10)
              )
              .id(token.id)
            }
          }
          .fixedSize(horizontal: true, vertical: false)
          .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { wordsWidth = $0 }
        }
        .frame(width: messageWidth, height: stripHeight)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .onChange(of: session.tokens.count) { _ in
          if let last = session.tokens.last { proxy.scrollTo(last.id, anchor: .trailing) }
        }
      }

    }
  }

  private var messageWidth: CGFloat {
    if let availableWidth {
      return max(1, availableWidth - 3 * actionWidth - 32)
    }
    return max(1, viewportWidth - 3 * actionWidth - 32)
  }

  private func actionLabel(_ title: String, symbol: String) -> some View {
    VStack(spacing: 3 * compactScale) {
      Image(systemName: symbol).resizable().scaledToFit()
        .frame(maxWidth: max(6, stripHeight * 0.62),
               maxHeight: max(6, stripHeight * 0.62))
        .accessibilityHidden(true)
      Text(title).font(cardSize.height < 90 ? .caption : .body)
        .lineLimit(1).minimumScaleFactor(0.5)
        .layoutPriority(1)
    }
    .padding(4 * compactScale)
    .frame(width: actionWidth, height: stripHeight)
    .foregroundStyle(.white)
    .background(.black, in: RoundedRectangle(cornerRadius: 8))
  }

  private var speechCard: some View {
    Button {
      access.stop()
      if speech.isSpeaking { speech.stop() } else { session.speak() }
    } label: {
      actionLabel(speech.isSpeaking ? "Stop" : "Speak",
                  symbol: speech.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
    }
    .disabled(!speech.isSpeaking && (session.tokens.isEmpty || !access.available))
    .accessibilityLabel(speech.isSpeaking ? "Stop speaking" : "Speak message")
    .accessibilityIdentifier(speech.isSpeaking ? "stopSpeech" : "speakMessage")
    .keyboardShortcut(speech.isSpeaking ? "." : "s", modifiers: .command)
  }

  @ViewBuilder private var actions: some View {
    Button {
      access.stop()
      session.undo()
    } label: {
      actionLabel("Delete", symbol: "delete.left")
    }
    .disabled(session.tokens.isEmpty || !access.available)
    .accessibilityLabel("Undo last word")
    .accessibilityInputLabels(["Delete", "Undo", "Undo last word"])
    .accessibilityIdentifier("undoMessage")
    Button {
      access.stop()
      session.clear()
    } label: {
      actionLabel("Clear", symbol: "xmark.circle")
    }
    .disabled(session.tokens.isEmpty || !access.available)
    .accessibilityLabel("Clear message")
    .accessibilityInputLabels(["Clear", "Clear message"])
    .accessibilityIdentifier("clearMessage")
  }
}
