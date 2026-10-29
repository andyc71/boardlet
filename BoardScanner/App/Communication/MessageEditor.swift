import SwiftUI

struct MessageEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var session: CommunicationSession
    @ObservedObject var speech: SpeechController
    @State private var editMode = EditMode.inactive
    @State private var editing: CommunicationToken?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(session.tokens) { token in
                        Button { editing = token } label: {
                            HStack {
                                if let data = token.imagePNG, let image = UIImage(data: data) {
                                    ArtworkImage(image: image).frame(width: 44, height: 44).accessibilityHidden(true)
                                }
                                Text(token.text).lineLimit(3).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                        }
                        .accessibilityIdentifier("messageToken_\(token.id)")
                        .accessibilityHint("Edit these words")
                        .accessibilityAction(named: "Move earlier") { session.moveToken(token.id, earlier: true) }
                        .accessibilityAction(named: "Move later") { session.moveToken(token.id, earlier: false) }
                    }
                    .onDelete(perform: session.removeTokens)
                    .onMove(perform: session.moveTokens)
                    if session.tokens.isEmpty { Text("Your message is empty.").foregroundStyle(.secondary) }
                } header: { Text(editMode.isEditing ? "Drag to reorder or remove words" : "Tap words to edit") }
                if !session.lastMessage.isEmpty {
                    Section("Last spoken or cleared message") {
                        Text(session.lastMessageText)
                        Button("Add last message", action: session.reuseLastMessage)
                            .accessibilityIdentifier("reuseLastMessage")
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { SpeechStatusBar(speech: speech) }
            .onChange(of: editing?.id) { if $0 != nil { speech.stop() } }
            .environment(\.editMode, $editMode)
            .navigationTitle("Edit message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(editMode.isEditing ? "Finish organizing" : "Organize") {
                        editMode = editMode.isEditing ? .inactive : .active
                    }.disabled(session.tokens.isEmpty && !editMode.isEditing)
                }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(item: $editing) { token in MessageTokenEditor(token: token, save: session.updateToken) }
        }
    }
}
