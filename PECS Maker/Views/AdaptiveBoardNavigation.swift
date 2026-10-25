//
//  AdaptiveBoardNavigation.swift
//  PECS Maker
//

import SwiftUI
import SharedSwiftUI

struct AdaptiveBoardNavigation: View {
    @EnvironmentObject private var navigationModel: NavigationModel
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]

    var body: some View {
        ZStack {
            Group {
                if #available(iOS 17.0, *) {
                    NativeBoardNavigation(topicToEdit: $topicToEdit, appMode: $appMode,
                                          mainMenuAction: $mainMenuAction, selectedItems: $selectedItems)
                } else {
                    LegacyBoardNavigation(topicToEdit: $topicToEdit, appMode: $appMode,
                                          mainMenuAction: $mainMenuAction, selectedItems: $selectedItems)
                }
            }
            .opacity(navigationModel.topicsAreMaximized ? 0 : 1)
            .allowsHitTesting(!navigationModel.topicsAreMaximized)
            .accessibilityHidden(navigationModel.topicsAreMaximized)

            if navigationModel.topicsAreMaximized {
                NavigationStack {
                    BoardNavigationSidebar(topicToEdit: $topicToEdit, appMode: $appMode,
                        mainMenuAction: $mainMenuAction, selectedItems: $selectedItems, isSplitView: false)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct NativeBoardNavigation: View {
    @EnvironmentObject private var navigationModel: NavigationModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var isSplitView: Bool { horizontalSizeClass == .regular }

    private var compactColumn: Binding<NavigationSplitViewColumn> {
        Binding(get: {
            switch navigationModel.focus {
            case .boards: return .sidebar
            case .menu:
#if AppHasTopics
                return .content
#else
                return .sidebar
#endif
            case .editor: return .detail
            }
        }, set: { column in
            if column == .detail {
                navigationModel.focus = .editor
            } else if column == .content {
                navigationModel.focus = .menu
            } else {
#if AppHasTopics
                navigationModel.focus = .boards
#else
                navigationModel.focus = .menu
#endif
            }
        })
    }

    var body: some View {
#if AppHasTopics
        NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: compactColumn) {
            BoardNavigationSidebar(topicToEdit: $topicToEdit, appMode: $appMode,
                mainMenuAction: $mainMenuAction, selectedItems: $selectedItems, isSplitView: isSplitView)
        } content: {
            if let topic = topicToEdit {
                MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode,
                    action: $mainMenuAction, selectedItems: $selectedItems, isForSplitView: isSplitView)
                    .id(topic.id)
            }
        } detail: {
            BoardNavigationDetail(appMode: $appMode, isSplitView: isSplitView)
        }
#else
        NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: compactColumn) {
            BoardNavigationSidebar(topicToEdit: $topicToEdit, appMode: $appMode,
                mainMenuAction: $mainMenuAction, selectedItems: $selectedItems, isSplitView: isSplitView)
        } detail: {
            BoardNavigationDetail(appMode: $appMode, isSplitView: isSplitView)
        }
#endif
    }
}

struct BoardNavigationSidebar: View {
    @StateObject private var repoFactory = PECSRepoFactory.shared
    @StateObject private var errorHandler = ErrorHandler.shared
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    let isSplitView: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let error = errorHandler.lastError {
                ErrorView(message: error.localizedDescription, closeAction: {
                    withAnimation { errorHandler.setLastError(nil) }
                })
            }
            TopicSelectionView(appMode: $appMode, mainMenuAction: $mainMenuAction,
                topicToEdit: $topicToEdit, selectedItems: $selectedItems, isForSplitView: isSplitView)
                .environmentObject(repoFactory)
        }
    }
}

struct BoardNavigationDetail: View {
    @EnvironmentObject private var navigationModel: NavigationModel
    @Binding var appMode: PECSAppMode
    let isSplitView: Bool
    var showsBackToMenu = false

    var body: some View {
        // Selecting a board shows its photos in the wide layout. Column focus
        // still determines whether the editor is visible in a compact layout.
        NavigationStack {
            if navigationModel.selectedTopic != nil {
                navigationModel.makeDetailView(for: navigationModel.mainMenuAction ?? .changeSelections,
                                               isForSplitView: isSplitView, appMode: $appMode)
                    .toolbar {
                        if showsBackToMenu {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: { navigationModel.focus = .menu }) {
                                    Label(navigationModel.selectedTopic?.topicName ?? L10n.TopicSelectionView.title,
                                          systemImage: "chevron.backward")
                                }
                                .accessibilityIdentifier("BoardNavigation.backToMenu")
                            }
                        }
                    }
            }
        }
        // A different destination/board ends nested navigation (for example
        // Settings > Credits). Window size never participates in this identity.
        .id(navigationModel.mainMenuAction)
        .id(navigationModel.selectedTopic?.id)
    }
}

// Compatibility navigation for iOS 16, which lacks preferredCompactColumn.
struct LegacyBoardNavigation: View {
    @EnvironmentObject private var navigationModel: NavigationModel
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @State private var hasRoomForColumns = false
    private var isWide: Bool { hasRoomForColumns && topicToEdit != nil }

    var body: some View {
        HStack(spacing: 0) {
#if AppHasTopics
            NavigationStack {
                BoardNavigationSidebar(topicToEdit: $topicToEdit, appMode: $appMode,
                    mainMenuAction: $mainMenuAction, selectedItems: $selectedItems, isSplitView: isWide)
            }
            .modifier(BoardColumnVisibility(isVisible: isWide || navigationModel.focus == .boards))
            NavigationStack {
                if let topic = topicToEdit {
                    MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode,
                        action: $mainMenuAction, selectedItems: $selectedItems, isForSplitView: isWide)
                        .id(topic.id)
                        .toolbar {
                            if !isWide {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: { navigationModel.focus = .boards }) {
                                        Label(L10n.TopicSelectionView.title, systemImage: "chevron.backward")
                                    }
                                }
                            }
                        }
                }
            }
            .modifier(BoardColumnVisibility(isVisible: isWide || navigationModel.focus == .menu))
#else
            NavigationStack {
                BoardNavigationSidebar(topicToEdit: $topicToEdit, appMode: $appMode,
                    mainMenuAction: $mainMenuAction, selectedItems: $selectedItems, isSplitView: isWide)
            }
            .modifier(BoardColumnVisibility(isVisible: isWide || navigationModel.focus != .editor))
#endif
            BoardNavigationDetail(appMode: $appMode, isSplitView: isWide, showsBackToMenu: !isWide)
                .modifier(BoardColumnVisibility(isVisible: isWide || navigationModel.focus == .editor))
        }
        .onGeometryChange(for: Bool.self) { geometry in
            geometry.size.width > 1024
        } action: { hasRoomForColumns = $0 }
    }
}

private struct BoardColumnVisibility: ViewModifier {
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .frame(minWidth: 0, maxWidth: isVisible ? .infinity : 0)
            .clipped()
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityHidden(!isVisible)
    }
}
