import SwiftUI

struct ARASAACSearchWelcome: View {
    @ObservedObject var model: ARASAACBoardSuggestionsModel
    let isSelected: (ARASAACBoardSuggestion) -> Bool
    let toggle: (ARASAACBoardSuggestion) -> Void
    let retry: () -> Void

    var body: some View {
        List {
            ARASAACBoardSuggestionSection(model: model,
                                           title: Text("Suggested for your board", bundle: .module),
                                           isSelected: isSelected, toggle: toggle, retry: retry)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }
}
