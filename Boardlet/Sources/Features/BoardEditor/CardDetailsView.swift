import SwiftUI

struct CardDetailsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
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
        Group {
            if let card {
                GeometryReader { geometry in
                    if usesTwoColumnLayout(in: geometry.size) {
                        let spacing: CGFloat = 16
                        let availableWidth = geometry.size.width - spacing
                        HStack(spacing: spacing) {
                            Form {
                                CardImageEditor(
                                    card: card,
                                    mediaURL: store.mediaURL,
                                    previewHeight: landscapePreviewHeight(for: geometry.size.height),
                                    onReplace: { replace = true }
                                )
                            }
                            .scrollDisabled(true)
                            .frame(width: availableWidth * 0.4)

                            Form {
                                CardTitleEditor(text: binding(\.label, fallback: ""))
                                CardPhotoActions(
                                    card: card,
                                    processing: processing,
                                    onCrop: { crop = true },
                                    onRemoveBackground: { Task { await removeBackgroundIfAvailable() } },
                                    onRestoreOriginal: restoreOriginal
                                )
                                CardRemainingSections(
                                    card: card,
                                    board: store.board(boardID),
                                    mediaURL: store.mediaURL,
                                    audio: audio,
                                    voice: binding(\.voice, fallback: .speech),
                                    language: Binding(get: { card.language ?? store.board(boardID)?.communication.language ?? "en" }, set: { value in change { $0.language = value } }),
                                    voiceID: binding(\.voiceID, fallback: nil),
                                    error: error,
                                    onSaveRecording: { Task { await saveRecording() } },
                                    onStartRecording: { Task { await audio.startRecording() } },
                                    onRemoveRecording: { change { $0.recording = nil; $0.voice = .speech } },
                                    onDuplicate: { store.edit(boardID) { $0.cards.append(card.duplicate()) } },
                                    onUseAsCover: { store.edit(boardID) { $0.cover = card.image; $0.coverAttribution = card.attribution } }
                                )
                            }
                            .frame(width: availableWidth * 0.6)
                        }
                        .background(Color(uiColor: .systemGroupedBackground))
                    } else {
                        Form {
                            CardImageEditor(
                                card: card,
                                mediaURL: store.mediaURL,
                                previewHeight: 230,
                                onReplace: { replace = true },
                                photoActions: {
                                    CardPhotoActionRows(
                                        card: card,
                                        processing: processing,
                                        onCrop: { crop = true },
                                        onRemoveBackground: { Task { await removeBackgroundIfAvailable() } },
                                        onRestoreOriginal: restoreOriginal
                                    )
                                }
                            )
                            CardTitleEditor(text: binding(\.label, fallback: ""))
                            CardRemainingSections(
                                card: card,
                                board: store.board(boardID),
                                mediaURL: store.mediaURL,
                                audio: audio,
                                voice: binding(\.voice, fallback: .speech),
                                language: Binding(get: { card.language ?? store.board(boardID)?.communication.language ?? "en" }, set: { value in change { $0.language = value } }),
                                voiceID: binding(\.voiceID, fallback: nil),
                                error: error,
                                onSaveRecording: { Task { await saveRecording() } },
                                onStartRecording: { Task { await audio.startRecording() } },
                                onRemoveRecording: { change { $0.recording = nil; $0.voice = .speech } },
                                onDuplicate: { store.edit(boardID) { $0.cards.append(card.duplicate()) } },
                                onUseAsCover: { store.edit(boardID) { $0.cover = card.image; $0.coverAttribution = card.attribution } }
                            )
                        }
                    }
                }
            }
        }
            .navigationTitle("Edit card")
            .sheet(isPresented: $replace) { AddCardsView(single: true) { cards in
                guard let replacement = cards.first else { return }
                change { $0.image = replacement.image; $0.originalImage = replacement.originalImage; $0.attribution = replacement.attribution; $0.originalAttribution = replacement.attribution; $0.systemSymbol = replacement.systemSymbol }
            } }
            .sheet(isPresented: $crop) { if let url = store.assetURL(card?.image), let data = try? Data(contentsOf: url) { CropView(data: data) { result in Task { await applyImage(result) } } } }
            .onDisappear { audio.close() }
    }
    private func usesTwoColumnLayout(in size: CGSize) -> Bool {
        verticalSizeClass == .compact && size.width >= 720 && size.width > size.height && !typeSize.isAccessibilitySize
    }
    private func landscapePreviewHeight(for availableHeight: CGFloat) -> CGFloat {
        min(320, max(200, availableHeight - 88))
    }
    private func restoreOriginal() {
        change { $0.image = $0.originalImage; $0.attribution = $0.originalAttribution ?? $0.attribution }
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
    private func removeBackgroundIfAvailable() async {
        if #available(iOS 17, *) { await removeBackground() }
    }
    func saveRecording() async {
        do { if let data = try audio.finishRecording() { let name = try await store.storage.storeAsset(data, extension: "m4a"); change { $0.recording = name; $0.voice = .recording } } }
        catch { self.error = error.localizedDescription }
    }
}

private struct CardImageEditor<PhotoActions: View>: View {
    let card: Card
    let mediaURL: URL
    let previewHeight: CGFloat
    let onReplace: () -> Void
    let photoActions: PhotoActions

