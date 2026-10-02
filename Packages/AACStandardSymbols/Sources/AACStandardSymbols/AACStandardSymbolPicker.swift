#if os(iOS)
import SwiftUI

/// Search, select across pages, and download a complete selection. The host dismisses the picker
/// in completion; Cancel supplies an empty array, matching ARASAAC and Dynavox.
@MainActor
public struct AACStandardSymbolPicker: View {
    @Environment(\.locale) private var locale
    @StateObject private var model: AACStandardPickerModel
    @State private var query = ""
    @State private var retryToken = 0
    @State private var loadMoreToken = 0
    @State private var isDownloading = false
    private let language: String?
    private let ageGroup: AACStandardAgeGroup?
    private let completion: ([AACStandardSelection]) -> Void

    public init(client: any AACStandardServing = AACStandardClient(), maxSelections: Int? = nil,
                language: String? = nil, ageGroup: AACStandardAgeGroup? = nil,
                completion: @escaping ([AACStandardSelection]) -> Void) {
        _model = StateObject(wrappedValue: AACStandardPickerModel(service: client, maxSelections: maxSelections))
        self.language = language
        self.ageGroup = ageGroup
        self.completion = completion
    }

    private var request: AACStandardSearchRequest {
        // These are the service's advertised languages at implementation time. Callers may
        // supply any language explicitly, including languages added by the service later.
        let supported = ["pl", "en", "de", "uk", "fr", "es", "it", "cs", "sk"]
        let code = locale.language.languageCode?.identifier ?? "en"
        return AACStandardSearchRequest(term: query, language: language ?? (supported.contains(code) ? code : "en"),
                                        ageGroup: ageGroup)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField(text: $query, prompt: Text("Search AAC Standard", bundle: .module)) {
                    Text("Search AAC Standard", bundle: .module)
                }
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .disabled(isDownloading)
                .accessibilityIdentifier("aacStandardSearchField")

                AACStandardResultsView(model: model, query: query, isDownloading: isDownloading,
                                       retry: { retryToken += 1 }, loadMore: { loadMoreToken += 1 })

                if let error = model.downloadError {
                    Text(error).multilineTextAlignment(.center).padding(8)
                }
                if !model.selections.isEmpty {
                    HStack {
                        Text("Selected: \(model.selections.count)", bundle: .module)
                        Spacer()
                        Button { model.clearSelection() } label: { Text("Clear Selection", bundle: .module) }
                    }
                    .font(.footnote)
                    .padding(.horizontal)
                    .disabled(isDownloading)
                }
                Link(destination: AACStandardSymbol.licenseURL) {
                    Text("AAC Standard · © aisay.co · Terms of use", bundle: .module)
                        .font(.footnote).multilineTextAlignment(.center)
                }
                .padding(8)
            }
            .navigationTitle(Text("AAC Standard Symbols", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { completion([]) } label: { Text("Cancel", bundle: .module) }
                        .disabled(isDownloading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { isDownloading = true } label: {
                        if isDownloading { ProgressView() }
                        else { Text("Add", bundle: .module) }
                    }
                    .disabled(model.selections.isEmpty || isDownloading)
                    .accessibilityLabel(Text("Add", bundle: .module))
                    .accessibilityIdentifier("aacStandardAddButton")
                }
            }
        }
        .interactiveDismissDisabled(isDownloading)
        .task(id: SearchIdentity(request: request, retry: retryToken)) { await model.search(request) }
        .task(id: loadMoreToken) {
            if loadMoreToken > 0 { await model.loadMore() }
        }
        .task(id: isDownloading) {
            guard isDownloading else { return }
            let selections = await model.downloadSelection()
            guard !Task.isCancelled else { return }
            isDownloading = false
            if let selections { completion(selections) }
        }
    }
}

private struct SearchIdentity: Equatable {
    let request: AACStandardSearchRequest
    let retry: Int
}
#endif
