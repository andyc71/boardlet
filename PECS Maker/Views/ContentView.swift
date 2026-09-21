//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine
import SharedSwiftUI
import LogFramework
import MediaFramework

struct ContentView: View {
    
    @EnvironmentObject var currentTheme: SharedUITheme

    @EnvironmentObject private var repoFactory: PECSRepoFactory
    @EnvironmentObject private var errorHandler: ErrorHandler
    
    @Binding var topicToEdit: PECSRepo?
    
    @AppStorage("appMode")
    var appMode: PECSAppMode = .pecsMaker
    
    @State var selectedItems: [PhotoItem] = []
    
    //@State var navigationModel = NavigationModel()
    @StateObject private var navigationModel = NavigationModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var mainMenuAction: Binding<MainMenuAction?> {
        Binding(
            get: { navigationModel.currentAction },
            set: { navigationModel.updateMainMenuAction($0) }
        )
    }
    
    //@Environment(\.horizontalSizeClass) var horizontalSizeClass
    //@Environment(\.screen) var screen
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                ContentViewIOS16Split(
                    topicToEdit: $topicToEdit,
                    appMode: $appMode,
                    mainMenuAction: mainMenuAction,
                    selectedItems: $selectedItems,
                    isSplitView: true
                )
            }
            else {
                ContentViewIOS16Compact(
                    topicToEdit: $topicToEdit,
                    appMode: $appMode,
                    mainMenuAction: mainMenuAction,
                    selectedItems: $selectedItems
                )
            }
        }
        .if(appMode == .choiceBoard) { view in
            view.mutePrompt(foregroundColor: Color.mfVeryBrightBlue, backgroundColor: Color.mfLightYellow)
        }
        .environmentObject(navigationModel)
    }
    
}

@available(iOS 16.0, *)
private struct ContentViewIOS16Compact: View {
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var repoFactory: PECSRepoFactory
    @EnvironmentObject private var errorHandler: ErrorHandler
    @EnvironmentObject private var navigationModel: NavigationModel

    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]

    private var navigationPath: Binding<[AppRoute]> {
        Binding(
            get: { navigationModel.compactPath },
            set: { newPath in
                navigationModel.updateCompactPath(newPath)
                if newPath.isEmpty {
                    topicToEdit = nil
                }
            }
        )
    }

    var body: some View {
        NavigationStack(path: navigationPath) {
            VStack(spacing: 0) {
                if let lastError = errorHandler.lastError {
                    ErrorView(message: lastError.localizedDescription) {
                        withAnimation {
                            errorHandler.setLastError(nil)
                        }
                    }
                }

                TopicSelectionView(
                    appMode: $appMode,
                    mainMenuAction: $mainMenuAction,
                    topicToEdit: $topicToEdit,
                    selectedItems: $selectedItems,
                    isForSplitView: false
                )
                .environmentObject(repoFactory)
            }
            .frame(maxWidth: .infinity)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .topic(let topicID):
                    if let topic = navigationModel.topic(for: topicID) {
                        MainMenuViewOrChoiceBoardView(
                            topic: topic,
                            appMode: $appMode,
                            action: $mainMenuAction,
                            selectedItems: $selectedItems,
                            isForSplitView: false
                        )
                    }
                    else {
                        EmptyView()
                    }
                case .action(_, let action):
                    navigationModel.makeDetailView(
                        for: action,
                        isForSplitView: false,
                        appMode: $appMode
                    )
                }
            }
        }
        .accentColor(.mfVeryBrightBlue)
        .environmentObject(currentTheme)
        .onAppear {
            navigationModel.adapt(toSplitView: false)
            if let topicToEdit {
                navigationModel.prepareTopic(topicToEdit)
                if navigationModel.route == nil {
                    navigationModel.setTopic(topicToEdit)
                }
            }
        }
        .onChange(of: topicToEdit) { newValue in
            if let newValue {
                navigationModel.setTopic(newValue)
            }
            else if !navigationModel.compactPath.isEmpty {
                navigationModel.clearSelection()
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//
//    @State static var showRatingPrompt: Bool = false
//
//    static var previews: some View {
//        ContentView(showRatingPrompt: showRatingPrompt)
//        //ContentView(showRatingPrompt: .constant(false))
//    }
//}
//
//