    init(
        card: Card,
        mediaURL: URL,
        previewHeight: CGFloat,
        onReplace: @escaping () -> Void,
        @ViewBuilder photoActions: () -> PhotoActions
    ) {
        self.card = card
        self.mediaURL = mediaURL
        self.previewHeight = previewHeight
        self.onReplace = onReplace
        self.photoActions = photoActions()
    }

    var body: some View {
        Section {
            CardArtwork(card: card, mediaURL: mediaURL)
                .frame(maxWidth: .infinity)
                .frame(height: previewHeight)
            Button("Replace picture", action: onReplace)
            photoActions
        }
    }
}

private extension CardImageEditor where PhotoActions == EmptyView {
    init(card: Card, mediaURL: URL, previewHeight: CGFloat, onReplace: @escaping () -> Void) {
        self.init(card: card, mediaURL: mediaURL, previewHeight: previewHeight, onReplace: onReplace) { EmptyView() }
    }
}

private struct CardTitleEditor: View {
    let text: Binding<String>

    var body: some View {
        Section("Label") {
            TextField("Label", text: text, axis: .vertical)
                .accessibilityIdentifier("cardLabel")
        }
    }
}

private struct CardPhotoActions: View {
    let card: Card
    let processing: Bool
    let onCrop: () -> Void
    let onRemoveBackground: () -> Void
    let onRestoreOriginal: () -> Void

    var body: some View {
        Section {
            CardPhotoActionRows(
                card: card,
                processing: processing,
                onCrop: onCrop,
                onRemoveBackground: onRemoveBackground,
                onRestoreOriginal: onRestoreOriginal
            )
        }
    }
}

private struct CardPhotoActionRows: View {
    let card: Card
    let processing: Bool
    let onCrop: () -> Void
    let onRemoveBackground: () -> Void
    let onRestoreOriginal: () -> Void

    var body: some View {
        if card.image != nil {
            Button("Crop picture", action: onCrop)
            if #available(iOS 17, *) {
                Button("Remove background", action: onRemoveBackground)
                    .disabled(processing)
            }
            Button("Restore original picture", action: onRestoreOriginal)
                .disabled(card.originalImage == nil || card.image == card.originalImage)
        }
        if processing { ProgressView("Editing picture…") }
    }
}

private struct CardRemainingSections: View {
    let card: Card
    let board: Board?
    let mediaURL: URL
    @ObservedObject var audio: AudioService
    let voice: Binding<VoiceSource>
    let language: Binding<String>
    let voiceID: Binding<String?>
    let error: String?
    let onSaveRecording: () -> Void
    let onStartRecording: () -> Void
    let onRemoveRecording: () -> Void
    let onDuplicate: () -> Void
    let onUseAsCover: () -> Void

    var body: some View {
        #if BOARDLET_PLUS
        CardVoiceEditor(
            card: card,
            board: board,
            mediaURL: mediaURL,
            audio: audio,
            voice: voice,
            language: language,
            voiceID: voiceID,
            onSaveRecording: onSaveRecording,
            onStartRecording: onStartRecording,
            onRemoveRecording: onRemoveRecording
        )
        #endif
        CardActionList(onDuplicate: onDuplicate, onUseAsCover: onUseAsCover)
        if let attribution = card.attribution {
            Section("Source credits") { Text(attribution.exportCredit).font(.footnote) }
        }
        if let error { Section { Text(error).foregroundStyle(.red) } }
    }
}

#if BOARDLET_PLUS
private struct CardVoiceEditor: View {
    let card: Card
    let board: Board?
    let mediaURL: URL
    @ObservedObject var audio: AudioService
    let voice: Binding<VoiceSource>
    let language: Binding<String>
    let voiceID: Binding<String?>
    let onSaveRecording: () -> Void
    let onStartRecording: () -> Void
    let onRemoveRecording: () -> Void

    var body: some View {
        Section("Card voice") {
            Picker("Voice source", selection: voice) {
                Text("Speak the label").tag(VoiceSource.speech)
                Text("Play a recording").tag(VoiceSource.recording)
                Text("Silent").tag(VoiceSource.silent)
            }
            Text("Tap behaviour is set for the whole board in Board controls.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let board {
                Button("Preview voice") { audio.play([card], settings: board.communication, mediaURL: mediaURL) }
                    .disabled(audio.recording)
                VoiceSettingsView(language: language, voiceID: voiceID)
            }
            if audio.recording {
                Label("Recording…", systemImage: "record.circle")
                    .foregroundStyle(.red)
                Button("Save recording", action: onSaveRecording)
                Button("Cancel recording", role: .cancel) { audio.cancelRecording() }
            } else {
                Button(card.recording == nil ? "Record voice" : "Replace recording", action: onStartRecording)
            }
            if card.recording != nil { Button("Remove recording", role: .destructive, action: onRemoveRecording) }
            if let notice = audio.notice { Text(notice).foregroundStyle(.secondary) }
        }
    }
}
#endif

private struct CardActionList: View {
    let onDuplicate: () -> Void
    let onUseAsCover: () -> Void

    var body: some View {
        Section {
            Button("Duplicate card", action: onDuplicate)
            Button("Use as board cover", action: onUseAsCover)
        }
    }
}
