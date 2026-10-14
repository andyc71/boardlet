import SwiftUI

/// Compatibility entry point; both interfaces use the same navigation shell.
struct ClassicContentViewSplit: View {
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @Binding var isTopicsMaximized: Bool
    var isSplitView: Bool

    var body: some View {
        ContentViewIOS16Split(topicToEdit: $topicToEdit, appMode: $appMode,
                             mainMenuAction: $mainMenuAction, selectedItems: $selectedItems,
                             isTopicsMaximized: $isTopicsMaximized, isSplitView: isSplitView)
    }
}
