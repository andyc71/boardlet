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

struct TopicSelectionView: View {
    
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var topicToEdit: PECSRepo?
    var isForSplitView: Bool

    @EnvironmentObject private var repoFactory: PECSRepoFactory
    
    @StateObject private var errorHandler = ErrorHandler.shared
    
    @State private var isEditMode: Bool = false
    
    @State private var topicAction: TopicAction?

    //@State var newTopic: PECSRepo?
    //@State var topicToEdit: PECSRepo?

    
    private let gridItem = GridItem(.flexible())
    
    private var columns: [GridItem] {

        
        if isForSplitView {
            //One fixed-width column for split view.
            //return [GridItem(.fixed(100))]
            //As many items with min size of 100 as can fit
            return [GridItem(.adaptive(minimum: 100))]
        }
        else {
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                //Mostly the iPad interface will be split view, but if there
                //isn't a topic selected we will get a whole-screen view of
                //the topic selection interface. Also on pre-IOS16 iPad we
                //aren't using split view.
                //As many items with min size of 150 as can fit
                if repoFactory.publishedTopics.count <= 12 {
                    return [GridItem(.adaptive(minimum: 200))]
                }
                else {
                    return [GridItem(.adaptive(minimum: 150))]
                }
            }
            else {
                //As many items with min size of 100 as can fit
                return [GridItem(.adaptive(minimum: 100))]
            }
        }
        
