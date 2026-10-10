import SwiftUI
import SharedSwiftUI

/// Original persistent menu/detail arrangement, isolated for eventual Classic removal.
struct ClassicContentViewSplit: View {
    @EnvironmentObject private var navigationModel: NavigationModel
    @EnvironmentObject private var repoFactory: PECSRepoFactory
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @Binding var isTopicsMaximized: Bool
    var isSplitView: Bool
    @State private var visibility: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            TopicSelectionView(appMode: $appMode, mainMenuAction: $mainMenuAction,
                               topicToEdit: $topicToEdit, selectedItems: $selectedItems,
                               isForSplitView: true, isTopicsMaximized: $isTopicsMaximized)
        } content: {
            if let topic = topicToEdit {
                MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode,
                                              action: $mainMenuAction, selectedItems: $selectedItems,
                                              isForSplitView: true)
            }
        } detail: {
            NavigationStack {
                navigationModel.makeDetailView(for: mainMenuAction ?? .changeSelections,
                                               isForSplitView: true, appMode: $appMode,
                                               mainMenuAction: $mainMenuAction, interfaceStyle: .classic)
            }
            .id(mainMenuAction)
        }
        .onAppear {
            if let topicToEdit { navigationModel.prepareTopic(topicToEdit) }
        }
        .onChange(of: topicToEdit) { topic in
            if let topic {
                navigationModel.prepareTopic(topic)
                visibility = .doubleColumn
            } else {
                visibility = .all
            }
        }
    }
}
