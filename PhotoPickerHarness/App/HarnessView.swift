import SwiftUI

struct HarnessView: View {
    @StateObject private var harness = HarnessModel()
    @StateObject private var importer = PhotoImportModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Selection", selection: $harness.selectionLimit) {
                    Text("Multiple").tag(0)
                    Text("Single").tag(1)
                }
                .pickerStyle(.segmented)
                .disabled(importer.isLoading)

                Button("Choose Photos") { harness.showingPicker = true }
                    .accessibilityIdentifier("choosePhotos")
                    .disabled(importer.isLoading)

                status
                Text("Imported: \(importer.photos.count)")
                    .accessibilityIdentifier("importedCount")
                ScrollView {
                    LazyVStack {
                        ForEach(Array(importer.photos.enumerated()), id: \.element.id) { index, photo in
                            VStack {
                                Image(uiImage: photo.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 160)
                                    .accessibilityLabel("Imported photo \(index + 1)")
                                    .accessibilityIdentifier("thumbnail-\(index)")
                                Text(ImageEvidence.describe(photo.image))
                                    .font(.caption.monospaced())
                                    .accessibilityIdentifier("content-\(index)")
                            }
                        }
                    }
                }
                .accessibilityIdentifier("importedPhotos")
            }
            .padding()
            .navigationTitle("Photos Picker Harness")
            .sheet(isPresented: $harness.showingPicker) {
                SystemPhotoPicker(selectionLimit: harness.selectionLimit) { providers in
                    harness.showingPicker = false
                    importer.importPhotos(from: providers)
                } onCancel: {
                    harness.showingPicker = false
                    importer.cancel()
                }
            }
        }
    }

    @ViewBuilder private var status: some View {
        switch importer.state {
        case .idle: Text("Ready").accessibilityIdentifier("importStatus")
        case let .loading(completed, total):
            ProgressView("Loading \(completed) of \(total)…", value: Double(completed), total: Double(total))
                .accessibilityIdentifier("loadingStatus")
            Button("Cancel Import", action: importer.cancel)
        case .loaded: Text("Import complete").accessibilityIdentifier("importStatus")
        case .cancelled: Text("Cancelled; imported photos unchanged").accessibilityIdentifier("importStatus")
        case let .failed(message):
            Text(message).foregroundStyle(.red).accessibilityIdentifier("importError")
        }
    }
}