        //return [GridItem(.adaptive(minimum: 100))]
    }
        
    func createTopic() {
            do {
                //            let topic = try repoFactory.createEmptyRepo(setActive: true)
                //            DispatchQueue.main.async {
                //                self.newTopic = topic
                //            }
                
                //As a result of creating the new topic and setting it active, we
                //will end up with topicToEdit being set, which in turn will trigger
                //the navigation to the main menu screen
                self.topicToEdit = try repoFactory.createEmptyRepo(setActive: true)
            }
            catch {
                errorHandler.setLastError(error)
            }
    }
    
    func duplicateTopic(_ topic: PECSRepo) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            do {
                try PECSRepoFactory.shared.duplicateTopic(repo: topic)
                //throw CocoaError(.coderInvalidValue)
            }
            catch {
                errorHandler.setLastError(error)
            }
        }
    }
    
    init(mainMenuAction: Binding<MainMenuAction?>, topicToEdit: Binding<PECSRepo?>, isForSplitView: Bool) {
        self._mainMenuAction = mainMenuAction
        self._topicToEdit = topicToEdit
        self.isForSplitView = isForSplitView
        //print("***topicName: \(topicToEdit.wrappedValue?.topicName)")
    }
    
    @ViewBuilder
    func buildView(for topic: PECSRepo) -> some View {
        MainMenuView(topic: topic, action: $mainMenuAction, isForSplitView: isForSplitView)
    }
    
    var ios16: Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        else {
            return false
        }
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            //bodyIOS16
            bodyIOS14
        }
        else {
            bodyIOS14
        }
    }
    
    var isFullScreenOniPad: Bool {
        return !isForSplitView && UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    @ViewBuilder
    var newTopicButton: some View {
        if isFullScreenOniPad {
            //Big button
            MainMenuButton(action: { createTopic() }, systemIconName: "plus.circle", text: L10n.TopicSelectionView.createDesignButton  )
        }
        else {
            
            StandardButton(action: {
                createTopic()
                
            }, /*systemIconName: "checkmark",*/ text: L10n.TopicSelectionView.createDesignButton, purpose: .primary)
        }

    }
    
    var bodyIOS14 : some View {
        
            VStack {

                newTopicButton
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.createDesignButton1)
                    .padding()

                
                LazyVGrid(columns: self.columns, spacing: 0) {
                    
                    ForEach(repoFactory.publishedTopics, id: \.self) { topic in
                        
                        let index = repoFactory.publishedTopics.firstIndex(of: topic)
                        
                        //Previously we used NavigationLinks to directly navigate, but on
                        //IOS 14.5/15.5 there seems to be a bug whereby:
                        //1) Tap doesn't work on the UI tests
                        //2) If you have exactly 2 items then tapping on the second
                        //item navigates and immediately pops back to this screen.
                        //See: https://www.hackingwithswift.com/forums/swiftui/unable-to-present-please-file-a-bug/7901/8237
                        Button(action: { self.topicToEdit = topic }) {
                            TopicCell(topic: topic, showDeleteButton: isEditMode, index: index)
                                .padding(12)
                        }
                        .topicCellContextMenu(for: topic, topicAction: $topicAction)
                        .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index ?? 0))
                        .accessibility(label: Text(topic.topicName))
                    }
                    
                    /*
                     Button(action: { createTopic() }) {
                     Text("Create")
                     }
                     .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.createDesignButton)
                     //.accessibility(label: Text(topic.topicName))
                     */
                }
                
                if repoFactory.publishedTopics.count == 0 {
                    TipView(tipText: L10n.TopicSelectionView.noTopicsMessage, canHide: false)
                    //.padding(8)
                    //.listRowBackground(Color(currentTheme.backgroundColor))
                }
                
                if !isFullScreenOniPad {
                    newTopicButton
                        .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.createDesignButton1)
                        .padding()
                }
            
            
             if let topic = topicToEdit {
                 //This causes the navigation to happen after a topic is tapped or
                 //the create button is tapped. We're setting opactity to zero because
                 //we don't need to see any resulting button. In addition, on IOS14 this
                 //button would get an accessibility identifier the same as the corresponding
                 //item in the topic list which will break the automated tests.
                 NavigationLink("", destination: buildView(for: topic), tag: topic, selection: $topicToEdit)
                     .opacity(0)
             }
                
            Spacer() // Make sure the topics are top-aligned.

            
        }
        .navigationBarTitle(Text(L10n.TopicSelectionView.title), displayMode: .inline)
        .toolbar(content: {
            Button(action: { isEditMode.toggle() } ) {
                //Image(systemName: "doc.badge.plus")
                //.foregroundColor(.mfBrightBlue)
                Text(isEditMode ? L10n.TopicSelectionView.doneButton : L10n.TopicSelectionView.editButton )
                    .foregroundColor(Color( currentTheme.headerStyle.textColor))
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.editButton)
        })
        
        .onChange(of: topicAction) { newValue in
            guard let topicAction = newValue else {return}
            switch topicAction.action {
            case .view:
                topicToEdit = topicAction.topic
                self.topicAction = nil
            case .duplicate:
                duplicateTopic(topicAction.topic)
                self.topicAction = nil
                return
            case .rename:
                return //Handled by askToRename
            case .delete:
                return //Handled by askToDelete
            }
        }
        .askToDeleteTopic(topicAction: $topicAction)
        .askToRenameTopic(topicAction: $topicAction)
        
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Topic Selection")
        }
        
    }
    
    @available(iOS 16.0, *)
    var bodyIOS16: some View {
        
        VStack {
            
            LazyVGrid(columns: self.columns, spacing: 0) {
                ForEach(repoFactory.publishedTopics, id: \.self) { topic in
                    
                    let index = repoFactory.publishedTopics.firstIndex(of: topic)
                    
                    //Previously we used NavigationLinks to directly navigate, but on
                    //IOS 14.5/15.5 there seems to be a bug whereby:
                    //1) Tap doesn't work on the UI tests
                    //2) If you have exactly 2 items then tapping on the second
                    //item navigates and immediately pops back to this screen.
                    //See: https://www.hackingwithswift.com/forums/swiftui/unable-to-present-please-file-a-bug/7901/8237
                    NavigationLink(value: topic, label: {
                        TopicCell(topic: topic, showDeleteButton: isEditMode, index: index)
                            .padding(12)
                            .topicCellContextMenu(for: topic, topicAction: $topicAction)
                    })
                    .id(UUID())
                    .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index ?? 0))
                    .accessibility(label: Text(topic.topicName))
                }

                Button(action: { createTopic() }) {
                    Text(L10n.TopicSelectionView.createDesignButton)
                }
                .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.createDesignButton1)
                //.accessibility(label: Text(topic.topicName))
            }
            
            if repoFactory.publishedTopics.count == 0 {
                TipView(tipText: L10n.TopicSelectionView.noTopicsMessage, canHide: false)
                //.padding(8)
                //.listRowBackground(Color(currentTheme.backgroundColor))
            }

            /*
            StandardButton(action: {
                createTopic()
                
            }, /*systemIconName: "checkmark",*/ text: L10n.TopicSelectionView.createDesignButton, purpose: .primary)
            //.padding()
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.createDesignButton)
             */
            
            
        }
        .navigationDestination(for: PECSRepo.self) { topic in
            buildView(for: topic)
        }
        .navigationBarTitle(Text(L10n.TopicSelectionView.title), displayMode: .inline)
        .toolbar(content: {
            Button(action: { isEditMode.toggle() } ) {
                //Image(systemName: "doc.badge.plus")
                //.foregroundColor(.mfBrightBlue)
                Text(isEditMode ? L10n.TopicSelectionView.doneButton : L10n.TopicSelectionView.editButton )
                    .foregroundColor(Color( currentTheme.headerStyle.textColor))
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.editButton)
        })
        
        .onChange(of: topicAction) { newValue in
            guard let topicAction = newValue else {return}
            switch topicAction.action {
            case .view:
                topicToEdit = topicAction.topic
                self.topicAction = nil
            case .duplicate:
                duplicateTopic(topicAction.topic)
                self.topicAction = nil
                return
            case .rename:
                return //Handled by askToRename
            case .delete:
                return //Handled by askToDelete
            }
        }
        .askToDeleteTopic(topicAction: $topicAction)
        .askToRenameTopic(topicAction: $topicAction)
        
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Topic Selection")
        }
        
    }
}

