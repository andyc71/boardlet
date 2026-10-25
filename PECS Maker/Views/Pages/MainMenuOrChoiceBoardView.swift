//
//  ChoiceBoardView.swift
//  PECS Maker
//
//  Created by Andy on 16/07/2023.
//

import SwiftUI
import PhotosUI
import LogFramework
import SharedSwiftUI
import SFSafeSymbols
import MediaFramework

//typealias MainMenuViewOrChoiceBoardView = ChoiceBoardView
//typealias MainMenuViewOrChoiceBoardView = MainMenuView

enum PECSAppMode : String { case pecsMaker, choiceBoard }

struct MainMenuViewOrChoiceBoardView : View {

    @AppStorage(InterfaceStyle.storageKey) private var interfaceStyle = InterfaceStyle.defaultValue

    @ObservedObject var topic: PECSRepo
    var isForSplitView: Bool
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @EnvironmentObject var navigationModel: NavigationModel

    init(topic: PECSRepo, appMode: Binding<PECSAppMode>, action: Binding<MainMenuAction?>, selectedItems: Binding<[PhotoItem]>, isForSplitView: Bool) {
        self.topic = topic
        self._appMode = appMode
        self._mainMenuAction = action
        self._selectedItems = selectedItems
        self.isForSplitView = isForSplitView
    }
    
    var body: some View {
        BoardHierarchyContainer(
            topic: topic,
            showsLibraryActions: interfaceStyle != .classic
                || (appMode == .choiceBoard && FeatureFlags.current.voiceEnabled)
        ) { boardContent }
    }

    @ViewBuilder private var boardContent: some View {
        if let pageLayoutState = navigationModel.pageLayoutState {
            if appMode == .choiceBoard && FeatureFlags.current.voiceEnabled {
                ChoiceBoardView(pageLayoutState: pageLayoutState, appMode: $appMode, action: $mainMenuAction, selectedItems: $selectedItems, isForSplitView: isForSplitView)
            } else if interfaceStyle == .classic {
                ClassicMainMenuView(pageLayoutState: pageLayoutState, appMode: $appMode, action: $mainMenuAction, isForSplitView: isForSplitView)
            } else {
                PhotoListView2(pageLayoutState: pageLayoutState, appMode: $appMode,
                               mainMenuAction: $mainMenuAction, isForSplitView: isForSplitView,
                               dismissAction: { pageLayoutState.save() })
            }
        }
        else {
            Text("Error: Page Layout State not set")
        }
    }
}
