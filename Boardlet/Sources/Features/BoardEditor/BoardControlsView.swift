import SwiftUI

struct BoardControlsView: View {
    @EnvironmentObject private var store: BoardStore
    let boardID: UUID
    let close: () -> Void
    @State private var coverPicker = false
    func binding<T>(_ path: WritableKeyPath<Board, T>, fallback: T) -> Binding<T> {
        Binding(get: { store.board(boardID)?[keyPath: path] ?? fallback }, set: { value in store.edit(boardID) { $0[keyPath: path] = value } })
    }
    var body: some View {
        Form {
            Section("Board") {
                TextField("Board name", text: binding(\.name, fallback: ""))
                Toggle("Pinned", isOn: binding(\.pinned, fallback: false))
                Button("Choose cover picture") { coverPicker = true }
                Button("Use card preview as cover") { store.edit(boardID) { $0.cover = nil; $0.coverAttribution = nil } }
            }
            Section("When a card is tapped") {
                Picker("Tap behaviour", selection: binding(\.communication.tap, fallback: .speak)) {
                    Text("Speak the card").tag(TapBehavior.speak)
                    Text("Add to message").tag(TapBehavior.message)
                    Text("Speak and add to message").tag(TapBehavior.both)
                }
                Toggle("Confirm before leaving Use mode", isOn: binding(\.communication.protectEditing, fallback: false))
            }
            Section("Communication layout") {
                Stepper("\(store.board(boardID)?.communication.columns ?? 2) across", value: binding(\.communication.columns, fallback: 2), in: 1...6)
                Stepper("\(store.board(boardID)?.communication.rows ?? 3) rows per page", value: binding(\.communication.rows, fallback: 3), in: 1...8)
                Text("Cards keep the same row, column and page during rotation. Small windows scroll instead of moving your choices.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Labels") { Toggle("Labels above pictures", isOn: binding(\.print.labelsAbove, fallback: false)) }
            Section("Voice") {
                VoiceSettingsView(language: binding(\.communication.language, fallback: "en-GB"), voiceID: binding(\.communication.voiceID, fallback: nil))
            }
        }.navigationTitle("Board controls").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done", action: close).accessibilityIdentifier("closeBoardControls") } }
            .sheet(isPresented: $coverPicker) { AddCardsView(single: true) { cards in if let card = cards.first { store.edit(boardID) { $0.cover = card.image; $0.coverAttribution = card.attribution } } } }
    }
}

struct BulkLabelsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    let boardID: UUID
    var body: some View {
        NavigationStack {
            Form {
                ForEach(store.board(boardID)?.cards ?? []) { card in
                    HStack {
                        CardArtwork(card: card, mediaURL: store.mediaURL).frame(width: 56, height: 56)
                        TextField("Label", text: Binding(get: { store.board(boardID)?.cards.first { $0.id == card.id }?.label ?? "" }, set: { text in store.edit(boardID) { board in if let index = board.cards.firstIndex(where: { $0.id == card.id }) { board.cards[index].label = text } } }))
                            .accessibilityLabel(L("Label") + " " + card.label)
                    }
                }
            }.navigationTitle("Edit all labels").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct CopyCardsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    let source: UUID
    let selection: Set<UUID>
    var body: some View {
        NavigationStack {
            List(store.boards.filter { $0.id != source }) { board in
                Button(board.name) { store.copyCards(selection, from: source, to: board.id); dismiss() }
            }.navigationTitle("Copy to another board").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