extension View {
    
    
    func askToDeleteTopic(topicAction: Binding<TopicAction?>) -> some View {
        
        let isPresented = Binding<Bool> (
            get: { return topicAction.wrappedValue?.action == .delete },
            set: { newValue in
                if !newValue { topicAction.wrappedValue = nil }
            }
        )
        
        let topicToDelete = topicAction.wrappedValue?.topic
        let topicName = topicToDelete?.topicName ?? ""
        
        return self.askQuestionYesNo(isPresented: isPresented, title: L10n.TopicSelectionView.DeleteTopicAlert.title, message: L10n.TopicSelectionView.DeleteTopicAlert.message(topicName), isDestructive: true, yesAction: {
            if let topic = topicToDelete {
                PECSRepoFactory.shared.deleteTopic(topic)
            }
        }, noAction: { } )
    }

    func askToRenameTopic(topicAction: Binding<TopicAction?>) -> some View {
        
        let isPresented = Binding<Bool> (
            get: { return topicAction.wrappedValue?.action == .rename },
            set: { newValue in
                if !newValue { topicAction.wrappedValue = nil }
            }
        )
        
        let topicName = Binding<String> (
            get: {
                guard let topic = topicAction.wrappedValue?.topic else { return "" }
                return topic.topicName
            },
            set: { newValue in
                guard let topic = topicAction.wrappedValue?.topic else { return }
                topic.topicName = newValue
            }
        )
        
        let topicToRename = topicAction.wrappedValue?.topic
        
        return self.renameItemAlert(isPresented: isPresented, itemName: topicName, placeholder: L10n.RenameTopicAlert.placeholder, title: L10n.RenameTopicAlert.title, message: nil, saveAction: {
            guard let topicToRename = topicToRename else { return }
            try? topicToRename.saveToFile()
        })
    }
    

}


struct TopicSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        //TopicSelectionView()
        Text("TO DO")
    }
}
