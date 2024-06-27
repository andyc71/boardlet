//
//  TopicSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 13/10/2022.
//

import SwiftUI
import LogFramework
import SharedSwiftUI
import LazyViewSwiftUI

///Dummy TopicSelectionView that caters for the fact that the standard version of the
///app does not support multiple topics.
///All this sceen does is to select the first (and only) available topic or ceates a new one.
///It is then simply a container for MainMenuView, which is what would be called from 
///the real TopicSelectionView when a user taps selects a topic from the list in the
///Plus version of the app. Compare TopicSelectionViewPlus.swift.
struct TopicSelectionView: View {
    
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var appMode: PECSAppMode
    @Binding var topicToEdit: PECSRepo?
    var isForSplitView: Bool
    
    @EnvironmentObject private var repoFactory: PECSRepoFactory
    
    @StateObject private var errorHandler = ErrorHandler.shared
    
    @State private var isEditMode: Bool = false
    
    @State private var topicAction: TopicAction?
    
    func createTopic() {
        do {
            //            let topic = try repoFactory.createEmptyRepo(setActive: true)
            //            DispatchQueue.main.async {
            //                self.newTopic = topic
            //            }
            
            //As a result of creating the new topic and setting it active, we
            //will end up with topicToEdit being set, which in turn will trigger
            //the navigation to the main menu screen
            if let topic = repoFactory.availableTopics.first {
                self.topicToEdit = topic
            }
            else {
                self.topicToEdit = try repoFactory.createEmptyRepo(setActive: true)
            }
        }
        catch {
            errorHandler.setLastError(error)
        }
    }
    
    init(appMode: Binding<PECSAppMode>, mainMenuAction: Binding<MainMenuAction?>, topicToEdit: Binding<PECSRepo?>, isForSplitView: Bool) {
        self._appMode = appMode
        self._mainMenuAction = mainMenuAction
        self._topicToEdit = topicToEdit
        self.isForSplitView = isForSplitView
        //print("***topicName: \(topicToEdit.wrappedValue?.topicName)")
    }
    
    @ViewBuilder
    func buildView(for topic: PECSRepo) -> some View {
        MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode, action: $mainMenuAction, selectedItems: $selectedItems, isForSplitView: isForSplitView)
    }
    
    var body: some View {
        Group {
            if let topic = topicToEdit {
                buildView(for: topic)
            }
            else {
                Text("No topic")
            }
        }
        .onAppear {
            if topicToEdit == nil {
                createTopic()
            }
        }
    }
    
}

