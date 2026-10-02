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
    
    @Binding var topicToEdit: PECSRepo?

    @AppStorage("isTopicSelectionMaximized")
    private var isTopicSelectionMaximized = false
    
    @AppStorage("appMode")
    var appMode: PECSAppMode = .pecsMaker
    
    //AppStorage with optionals isn't supported on IOS14 and the
    //backport doesn't work for some reason, so we just go with
    //a @State variable for now. We have also experimented with
    //storing the mainMenuAction within a specific page set, but
    //not sure why we need this individual behaviour.
    @State
    //@AppStorage("mainMenuAction")
    var mainMenuAction: MainMenuAction?
    
    @State var selectedItems: [PhotoItem] = []
    
    //@State var navigationModel = NavigationModel()
    @StateObject private var navigationModel = NavigationModel()
    
    //@Environment(\.horizontalSizeClass) var horizontalSizeClass
    //@Environment(\.screen) var screen
    
    var body: some View {
        
        GeometryReader { geometry in
            
            let canUseSplitView = geometry.size.width > 1024
            let isSplitView = canUseSplitView && topicToEdit != nil && !isTopicSelectionMaximized
            
            if isSplitView {
                ContentViewIOS16Split(topicToEdit: $topicToEdit, appMode: $appMode, mainMenuAction: $mainMenuAction, selectedItems: $selectedItems, isTopicsMaximized: $isTopicSelectionMaximized, isSplitView: isSplitView)
            }
            else {
                makeCompactBody(isSplitView: false, canUseSplitView: canUseSplitView)
            }
        }
        .tint(.mfVeryBrightBlue)
        .if(appMode == .choiceBoard && FeatureFlags.current.voiceEnabled) { view in
            view.mutePrompt(foregroundColor: Color.mfVeryBrightBlue, backgroundColor: Color.mfLightYellow)
        }
        .environmentObject(navigationModel)
        // Board creation can replace the compact hierarchy with a split view.
        // Observe the selection here so that transition cannot lose preparation.
        .onAppear {
            // A full-screen picker also causes this view to appear again.
            // Preserve the compact navigation stack's currently edited board.
            if navigationModel.pageLayoutState == nil, let topicToEdit {
                navigationModel.prepareTopic(topicToEdit)
            }
        }
        .onChange(of: topicToEdit) { topic in
            if let topic { navigationModel.prepareTopic(topic) }
        }
    }
    
    @ViewBuilder
    func makeCompactBody(isSplitView: Bool, canUseSplitView: Bool) -> some View {
        
        makeCompactBodyIOS16(isSplitView: isSplitView, canUseSplitView: canUseSplitView)
        //makeCompactBodyIOS16 doesn't work (navigation from topic is broken)
        //makeCompactBodyIOS16(isSplitView: isSplitView)
        //makeCompactBodyIOS14(isSplitView: isSplitView)
    }
    
    func makeCompactBodyIOS14(isSplitView: Bool, canUseSplitView: Bool) -> some View {
        NavigationView {
            makeNavigationBody(isSplitView: isSplitView, canUseSplitView: canUseSplitView)
        }
        .navigationViewStyle(.stack)
        .tint(.mfVeryBrightBlue)
        .environmentObject(currentTheme)
    }
    
    func makeCompactBodyIOS16(isSplitView: Bool, canUseSplitView: Bool) -> some View {
        NavigationStack(path: $navigationModel.path) {
            makeNavigationBody(isSplitView: isSplitView, canUseSplitView: canUseSplitView)
                .navigationDestination(for: PECSRepo.self) { topic in
                    MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode, action: $mainMenuAction, selectedItems: $selectedItems, isForSplitView: isSplitView)
                }
                .navigationDestination(for: MainMenuAction.self) { action in
                    Group {
                        if action == .changeSelections {
                            navigationModel.makeDetailView(for: action, isForSplitView: isSplitView, appMode: $appMode)
                        } else {
                            navigationModel.makeDetailView(for: action, isForSplitView: isSplitView, appMode: $appMode)
                                .boardBackButton()
                        }
                    }
                    .onAppear {
                        mainMenuAction = action
                    }
                }
                // On compact devices, reopen the saved topic. A wide iPad's
                // maximized topics screen must stay at the list after relaunch.
                .onChange(of: topicToEdit) { newValue in
                    if let topic = newValue, !canUseSplitView {
                        navigationModel.setTopic(topic)
                    }
                }
            
            
        }
        .onChange(of: navigationModel.path.count) { _ in
            if navigationModel.didPopCompactAction() {
                mainMenuAction = nil
            }
        }
        //.navigationViewStyle(StackNavigationViewStyle())
        .tint(.mfVeryBrightBlue)
    }
    
    func makeNavigationBody(isSplitView: Bool, canUseSplitView: Bool) -> some View {
        VStack(spacing: 0) {
            
            if errorHandler.lastError != nil {
                ErrorView(message: errorHandler.lastError!.localizedDescription, closeAction: {
                    withAnimation {
                        errorHandler.setLastError(nil) }
                })
            }
            
            TopicSelectionView(appMode: $appMode, mainMenuAction: $mainMenuAction, topicToEdit: $topicToEdit, selectedItems: $selectedItems, isForSplitView: isSplitView, isTopicsMaximized: $isTopicSelectionMaximized, canRestoreSplitView: canUseSplitView)
            //.frame(minWidth: 0, maxWidth: AppSettings.maxViewWidth)
                .environmentObject(repoFactory)
            
            /*
             MainMenuViewOrChoiceBoardView(topic: topic)
             //Maxwidth of 400 ensures that iPhone portrait button can be full width, which looks fine,
             //but it doesn't take up the full width on wider devices like iPad because that looks odd.
             .frame(minWidth: 0, maxWidth: AppSettings.maxViewWidth)
             */
        }
        
        .frame(maxWidth: .infinity)
        //.scrollContentHideBackground()
        
        //.background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
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
