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
    }
    
    
    var mainMenuViewEmptyIOS16: some View {
        EmptyView()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    var splitViewBodyIOS16 : some View {
        NavigationSplitView(columnVisibility: $splitColumnVisibility) {
            
            if let topic = topicToEdit {
                MainMenuView(topic: topic, action: $mainMenuAction, isForSplitView: isSplitView)
            }
            else {
                mainMenuViewEmptyIOS16
            }
        }
        detail: {
            EmptyView()
        }
    }

}


