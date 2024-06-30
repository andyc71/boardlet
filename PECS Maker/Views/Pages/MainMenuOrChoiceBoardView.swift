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

    @ObservedObject var topic: PECSRepo
    var isForSplitView: Bool
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]

    init(topic: PECSRepo, appMode: Binding<PECSAppMode>, action: Binding<MainMenuAction?>, selectedItems: Binding<[PhotoItem]>, isForSplitView: Bool) {
        self.topic = topic
        self._appMode = appMode
        self._mainMenuAction = action
        self._selectedItems = selectedItems
        self.isForSplitView = isForSplitView
    }
    
    var body: some View {
        switch appMode {
        case .pecsMaker:
            MainMenuView(pageLayoutState: PageLayoutState(topic: topic), appMode: $appMode, action: $mainMenuAction, isForSplitView: isForSplitView)
        case .choiceBoard:
            ChoiceBoardView(topic: topic, appMode: $appMode, action: $mainMenuAction, selectedItems: $selectedItems, isForSplitView: isForSplitView)
        }
    }
}
