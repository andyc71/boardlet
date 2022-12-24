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
    @EnvironmentObject var repoFactory: PECSRepoFactory
    
    @StateObject var errorHandler = ErrorHandler.shared
    
    @State var newTopic: PECSRepo?
    @State var isEditMode: Bool = false
    
    @State var topicAction: TopicAction?
    @State var topicToEdit: PECSRepo?

    
    let gridItem = GridItem(.flexible())
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    init() {
        
    }
    
    func createTopic() {
        self.topicToEdit = nil
        let pls = PageLayoutState(topic: nil)
        DispatchQueue.main.async {
            self.newTopic = pls.topic
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
    
    var body: some View {
        
        ScrollView {
            
            LazyVGrid(columns: self.columns, spacing: 0) {
                ForEach(repoFactory.publishedTopics) { topic in
                    let index = repoFactory.publishedTopics.firstIndex(of: topic)
                    let topicView = MainMenuView(topic: topic)
                        .padding()
                        .background(Color(currentTheme.backgroundColor))
                        .ignoresSafeArea()
                    NavigationLink(
                        destination: LazyView(topicView),
                        tag: topic,
                        selection: $topicToEdit)
                    {
                        TopicCell(topic: topic, showDeleteButton: isEditMode, index: index)
                            .padding(12)
                            .topicCellContextMenu(for: topic, topicAction: $topicAction)
                    }
                    .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index ?? 0))
                    .accessibility(label: Text(topic.topicName))
                }
            }
            
            if repoFactory.publishedTopics.count == 0 {
                TipView(tipText: L10n.TopicSelectionView.noTopicsMessage, canHide: false)
                //.padding(8)
                //.listRowBackground(Color(currentTheme.backgroundColor))
            }
            
            StandardButton(action: {
                createTopic()
                
            }, /*systemIconName: "checkmark",*/ text: L10n.TopicSelectionView.createDesignButton, purpose: .primary
            )
            //.padding()
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.createDesignButton)
            
            
            if let newTopic = self.newTopic {
                
                let topicView = MainMenuView(topic: newTopic)
                    .padding()
                    .background(Color(currentTheme.backgroundColor))
                    .ignoresSafeArea()
                
                NavigationLink(destination: LazyView(topicView), tag: newTopic, selection: $newTopic) { EmptyView() }
            }
            
            
            
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
        
        var topicToRename = topicAction.wrappedValue?.topic
        
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
