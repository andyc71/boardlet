import SwiftUI

struct CommunicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @StateObject private var audio = AudioService()
    let board: Board
    let mediaURL: URL
    @State private var message: [MessageEntry] = []
    @State private var page = 0
    @State private var lastChoice: String?
    @State private var exitConfirmation = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical]) {
                        // Stable configured columns and pages. Overflow scrolls; cards never reflow on rotation.
                        let columns = max(1, board.communication.columns)
                        let available = max(0, geometry.size.width - 32 - CGFloat(columns - 1) * 12)
                        let width = max(typeSize.isAccessibilitySize ? 220 : 120, available / CGFloat(columns))
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(width), spacing: 12), count: columns), spacing: 12) {
                            ForEach(Array(board.cards.dropFirst(page * board.communication.capacity).prefix(board.communication.capacity))) { card in
                                Button { choose(card) } label: { CardTile(card: card, mediaURL: mediaURL, selected: false, labelsAbove: board.print.labelsAbove) }
                                    .buttonStyle(.plain).accessibilityIdentifier("speakCard-" + card.id.uuidString)
                            }
                        }.padding()
                    }
                }
                if board.cards.isEmpty { Text("This board has no cards yet.").padding() }
                if board.cards.count > board.communication.capacity {
                    HStack {
                        Button { page -= 1 } label: { Label("Previous page", systemImage: "chevron.left") }.disabled(page == 0)
                        Spacer()
                        Text("Page \(page + 1) of \(max(1, (board.cards.count + board.communication.capacity - 1) / board.communication.capacity))").font(.caption)
                        Spacer()
                        Button { page += 1 } label: { Label("Next page", systemImage: "chevron.right") }.disabled((page + 1) * board.communication.capacity >= board.cards.count)
                    }.padding().buttonStyle(.bordered)
                }
                if let lastChoice { Text(lastChoice).font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("lastChoice") }
                if let notice = audio.notice { Text(notice).font(.caption).foregroundStyle(.secondary).padding(.horizontal) }
                if board.communication.tap != .speak {
                    VStack(alignment: .leading) {
                        ScrollView(.horizontal) {
                            HStack {
                                if message.isEmpty { Text("Your message").foregroundStyle(.secondary) }
                                ForEach(message) { entry in Text(entry.card.label).padding(8).background(.quaternary, in: Capsule()) }
                            }.padding(.horizontal)
                        }.frame(minHeight: 44).accessibilityIdentifier("messageStrip")
                        ViewThatFits(in: .horizontal) {
                            HStack { MessageButtons(audio: audio, message: $message, settings: board.communication, mediaURL: mediaURL) }
                            VStack { MessageButtons(audio: audio, message: $message, settings: board.communication, mediaURL: mediaURL) }
                        }.padding(.horizontal).padding(.bottom)
                    }.background(.bar)
                }
            }.navigationTitle(board.name).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button { if board.communication.protectEditing { exitConfirmation = true } else { dismiss() } } label: { Label("Exit Use mode", systemImage: "xmark") }.accessibilityIdentifier("exitUse") }
                    ToolbarItem(placement: .topBarTrailing) { Button { audio.stop() } label: { Label("Stop speaking", systemImage: "stop.circle") }.disabled(!audio.playing) }
                }
                .confirmationDialog("Leave Use mode?", isPresented: $exitConfirmation, titleVisibility: .visible) { Button("Return to editing") { dismiss() }; Button("Keep using board", role: .cancel) { } }
        }.onDisappear { audio.close() }
    }
    func choose(_ card: Card) {
        if board.communication.tap != .speak { message.append(MessageEntry(card: card)) }
        if board.communication.tap != .message { audio.play([card], settings: board.communication, mediaURL: mediaURL) }
        lastChoice = card.label
    }
}

struct MessageButtons: View {
    @ObservedObject var audio: AudioService
    @Binding var message: [MessageEntry]
    let settings: CommunicationSettings
    let mediaURL: URL
    var body: some View {
        Button { audio.play(message.map(\.card), settings: settings, mediaURL: mediaURL) } label: { Label("Speak", systemImage: "speaker.wave.2.fill") }.buttonStyle(.borderedProminent).disabled(message.isEmpty)
        Button { if !message.isEmpty { message.removeLast() } } label: { Label("Remove last", systemImage: "delete.left") }.buttonStyle(.bordered).disabled(message.isEmpty)
        Button("Clear") { audio.stop(); message = [] }.buttonStyle(.bordered).disabled(message.isEmpty)
    }
}
