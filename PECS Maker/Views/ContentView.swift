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

    @StateObject var repoFactory = PECSRepoFactory.shared
    @StateObject var errorHandler = ErrorHandler.shared
    
    @AppStorage(InterfaceStyle.storageKey) private var interfaceStyle = InterfaceStyle.defaultValue

    @Binding var topicToEdit: PECSRepo?

    @AppStorage("isTopicSelectionMaximized")
    private var isTopicSelectionMaximized = false
    
    @AppStorage("appMode")
    var appMode: PECSAppMode = .pecsMaker
    
    @State var selectedItems: [PhotoItem] = []
    
    //@State var navigationModel = NavigationModel()
    @StateObject private var navigationModel = NavigationModel()
    
    //@Environment(\.horizontalSizeClass) var horizontalSizeClass
    //@Environment(\.screen) var screen
    
    var body: some View {
        ContentViewIOS16Split(topicToEdit: $topicToEdit, appMode: $appMode,
                              mainMenuAction: navigationModel.actionBinding, selectedItems: $selectedItems,
                              isTopicsMaximized: $isTopicSelectionMaximized, isSplitView: true)
        .onChange(of: interfaceStyle) { _ in
            navigationModel.resetInterfaceNavigation()
        }
        .tint(.mfVeryBrightBlue)
        .if(appMode == .choiceBoard && FeatureFlags.current.voiceEnabled) { view in
            view.mutePrompt(foregroundColor: Color.mfVeryBrightBlue, backgroundColor: Color.mfLightYellow)
        }
        .environmentObject(navigationModel)
        // Board creation can replace the compact hierarchy with a split view.
        // Observe the selection here so that transition cannot lose preparation.
        .onAppear {
            // A saved Choice Board mode can remain after installing Standard.
            if !FeatureFlags.current.voiceEnabled && appMode == .choiceBoard {
                appMode = .pecsMaker
            }
            navigationModel.restoreInitialTopic(topicToEdit, openBoard: !isTopicSelectionMaximized)
        }
        .onChange(of: topicToEdit) { topic in
            if let topic { navigationModel.setTopic(topic) }
            else { navigationModel.clearTopic() }
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
