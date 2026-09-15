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
    
    
    var mainMenuViewEmptyIOS16: some View {
        EmptyView()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
    
#if AppHasTopics 
    //In the Plus verison of the App we have a three splitter panes:
    //1. Topic list
    //2. Main Menu view
    //3. Detail (e.g. photo selection screen).
    var splitViewBodyIOS16 : some View {
        NavigationSplitView(columnVisibility: $splitColumnVisibility) {
            topicSelectionView
        } content: {
            //Content view
            //mainMenuViewEmptyIOS16
            if let topic = topicToEdit {
                MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode, action: $mainMenuAction, selectedItems: $selectedItems, isForSplitView: isSplitView)
            }
            else {
                mainMenuViewEmptyIOS16
            }
        } detail: {
            detailView
        }
    }
#else
    //In the Standard verison of the App we have two splitter panes:
    //1. Main Menu view (which is facilitated by a dummy version of TopicSelectionView
    //2. Detail (e.g. photo selection screen).
    var splitViewBodyIOS16 : some View {
        NavigationSplitView(columnVisibility: $splitColumnVisibility) {
            topicSelectionView
        } detail: {
            detailView
        }
    }
#endif

    @ViewBuilder
    private var detailView: some View {
        if let mainMenuAction {
            navigationModel.makeDetailView(
                for: mainMenuAction,
                isForSplitView: isSplitView,
                appMode: $appMode
            )
        }
        else {
            EmptyView()
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
                
                TopicSelectionView(appMode: $appMode, mainMenuAction: $mainMenuAction, topicToEdit: $topicToEdit, selectedItems: $selectedItems, isForSplitView: isSplitView)
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
