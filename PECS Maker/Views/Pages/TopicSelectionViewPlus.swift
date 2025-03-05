//
//  TopicSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 13/10/2022.
//

import SwiftUI
import LogFramework
import LogFrameworkFirebase
import SharedSwiftUI
import LazyViewSwiftUI
import FeatureFramework

///Enables the user to select a topic from a list, and then displays the topic in MainMenuView. Also
///provides the option to create a new topic.
///Note that if the version of the app does not
///support multiple topics, take a look at the corresponding file TopicSelectionViewStandard.swift.
struct TopicSelectionView: View {
    
    @Binding var appMode: PECSAppMode 
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var topicToEdit: PECSRepo?
    @Binding var selectedItems: [PhotoItem] 
    var isForSplitView: Bool
    
    @EnvironmentObject private var repoFactory: PECSRepoFactory
    @EnvironmentObject var currentTheme: SharedUITheme
    @EnvironmentObject var featuresViewModel: FeaturesViewModel
    
    @StateObject private var errorHandler = ErrorHandler.shared
    
    @State private var isEditMode: Bool = false
    
    @State private var topicAction: TopicAction?
    
    //@State var newTopic: PECSRepo?
    //@State var topicToEdit: PECSRepo?
    
    
    private let gridItem = GridItem(.flexible())
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    private var columns: [GridItem] {
        
        //The sizes are based purely on what looks good for the screenshots on
        //the main supported devices.
        
        if isForSplitView {
            //One fixed-width column for split view.
            //return [GridItem(.fixed(100))]
            //As many items with min size of 100 as can fit
            return [GridItem(.adaptive(minimum: 100), spacing: 10, alignment: .top)]
        }
        else {
            if isIPad {
                //Mostly the iPad interface will be split view, but if there
                //isn't a topic selected we will get a whole-screen view of
                //the topic selection interface. Also on pre-IOS16 iPad we
                //aren't using split view.
                if repoFactory.publishedTopics.count < 18 {
                    return [GridItem(.adaptive(minimum: 200), spacing: 15, alignment: .top)]
                }
                else {
                    return [GridItem(.adaptive(minimum: 180), spacing: 15, alignment: .top)]
                }
            }
            else {
                //As many items with min size of 100 as can fit
                return [GridItem(.adaptive(minimum: 100), spacing: 10, alignment: .top)]
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
    
    init(appMode: Binding<PECSAppMode>, mainMenuAction: Binding<MainMenuAction?>, topicToEdit: Binding<PECSRepo?>, selectedItems: Binding<[PhotoItem]>, isForSplitView: Bool) {
        self._appMode = appMode
        self._mainMenuAction = mainMenuAction
        self._topicToEdit = topicToEdit
        self._selectedItems = selectedItems
        self.isForSplitView = isForSplitView
        //print("***topicName: \(topicToEdit.wrappedValue?.topicName)")
    }
    
    var body: some View {
        //bodyIOS16
        bodyIOS14
    }
    
    var isFullScreenOniPad: Bool {
        return !isForSplitView && UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    @ViewBuilder
    var newTopicButton: some View {
        StandardButton(action: {
            createTopic()
            
        }, /*systemIconName: "checkmark",*/ text: L10n.TopicSelectionView.createDesignButton, purpose: .primary)
        
    }
    
    func makeTopicCell(for topic: PECSRepo, index: Int?, isSelected: Bool) -> some View {
        NavigationLink(value: topic) {
            TopicCell(topic: topic, showDeleteButton: isEditMode, index: index)
                .padding(12)
        }
        .topicCellContextMenu(for: topic, topicAction: $topicAction)
        .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index ?? 0))
        .accessibility(label: Text(topic.topicName))
        //In splitter view we should show the currently selected topic.
        //In non-split view we don't want this because it causes the
        //selection to briefly flash on and off as we move back from
        //MainMenuView to TopicSelectionView.
        .if(isSelected && isForSplitView) { view in
            view.accessibilityAddTraits(.isSelected)
                .background(currentTheme.selectionHighlightColor)
                //.background(Color.systemFill)
                .cornerRadius(8)
        }
    }
    
    func makeNewTopicCell() -> some View {
        
        NewItemCell(text: L10n.TopicSelectionView.createDesignButton, action: {
                createTopic()
        })
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.createDesignButton1)
        .padding(12)
    }
    
    var bodyIOS14 : some View {
        ScrollView {
            
            LazyVGrid(columns: self.columns, spacing: 0) {
                
                if appMode != .choiceBoard {
                    makeNewTopicCell()
                }
                
                ForEach(repoFactory.publishedTopics, id: \.self) { topic in
                    
                    let index = repoFactory.publishedTopics.firstIndex(of: topic)
                    let isSelected = topic.id == topicToEdit?.id
                    
                    //Previously we used NavigationLinks to directly navigate, but on
                    //IOS 14.5/15.5 there seems to be a bug whereby:
                    //1) Tap doesn't work on the UI tests
                    //2) If you have exactly 2 items then tapping on the second
                    //item navigates and immediately pops back to this screen.
                    //See: https://www.hackingwithswift.com/forums/swiftui/unable-to-present-please-file-a-bug/7901/8237
                    makeTopicCell(for: topic, index: index, isSelected: isSelected)
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
            
            /*
             if !isFullScreenOniPad {
             newTopicButton
             .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.createDesignButton1)
             .padding()
             }
             */
            
            Spacer() // Make sure the topics are top-aligned.
            
        }
        .navigationBarTitle(Text(L10n.TopicSelectionView.title), displayMode: .large)
        
        .toolbar {
            if isForSplitView && topicToEdit != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    maximizeButton
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                editButton
            }
        }
        
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
        .askToDeleteTopic(topicAction: $topicAction, theme: currentTheme)
        .askToRenameTopic(topicAction: $topicAction, theme: currentTheme)
        
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //.scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Topic Selection")
            featuresViewModel.logEvent()
        }
        
    }
    
    @available(iOS 16.0, *)
    var bodyIOS16: some View {
        
        VStack {
            
            LazyVGrid(columns: self.columns, spacing: 0) {
                ForEach(repoFactory.publishedTopics, id: \.self) { topic in
                    
                    let index = repoFactory.publishedTopics.firstIndex(of: topic)
                    let isSelected = topic.id == topicToEdit?.id

                    NavigationLink(value: topic, label: {
                        TopicCell(topic: topic, showDeleteButton: isEditMode, index: index)
                        //.padding(10)
                            .topicCellContextMenu(for: topic, topicAction: $topicAction)
                    })
                    .id(UUID())
                    .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index ?? 0))
                    .accessibility(label: Text(topic.topicName))
                    .if(isSelected) { view in
                        view.accessibilityAddTraits(.isSelected)
                            .background(Color.systemFill)
                    }
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
        .askToDeleteTopic(topicAction: $topicAction, theme: currentTheme)
        .askToRenameTopic(topicAction: $topicAction, theme: currentTheme)
        
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Topic Selection")
            featuresViewModel.logEvent()
        }
        
    }
    
    @ViewBuilder
    var maximizeButton : some View {
        
        //Button to clear the selected topic, which will have the
        //effect of maximizing the topic selection pane.
        
                    Button(systemImage: .arrowUpLeftAndArrowDownRight, action: {
                        topicToEdit = nil
                    })
                    .foregroundColor(Color( currentTheme.headerStyle.textColor))
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.maximizeButton)
                    .accessibilityLabel(L10n.TopicSelectionView.maximizeButton)
    }
    
