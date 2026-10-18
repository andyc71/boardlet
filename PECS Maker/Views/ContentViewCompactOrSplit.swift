import SwiftUI
import SharedSwiftUI

/// Adaptive navigation shell. Column layout is presentation; history lives in
/// NavigationModel and is never reconstructed to implement Back.
struct ContentViewIOS16Split: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var navigationModel: NavigationModel
    @EnvironmentObject private var currentTheme: SharedUITheme
    @AppStorage(InterfaceStyle.storageKey) private var interfaceStyle = InterfaceStyle.defaultValue
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @Binding var isTopicsMaximized: Bool
    var isSplitView: Bool
    @StateObject private var errorHandler = ErrorHandler.shared
    @State private var visibility: NavigationSplitViewVisibility = .all

    private var isCompact: Bool { horizontalSizeClass == .compact || isTopicsMaximized }
    private var scope: NavigationScope {
        isCompact ? .compact : interfaceStyle == .classic ? .classicDetail : .modernDetail
    }

    var body: some View {
        Group {
            if isCompact {
                NavigationStack(path: navigationModel.pathBinding(for: .compact)) {
                    topics(isForSplitView: false)
                        .navigationDestination(for: AppRoute.self) { destination($0, isRoot: false) }
                }
            } else if interfaceStyle == .classic {
                NavigationSplitView(columnVisibility: $visibility) {
                    topics(isForSplitView: true)
                } content: {
                    boardRoot
                } detail: {
                    detailStack
                }
            } else {
                NavigationSplitView(columnVisibility: $visibility) {
                    topics(isForSplitView: true)
                } detail: {
                    detailStack
                }
            }
        }
        .onChange(of: isTopicsMaximized) { maximized in
            if maximized { navigationModel.showTopics() }
            else if navigationModel.path.isEmpty, let topic = topicToEdit {
                navigationModel.setTopic(topic)
            }
        }
    }

    private var detailStack: some View {
        NavigationStack(path: navigationModel.pathBinding(for: scope)) {
            Group {
                if interfaceStyle == .classic,
                   navigationModel.rootDepth(for: .classicDetail) > 0 {
                    destination(.menu(navigationModel.selectedAction ?? .changeSelections), isRoot: true)
                } else {
                    boardRoot
                }
            }
            .navigationDestination(for: AppRoute.self) { destination($0, isRoot: false) }
        }
    }

    @ViewBuilder
    private var boardRoot: some View {
        if let topic = navigationModel.pageLayoutState?.topic,
           navigationModel.path.first == .board(topic.id) {
            destination(.board(topic.id), isRoot: true)
        } else {
            EmptyView()
        }
    }

    private func destination(_ route: AppRoute, isRoot: Bool) -> some View {
        AppNavigationDestination(route: route, interfaceStyle: interfaceStyle,
                                 isForSplitView: isRoot && !isCompact,
                                 appMode: $appMode, selectedItems: $selectedItems)
    }

    private func topics(isForSplitView: Bool) -> some View {
        VStack(spacing: 0) {
            if let error = errorHandler.lastError {
                ErrorView(message: error.localizedDescription, closeAction: { errorHandler.setLastError(nil) })
            }
            TopicSelectionView(appMode: $appMode, mainMenuAction: $mainMenuAction,
                           topicToEdit: $topicToEdit, selectedItems: $selectedItems,
                           isForSplitView: isForSplitView, isTopicsMaximized: $isTopicsMaximized,
                           canRestoreSplitView: horizontalSizeClass != .compact)
        }
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
    }
}
