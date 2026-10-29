import SwiftUI

struct PhraseLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: PhraseLibrary
    @ObservedObject var session: CommunicationSession
    @ObservedObject var speech: SpeechController
    @State private var search = ""
    @State private var editing: SavedPhrase?
    @State private var deleting: SavedPhrase?
    @State private var error: String?
    @State private var reset = false

    private var filtered: [SavedPhrase] {
        library.phrases.filter { search.isEmpty || $0.title.localizedStandardContains(search) || $0.text.localizedStandardContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                if let failure = library.loadError {
                    Section {
                        Text(failure)
                        Button("Reset phrases", role: .destructive) { reset = true }
                    }
                } else {
                    Section {
                        Button("Save current message") { editing = SavedPhrase(title: "", text: session.message) }
                            .disabled(session.tokens.isEmpty).accessibilityIdentifier("saveCurrentPhrase")
                        Button("New phrase") { editing = SavedPhrase(title: "", text: "") }
                            .accessibilityIdentifier("newPhrase")
                        if library.recentlyDeleted != nil {
                            Button("Undo phrase deletion") { error = library.restoreDeleted() }
                        }
                    }
                    Section {
                        ForEach(filtered) { phrase in
                            HStack {
                                Button { session.append(phrase.text); dismiss() } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(phrase.title).font(.headline).lineLimit(2)
                                        if phrase.text != phrase.title { Text(phrase.text).font(.subheadline).foregroundStyle(.secondary).lineLimit(3) }
                                    }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel(phrase.title)
                                .accessibilityHint("Add phrase to your message")
                                .accessibilityIdentifier("phrase_\(phrase.id)")
                                Menu {
                                    Button("Speak now") { session.speakText(phrase.text) }
                                    Button("Edit phrase") { editing = phrase }
                                    Button("Delete phrase", role: .destructive) { deleting = phrase }
                                } label: { Label("Options for \(phrase.title)", systemImage: "ellipsis.circle").labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44) }
                                .accessibilityIdentifier("phraseOptions_\(phrase.id)")
                            }
                        }
                        .onMove { offsets, destination in error = library.move(from: offsets, to: destination) }
                        .moveDisabled(!search.isEmpty)
                        if filtered.isEmpty { Text(search.isEmpty ? "Save a phrase you use often." : "No matching phrases.").foregroundStyle(.secondary) }
                    } header: { Text("Tap to add") }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { SpeechStatusBar(speech: speech) }
            .onChange(of: editing != nil || deleting != nil || reset) { if $0 { speech.stop() } }
            .searchable(text: $search, prompt: "Search phrases")
            .navigationTitle("Phrases")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { EditButton().disabled(library.loadError != nil || !search.isEmpty) }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(item: $editing) { phrase in PhraseEditor(phrase: phrase, save: library.save) }
            .alert("Delete this phrase?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                Button("Delete", role: .destructive) {
                    if let deleting { error = library.delete(deleting) }
                    deleting = nil
                }
                Button("Cancel", role: .cancel) { deleting = nil }
            } message: { Text(deleting?.title ?? "") }
            .confirmationDialog("Reset unreadable phrases?", isPresented: $reset, titleVisibility: .visible) {
                Button("Reset phrases", role: .destructive) { library.resetUnreadableData() }
            } message: { Text("Start with the common phrases. A copy of the unreadable data will be kept on this device.") }
        }
    }
}
