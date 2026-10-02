#if os(iOS)
import SwiftUI

@MainActor
struct AACStandardResultsView: View {
    @ObservedObject var model: AACStandardPickerModel
    let query: String
    let isDownloading: Bool
    let retry: () -> Void
    let loadMore: () -> Void

    var body: some View {
        VStack {
            if model.isSearching {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Type a word to search for symbols.", bundle: .module)
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if let error = model.searchError {
                    Text(error).multilineTextAlignment(.center)
                    Button(action: model.results.isEmpty ? retry : loadMore) {
                        Text("Try Again", bundle: .module)
                    }
                    .disabled(isDownloading)
                }
                if model.results.isEmpty && model.searchError == nil {
                    Text("No symbols found.", bundle: .module)
                        .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                            ForEach(model.results) { symbol in
                                AACStandardSymbolCell(symbol: symbol,
                                    isSelected: model.selections.contains { $0.id == symbol.id },
                                    action: { model.toggle(symbol) })
                            }
                        }
                        .padding()
                        if model.isLoadingMore {
                            ProgressView().padding()
                        } else if model.nextOffset != nil {
                            Button(action: loadMore) { Text("Load More", bundle: .module) }
                                .padding()
                                .accessibilityIdentifier("aacStandardLoadMoreButton")
                        }
                    }
                    .disabled(isDownloading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
