//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine
import SharedSwiftUI

@available(iOS 16.0, *)
struct ContentViewIOS16: View {
    
    //MARK: App Restoration
    @Environment(\.scenePhase)var scenePhase: ScenePhase
    static let productUserActivityType = "com.brightblue.EasyPECS.PageLayoutState"
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    //@StateObject var pageLayoutState = PageLayoutState()
    @StateObject var errorHandler = ErrorHandler.shared
    
    @State var newTopic: PECSRepo?
    @Binding var topicToEdit: PECSRepo?
    @State var mainMenuAction: MainMenuAction?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.screen) var screen
    
    var isSplitView: Bool {
        horizontalSizeClass != .compact && screen.width >= 1024
    }
    
    @State var splitColumnVisibility: NavigationSplitViewVisibility = .automatic
    
    @ViewBuilder
    var body: some View {
        
        if topicToEdit == nil {
            NavigationStack {
                navigationBody
            }
        }
        else {
            splitViewBodyIOS16
                .onChange(of: topicToEdit) { newValue in
                    if newValue == nil {
                        splitColumnVisibility = .all
                    }
                    else {
                        splitColumnVisibility = .doubleColumn
                    }
                    
                }
        }
    }
    
    
    var mainMenuViewEmptyIOS16: some View {
        EmptyView()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    var splitViewBodyIOS16 : some View {
        NavigationSplitView(columnVisibility: $splitColumnVisibility) {
            navigationBody
        } content: {
            //Content view
            //mainMenuViewEmptyIOS16
            if let topic = topicToEdit {
                MainMenuView(topic: topic, action: $mainMenuAction, isForSplitView: isSplitView)
            }
            else {
                mainMenuViewEmptyIOS16
            }
        } detail: {
            /*
             if let topic = topicToEdit {
             if let mainMenuAction = mainMenuAction {
             MainMenuView.makeDetailView(for: mainMenuAction, pageLayoutState: PageLayoutState(topic: topic), selection: $mainMenuAction)
             }
             else {
             EmptyView()
             }
             }
             else {
             EmptyView()
             }
             */
            EmptyView()
        }
    }
    
    
    var navigationBody : some View {
        VStack {
            
            if errorHandler.lastError != nil {
                ErrorView(message: errorHandler.lastError!.localizedDescription, closeAction: {
                    withAnimation {
                        errorHandler.setLastError(nil) }
                })
            }
            
            TopicSelectionView(mainMenuAction: $mainMenuAction, topicToEdit: $topicToEdit, isForSplitView: isSplitView)
                .environmentObject(repoFactory)
            
            
        }
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
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
