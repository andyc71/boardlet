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
struct ContentViewIOS16Split: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var navigationModel: NavigationModel
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    @StateObject var errorHandler = ErrorHandler.shared
    
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @Binding var isTopicsMaximized: Bool
    
    var isSplitView: Bool
    
    @State var splitColumnVisibility: NavigationSplitViewVisibility = .automatic
    
    @ViewBuilder
    var body: some View {
        
            splitViewBodyIOS16
                .onAppear {
                    if let topicToEdit {
                        navigationModel.prepareTopic(topicToEdit)
                    }
                }
                .onChange(of: topicToEdit) { newValue in
                    if let newValue {
                        navigationModel.prepareTopic(newValue)
#if AppHasTopics
                        splitColumnVisibility = .doubleColumn
#else
                        splitColumnVisibility = .all
#endif
                    }
                    else {
                        splitColumnVisibility = .all
                    }
                }
    }
    
    
#if AppHasTopics 
    var splitViewBodyIOS16 : some View {
        NavigationSplitView(columnVisibility: $splitColumnVisibility) {
            topicSelectionView
        } detail: {
            detailView
        }
    }
#else
    var splitViewBodyIOS16 : some View {
        detailView
    }
#endif

    @ViewBuilder
    private var detailView: some View {
        NavigationStack(path: $navigationModel.splitPath) {
            Group {
                if let topic = topicToEdit {
                    MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode,
                                                  action: $mainMenuAction,
                                                  selectedItems: $selectedItems,
                                                  isForSplitView: isSplitView)
                } else {
#if AppHasTopics
                    EmptyView()
#else
                    topicSelectionView
#endif
                }
            }
            .navigationDestination(for: MainMenuAction.self) { action in
                navigationModel.makeDetailView(for: action, isForSplitView: isSplitView,
                                               appMode: $appMode, mainMenuAction: $mainMenuAction)
                    .boardBackButton()
            }
        }
    }
    
    var topicSelectionView : some View {
        ScrollView {
            VStack {
                
                if errorHandler.lastError != nil {
                    ErrorView(message: errorHandler.lastError!.localizedDescription, closeAction: {
                        withAnimation {
                            errorHandler.setLastError(nil) }
                    })
                }
                
                TopicSelectionView(appMode: $appMode, mainMenuAction: $mainMenuAction, topicToEdit: $topicToEdit, selectedItems: $selectedItems, isForSplitView: isSplitView, isTopicsMaximized: $isTopicsMaximized)
                    .environmentObject(repoFactory)
                
                
            }
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