    var editButton: some View {
        
            Button(action: {
                isEditMode.toggle()
            } ) {
                //Image(systemName: "doc.badge.plus")
                //.foregroundColor(.mfBrightBlue)
                Text(isEditMode ? L10n.TopicSelectionView.doneButton : L10n.TopicSelectionView.editButton )
                    .foregroundColor(Color( currentTheme.headerStyle.textColor))
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.editButton)
        
    }
}

extension View {
    
    
    func askToDeleteTopic(topicAction: Binding<TopicAction?>, theme: SharedUITheme) -> some View {
        
        let isPresented = Binding<Bool> (
            get: { return topicAction.wrappedValue?.action == .delete },
            set: { newValue in
                if !newValue { topicAction.wrappedValue = nil }
            }
        )
        
        let topicToDelete = topicAction.wrappedValue?.topic
        let topicName = topicToDelete?.topicName ?? ""
        
        return self.askQuestionYesNo(isPresented: isPresented, title: L10n.TopicSelectionView.DeleteTopicAlert.title, message: L10n.TopicSelectionView.DeleteTopicAlert.message(topicName), isDestructive: true, theme: theme, yesAction: {
            if let topic = topicToDelete {
                PECSRepoFactory.shared.deleteTopic(topic)
            }
        }, noAction: { } )
    }
    
    func askToRenameTopic(topicAction: Binding<TopicAction?>, theme: SharedUITheme) -> some View {
        
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
        
        return self.renameItemAlert(isPresented: isPresented, itemName: topicName, placeholder: L10n.RenameTopicAlert.placeholder, title: L10n.RenameTopicAlert.title, message: nil, theme: theme, saveAction: {
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
