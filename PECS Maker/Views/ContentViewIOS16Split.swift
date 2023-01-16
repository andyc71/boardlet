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
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    @StateObject var errorHandler = ErrorHandler.shared
    
    @Binding var topicToEdit: PECSRepo?
    @State var mainMenuAction: MainMenuAction?
    
    var isSplitView: Bool
    
    @State var splitColumnVisibility: NavigationSplitViewVisibility = .automatic
    
    @ViewBuilder
    var body: some View {
        
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
    
    
    var mainMenuViewEmptyIOS16: some View {
        EmptyView()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    var splitViewBodyIOS16 : some View {
        NavigationSplitView(columnVisibility: $splitColumnVisibility) {
            topicSelectionView
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
                
                TopicSelectionView(mainMenuAction: $mainMenuAction, topicToEdit: $topicToEdit, isForSplitView: isSplitView)
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
