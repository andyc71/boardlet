import SwiftUI

/// A search and multiple selection view for ARASAAC pictograms.
public struct ARASAACSymbolPicker: View {
    @Environment(\.locale) private var locale
    @State private var query = ""
    @State private var retryToken = 0
    @State private var results: [ARASAACSymbol] = []
    @State private var selection = ARASAACSelectionState()
    @State private var isSearching = false
    @State private var isDownloading = false
    @State private var errorMessage: String?
    @State private var downloadTask: Task<Void, Never>?

    private let client: ARASAACClient
    private let maxSelections: Int?
    private let completion: ([ARASAACSelection]) -> Void

    public init(
        client: ARASAACClient = ARASAACClient(),
        maxSelections: Int? = nil,
        completion: @escaping ([ARASAACSelection]) -> Void
    ) {
        self.client = client
        self.maxSelections = maxSelections
        self.completion = completion
    }

    private var language: String {
        locale.language.languageCode?.identifier == "es" ? "es" : "en"
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField(text: $query, prompt: Text("Search ARASAAC", bundle: .module)) {
                    Text("Search ARASAAC", bundle: .module)
                }
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .padding()
                .accessibilityIdentifier("arasaacSearchField")

                content

                Link(destination: URL(string: "https://arasaac.org/terms-of-use")!) {
                    Text("Pictograms: Sergio Palao / ARASAAC · © Government of Aragón · CC BY-NC-SA", bundle: .module)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                .padding(8)
            }
            .navigationTitle(Text("ARASAAC Symbols", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { completion([]) } label: { Text("Cancel", bundle: .module) }
                        .disabled(isDownloading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { startDownload() } label: {
                        if isDownloading {
                            ProgressView()
                        } else {
                            Text("Add", bundle: .module)
                        }
                    }
                    .disabled(selection.isEmpty || isDownloading)
                    .accessibilityIdentifier("arasaacAddButton")
                }
            }
        }
        .task(id: "\(language)|\(query)|\(retryToken)") { await search() }
        .onDisappear { downloadTask?.cancel() }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage {
            VStack(spacing: 12) {
                Text(errorMessage).multilineTextAlignment(.center)
                Button { retryToken += 1 } label: { Text("Try Again", bundle: .module) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isSearching {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("Type a word to search for symbols.", bundle: .module)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if results.isEmpty {
            Text("No symbols found.", bundle: .module)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    ForEach(results) { symbol in
                        Button { selection.toggle(symbol, maxSelections: maxSelections) } label: {
                            VStack(spacing: 6) {
                                AsyncImage(url: symbol.thumbnailURL) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(height: 90)
                                Text(symbol.title)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(8)
                            .background(selection.contains(symbol.id) ? Color.accentColor.opacity(0.18) : Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .topTrailing) {
                                if selection.contains(symbol.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .padding(4)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(symbol.title)
                        .accessibilityAddTraits(selection.contains(symbol.id) ? .isSelected : [])
                    }
                }
                .padding()
            }
        }
    }

    @MainActor
    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        guard !term.isEmpty else {
            results = []
            isSearching = false
            return
        }
        isSearching = true
        do {
            try await Task.sleep(nanoseconds: 350_000_000)
            let found = try await client.search(term, language: language)
            try Task.checkCancellation()
            results = found
        } catch is CancellationError {
            return
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }
        isSearching = false
    }

    private func startDownload() {
        let symbols = selection.symbols
        isDownloading = true
        errorMessage = nil
        downloadTask = Task {
            do {
                let selections = try await client.download(symbols)
                try Task.checkCancellation()
                completion(selections)
            } catch is CancellationError {
                // The picker was dismissed.
            } catch {
                errorMessage = error.localizedDescription
            }
            isDownloading = false
        }
    }
}
