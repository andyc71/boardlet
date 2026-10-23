import SwiftUI

/// Shared suggestion presentation for Inspire me and the symbol picker.
struct ARASAACBoardSuggestionSection: View {
    @ObservedObject var model: ARASAACBoardSuggestionsModel
    let title: Text
    let isSelected: (ARASAACBoardSuggestion) -> Bool
    let toggle: (ARASAACBoardSuggestion) -> Void
    let retry: () -> Void

    var body: some View {
        Section {
            if model.isGenerating {
                ProgressView { Text("Finding suggestions…", bundle: .module) }
            } else if model.items.isEmpty {
                Text("Suggestions aren't available for this board right now. You can still search for symbols.", bundle: .module)
            } else {
                ForEach(model.items) { item in
                    ARASAACBoardSuggestionRow(item: item, isSelected: isSelected(item)) {
                        toggle(item)
                    }
                }
            }
        } header: {
            title
        } footer: {
            if !model.items.isEmpty {
                Text("Choose items to add. Symbols will appear as they load.", bundle: .module)
            }
        }
        if model.items.contains(where: { if case .failed = $0.status { return true }; return false }) {
            Button(action: retry) { Text("Try Again", bundle: .module) }
                .disabled(model.isRetrying || model.isResolving)
        }
    }
}
