import SwiftUI

struct CardDetailsView: View {
    @EnvironmentObject private var store: BoardStore
    @StateObject private var audio = AudioService()
    let boardID: UUID
    let cardID: UUID
    @State private var replace = false
    @State private var crop = false
    @State private var processing = false
    @State private var error: String?
    private var card: Card? { store.board(boardID)?.cards.first { $0.id == cardID } }
    func change(_ action: (inout Card) -> Void) {
        store.edit(boardID) { board in if let index = board.cards.firstIndex(where: { $0.id == cardID }) { action(&board.cards[index]) } }
    }
    func binding<T>(_ path: WritableKeyPath<Card, T>, fallback: T) -> Binding<T> {
        Binding(get: { card?[keyPath: path] ?? fallback }, set: { value in change { $0[keyPath: path] = value } })
    }
    var body: some View {
        Form {
            if let card {
                Section {
                    CardArtwork(card: card, mediaURL: store.mediaURL).frame(maxWidth: .infinity).frame(height: 230)
                    Button("Replace picture") { replace = true }
                    if card.image != nil {
                        Button("Crop picture") { crop = true }
                        if #available(iOS 17, *) { Button("Remove background") { Task { await removeBackground() } }.disabled(processing) }
                        Button("Restore original picture") { change { $0.image = $0.originalImage; $0.attribution = $0.originalAttribution ?? $0.attribution } }.disabled(card.originalImage == nil || card.image == card.originalImage)
                    }
                    if processing { ProgressView("Editing picture…") }
                }
                Section("Label") { TextField("Label", text: binding(\.label, fallback: ""), axis: .vertical).accessibilityIdentifier("cardLabel") }
                Section("Card voice") {
                    Picker("Voice source", selection: binding(\.voice, fallback: .speech)) { Text("Speak the label").tag(VoiceSource.speech); Text("Play a recording").tag(VoiceSource.recording); Text("Silent").tag(VoiceSource.silent) }
                    Text("Tap behaviour is set for the whole board in Board controls.").font(.footnote).foregroundStyle(.secondary)
                    if let board = store.board(boardID) {
                        Button("Preview voice") { audio.play([card], settings: board.communication, mediaURL: store.mediaURL) }.disabled(audio.recording)
                        VoiceSettingsView(language: Binding(get: { card.language ?? board.communication.language }, set: { value in change { $0.language = value } }), voiceID: binding(\.voiceID, fallback: nil))
                    }
                    if audio.recording {
                        Label("Recording…", systemImage: "record.circle").foregroundStyle(.red)
                        Button("Save recording") { Task { await saveRecording() } }
                        Button("Cancel recording", role: .cancel) { audio.cancelRecording() }
                    } else {
                        Button(card.recording == nil ? "Record voice" : "Replace recording") { Task { await audio.startRecording() } }
                    }
                    if card.recording != nil { Button("Remove recording", role: .destructive) { change { $0.recording = nil; $0.voice = .speech } } }
                    if let notice = audio.notice { Text(notice).foregroundStyle(.secondary) }
                }
                Section {
                    Button("Duplicate card") { store.edit(boardID) { $0.cards.append(card.duplicate()) } }
                    Button("Use as board cover") { store.edit(boardID) { $0.cover = card.image; $0.coverAttribution = card.attribution } }
                }
                if let attribution = card.attribution { Section("Source credits") { Text(attribution.exportCredit).font(.footnote) } }
                if let error { Section { Text(error).foregroundStyle(.red) } }
            }
        }.navigationTitle("Edit card")
            .sheet(isPresented: $replace) { AddCardsView(single: true) { cards in
                guard let replacement = cards.first else { return }
                change { $0.image = replacement.image; $0.originalImage = replacement.originalImage; $0.attribution = replacement.attribution; $0.originalAttribution = replacement.attribution; $0.systemSymbol = replacement.systemSymbol }
            } }
            .sheet(isPresented: $crop) { if let url = store.assetURL(card?.image), let data = try? Data(contentsOf: url) { CropView(data: data) { result in Task { await applyImage(result) } } } }
            .onDisappear { audio.close() }
    }
    func applyImage(_ data: Data) async {
        do { let name = try await store.storage.storeAsset(data, extension: "png"); change { $0.image = name; $0.attribution?.modified = true } }
        catch { self.error = error.localizedDescription }
    }
    @available(iOS 17, *) func removeBackground() async {
        guard let url = store.assetURL(card?.image) else { return }
        processing = true; defer { processing = false }
        do { let data = try Data(contentsOf: url); let result = try await ImageEditor().removeBackground(data); await applyImage(result) }
        catch { self.error = error.localizedDescription }
    }
    func saveRecording() async {
        do { if let data = try audio.finishRecording() { let name = try await store.storage.storeAsset(data, extension: "m4a"); change { $0.recording = name; $0.voice = .recording } } }
        catch { self.error = error.localizedDescription }
    }
}
