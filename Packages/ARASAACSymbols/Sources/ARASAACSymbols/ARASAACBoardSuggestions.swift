import SwiftUI

/// Text suggestions appear before their pictograms finish searching and downloading.
public struct ARASAACBoardSuggestions: View {
    @Environment(\.locale) private var locale
    @StateObject private var model = ARASAACBoardSuggestionsModel()
    @State private var retryToken = 0
    @State private var showsSearch = false
    private let context: ARASAACSuggestionContext
    private let client: ARASAACClient
    private let completion: ([ARASAACSelection]) -> Void

    public init(context: ARASAACSuggestionContext, client: ARASAACClient = ARASAACClient(),
                completion: @escaping ([ARASAACSelection]) -> Void) {
        self.context = context
        self.client = client
        self.completion = completion
    }

    private var language: String { locale.language.languageCode?.identifier == "es" ? "es" : "en" }

    public var body: some View {
        List {
            ARASAACBoardSuggestionSection(model: model, title: Text(verbatim: context.boardName),
                                           isSelected: { model.selectedTerms.contains($0.term) },
                                           toggle: { item in
                if !model.selectedTerms.insert(item.term).inserted {
                    model.selectedTerms.remove(item.term)
                }
            }, retry: { retryToken += 1 })
            Button { showsSearch = true } label: { Text("Search ARASAAC", bundle: .module) }
            Link(destination: URL(string: "https://arasaac.org/terms-of-use")!) {
                Text("Pictograms: Sergio Palao / ARASAAC · © Government of Aragón · CC BY-NC-SA", bundle: .module)
                    .font(.caption)
            }
        }
        .accessibilityIdentifier("boardSuggestionsList")
        .navigationTitle(Text("Suggested for your board", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { completion([]) } label: { Text("Cancel", bundle: .module) }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { completion(model.selections) } label: { Text("Add", bundle: .module) }
                    .disabled(!model.canAdd)
                    .accessibilityIdentifier("boardSuggestionsAdd")
            }
        }
        .task(id: language) { await model.load(context: context, language: language, client: client) }
        .task(id: retryToken) {
            if retryToken > 0 { await model.retry(language: language, client: client) }
        }
        .fullScreenCover(isPresented: $showsSearch) {
            ARASAACSymbolPicker(client: client, suggestionContext: context) { selections in
                showsSearch = false
                if !selections.isEmpty { completion(selections) }
            }
        }
    }
}
