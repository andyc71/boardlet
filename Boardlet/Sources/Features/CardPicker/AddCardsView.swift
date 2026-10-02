import SwiftUI
@preconcurrency import ARASAACSymbols
import AVFoundation

struct AddCardsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = CardImportSession()
    var single = false
    let completion: ([Card]) -> Void
    @State private var source = "Symbols"
    @State private var photoPicker = false
    @State private var camera = false
    @State private var query = ""
    @State private var results: [ARASAACSymbol] = []
    @State private var picked: [ARASAACSymbol] = []
    @State private var searchError: String?
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var language = Locale.current.language.languageCode?.identifier == "es" ? "es" : "en"
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Source", selection: $source) { Text("Symbols").tag("Symbols"); Text("Photos").tag("Photos"); Text("Camera").tag("Camera"); Text("Text").tag("Text") }.pickerStyle(.segmented)
                    if source == "Symbols" {
                        HStack { TextField("Search symbols", text: $query).textFieldStyle(.roundedBorder).onSubmit(search); Button("Search", action: search).disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                        Picker("Symbol language", selection: $language) { Text("English").tag("en"); Text("Español").tag("es") }
                        Text("ARASAAC · Sergio Palao · Government of Aragón · CC BY-NC-SA").font(.caption).foregroundStyle(.secondary)
                        if searching { ProgressView("Searching…") }
                        if let searchError { Text(searchError).foregroundStyle(.red); Button("Retry", action: search) }
                        if !searching && results.isEmpty { Text("Search for pictures to add to your board. Downloaded cards work offline.").foregroundStyle(.secondary) }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))]) {
                            ForEach(results) { symbol in
                                Button {
                                    if picked.contains(symbol) { picked.removeAll { $0.id == symbol.id } }
                                    else { if single { picked = [] }; picked.append(symbol) }
                                } label: {
                                    VStack {
                                        AsyncImage(url: symbol.thumbnailURL) { image in image.resizable().scaledToFit() } placeholder: { Image(systemName: "photo").foregroundStyle(.secondary) }.frame(height: 96)
                                        Text(symbol.title).font(.headline)
                                        if picked.contains(symbol) { Label("Selected", systemImage: "checkmark.circle.fill") }
                                    }.padding().frame(maxWidth: .infinity, minHeight: 155).background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                                }.buttonStyle(.plain)
                            }
                        }
                        if !picked.isEmpty {
                            Button { session.importSymbols(picked, storage: store.storage); picked = [] } label: { Text("Download \(picked.count) selected") }.buttonStyle(.borderedProminent).disabled(session.loading)
                        }
                        #if BOARDLET_PLUS
                        PlusSourcesView { session.cards.append($0) }
                        #endif
                    } else if source == "Photos" {
                        Label("Choose pictures from your library", systemImage: "photo.on.rectangle").font(.title2)
                        Button("Choose photos") { photoPicker = true }.buttonStyle(.borderedProminent).disabled(session.loading)
                    } else if source == "Camera" {
                        Label("Take a photo for a card", systemImage: "camera").font(.title2)
                        Button("Open camera") { Task { await openCamera() } }.buttonStyle(.borderedProminent)
                    } else {
                        Text("Create a card with a label. Add a picture or a recording whenever you need one.")
                        Button("Add a text card") { session.cards.append(Card(label: L("New card"), systemSymbol: "text.bubble")) }.buttonStyle(.borderedProminent)
                    }
                    if session.loading {
                        ProgressView(value: Double(session.completed), total: Double(max(1, session.total))) { Text("Importing \(session.completed) of \(session.total)") }
                        Button("Cancel import") { session.cancel() }
                    }
                    if !session.failures.isEmpty {
                        Text("Some cards could not be imported. Your successful selections are kept.").font(.headline)
                        ForEach(session.failures, id: \.self) { Text($0).font(.caption).foregroundStyle(.red) }
                        Button("Retry failed items") { session.retry(storage: store.storage) }.disabled(session.loading)
                    }
                    if !session.cards.isEmpty {
                        Text("Ready to add: \(session.cards.count)").font(.headline)
                        ForEach(session.cards) { card in
                            HStack { CardArtwork(card: card, mediaURL: store.mediaURL).frame(width: 64, height: 64); Text(card.label.isEmpty ? L("Photo") : card.label); Spacer(); Button { session.cards.removeAll { $0.id == card.id } } label: { Label("Remove", systemImage: "minus.circle") } }
                        }
                    }
                }.padding()
            }.navigationTitle(single ? "Choose picture" : "Add cards")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { session.cancel(); dismiss() }.accessibilityIdentifier("cancelAdd") }
                    ToolbarItem(placement: .confirmationAction) { Button(single ? L("Use picture") : L("Add") + " (\(session.cards.count))") { completion(single ? Array(session.cards.prefix(1)) : session.cards); dismiss() }.disabled(session.cards.isEmpty || session.loading).accessibilityIdentifier("confirmAdd") }
                }
                .sheet(isPresented: $photoPicker) {
                    SystemPhotoPicker(selectionLimit: single ? 1 : 0, onSelection: { providers in photoPicker = false; session.importPhotos(providers.map(ImageImportSource.init(provider:)), storage: store.storage) }, onCancel: { photoPicker = false })
                }
                .fullScreenCover(isPresented: $camera) { CameraPicker { image in camera = false; if let image { Task { await session.addImage(image, storage: store.storage) } } }.ignoresSafeArea() }
                .onDisappear { searchTask?.cancel(); session.cancel() }
        }
    }
    func search() {
        searchTask?.cancel(); searching = true; searchError = nil
        let term = query; let lang = language
        searchTask = Task {
            do {
                let found = try await ARASAACClient().search(term, language: lang)
                try Task.checkCancellation(); results = found; searching = false
            } catch is CancellationError { }
            catch { searchError = error.localizedDescription; searching = false }
        }
    }
    func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { searchError = L("A camera is not available on this device."); source = "Symbols"; return }
        let allowed = await AVCaptureDevice.requestAccess(for: .video)
        if allowed { camera = true }
        else { searchError = L("Allow Camera access in Settings to take a photo."); source = "Symbols" }
    }
}
