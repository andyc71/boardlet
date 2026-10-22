import SwiftUI

/// A search and multiple selection view for ARASAAC pictograms.
public struct ARASAACSymbolPicker: View {
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .subheadline) private var minimumCardWidth = 140.0
    @State private var suggestions: [String] = []
    @State private var query = ""
    @State private var retryToken = 0
    @State private var results: [ARASAACSymbol] = []
    @State private var selection = ARASAACSelectionState()
    @State private var isSearching = false
    @State private var isDownloading = false
    @State private var errorMessage: String?
    @State private var downloadTask: Task<Void, Never>?

    private let suggestionContext: ARASAACSuggestionContext
    private let style: ARASAACPickerStyle
    private let client: ARASAACClient
    private let maxSelections: Int?
    private let completion: ([ARASAACSelection]) -> Void

    public init(
        client: ARASAACClient = ARASAACClient(),
        maxSelections: Int? = nil,
        initialQuery: String = "",
        style: ARASAACPickerStyle = ARASAACPickerStyle(),
        suggestionContext: ARASAACSuggestionContext = .init(boardName: "", cardLabels: []),
        completion: @escaping ([ARASAACSelection]) -> Void
    ) {
        _query = State(initialValue: initialQuery)
        self.suggestionContext = suggestionContext
        self.style = style
        self.client = client
        self.maxSelections = maxSelections
        self.completion = completion
    }

    private struct SuggestionTaskID: Equatable {
        let context: ARASAACSuggestionContext
        let language: String
    }

    private var language: String {
        locale.language.languageCode?.identifier == "es" ? "es" : "en"
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ARASAACSearchField(query: $query)
                    .padding()
                ScrollView {
                    VStack(spacing: 16) { content }
                        .frame(maxWidth: 900)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(style.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ARASAACSelectionFooter(count: selection.ids.count, isDownloading: isDownloading,
                                       add: startDownload)
            }
            .navigationTitle(Text("ARASAAC Symbols", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        completion([])
                    } label: {
                        Label {
                            Text("Cancel", bundle: .module)
                        } icon: {
                            Image(systemName: "xmark")
                        }
                    }
                    .disabled(isDownloading)
                }
            }
        }
        .tint(style.accent)
        .task(id: "\(language)|\(query)|\(retryToken)") { await search() }
        .task(id: SuggestionTaskID(context: suggestionContext, language: language)) {
            suggestions = []
            let generated = await ARASAACSuggestionService.shared.suggestions(
                context: suggestionContext, language: language, client: client)
            guard !Task.isCancelled else { return }
            suggestions = generated
        }
        .onDisappear { downloadTask?.cancel() }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage {
            ARASAACStatusCard(icon: "wifi.exclamationmark", title: "Unable to load symbols",
                              message: errorMessage, style: style)
            Button { retryToken += 1 } label: { Text("Try Again", bundle: .module) }
                .buttonStyle(.bordered)
                .controlSize(.large)
        } else if isSearching {
            ProgressView { Text("Finding symbols…", bundle: .module) }
                .padding(.vertical, 60)
                .frame(maxWidth: .infinity)
        } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ARASAACSearchWelcome(style: style, suggestions: suggestions.filter { term in
                !selection.symbols.contains { ARASAACSuggestionContext.normalized($0.title) == ARASAACSuggestionContext.normalized(term) }
            }) { query = $0 }
        } else if results.isEmpty {
            ARASAACStatusCard(icon: "magnifyingglass", title: "No symbols found.",
                              message: String(localized: "Try a different word or a shorter search.", bundle: .module),
                              style: style)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumCardWidth), spacing: 14)], spacing: 14) {
                ForEach(results) { symbol in
                    ARASAACSymbolCard(symbol: symbol, isSelected: selection.contains(symbol.id), style: style) {
                        selection.toggle(symbol, maxSelections: maxSelections)
                    }
                    .disabled(isDownloading)
                }
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
