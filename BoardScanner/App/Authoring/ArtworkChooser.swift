import SwiftUI
import UniformTypeIdentifiers

struct ArtworkChooser: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var importer = PhotoImportModel()
    @State private var showPhotos = false
    @State private var showFiles = false
    @State private var error: String?
    @State private var loading = false
    @State private var task: Task<Void, Never>?
    let select: (Data) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button { showPhotos = true } label: { Label("Photos", systemImage: "photo") }
                            .accessibilityIdentifier("buttonArtworkPhotos")
                        Button { showFiles = true } label: { Label("Files", systemImage: "folder") }
                            .accessibilityIdentifier("buttonArtworkFiles")
                    }.buttonStyle(.bordered)
                    if loading || importer.isLoading { ProgressView("Preparing picture…") }
                    if let error { Text(error).foregroundStyle(.red).accessibilityIdentifier("artworkImportError") }
                    Text("Built-in symbols").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(BuiltinSymbol.choices) { symbol in
                            Button { choose(symbol) } label: {
                                VStack {
                                    Image(systemName: symbol.name).font(.largeTitle).accessibilityHidden(true)
                                    Text(symbol.label).font(.body)
                                }.frame(maxWidth: .infinity, minHeight: 90)
                            }.buttonStyle(.bordered).accessibilityIdentifier("builtinSymbol_\(symbol.label)")
                        }
                    }
                }.padding().disabled(loading || importer.isLoading)
            }
            .navigationTitle("Choose picture")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .sheet(isPresented: $showPhotos) {
                SystemPhotoPicker(selectionLimit: 1, onSelection: { providers in
                    showPhotos = false
                    importer.importPhotos(from: providers)
                }, onCancel: { showPhotos = false })
            }
            .fileImporter(isPresented: $showFiles, allowedContentTypes: [.image]) { result in
                switch result {
                case .success(let url): load { try await BoardStorage.read(url) }
                case .failure(let failure): error = failure.localizedDescription
                }
            }
            .onChange(of: importer.state) { state in
                if case .loaded = state, let data = importer.photos.first?.pngData { load { data } }
                if case .failed(let message) = state { error = message }
            }
            .onDisappear { task?.cancel(); importer.cancel() }
        }
    }

    private func choose(_ symbol: BuiltinSymbol) {
        do { select(try ButtonArtwork.symbol(symbol)); dismiss() }
        catch { self.error = error.localizedDescription }
    }

    private func load(_ read: @escaping @MainActor () async throws -> Data) {
        task?.cancel()
        loading = true
        error = nil
        task = Task { @MainActor in
            do {
                let input = try await read()
                let data = try await ButtonArtwork.normalize(input)
                try Task.checkCancellation()
                select(data)
                dismiss()
            } catch is CancellationError { }
            catch { self.error = error.localizedDescription }
            if !Task.isCancelled { loading = false }
        }
    }
}
