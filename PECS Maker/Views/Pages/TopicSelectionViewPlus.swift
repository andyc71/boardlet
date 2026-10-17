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
    
    @AppStorage(InterfaceStyle.storageKey) private var interfaceStyle = InterfaceStyle.defaultValue

    @Binding var appMode: PECSAppMode 
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var topicToEdit: PECSRepo?
    @Binding var selectedItems: [PhotoItem] 
    @Binding var isTopicsMaximized: Bool
    var isForSplitView: Bool
    var canRestoreSplitView: Bool
    var onTopicSelected: (() -> Void)?
    
    @EnvironmentObject private var repoFactory: PECSRepoFactory
    @EnvironmentObject var currentTheme: SharedUITheme
    @EnvironmentObject var featuresViewModel: FeaturesViewModel
    @EnvironmentObject var navigationModel: NavigationModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @StateObject private var errorHandler = ErrorHandler.shared
    
    @State private var isSelectionMode: Bool = false
    @State private var selectedTopicIDs: Set<UUID> = []
    @State private var showDeleteSelectionAlert = false
    
    @State private var topicAction: TopicAction?
    @State private var topicToRename: PECSRepo?
    @State private var showRecommended = false
    
    //@State var newTopic: PECSRepo?
    //@State var topicToEdit: PECSRepo?
    
    
    private let gridItem = GridItem(.flexible())
    
    private var showsNewBoardAction: Bool {
        !isSelectionMode && (appMode != .choiceBoard || !FeatureFlags.current.voiceEnabled)
    }

    private var allTopicsAreSelected: Bool {
        !repoFactory.publishedTopics.isEmpty
            && repoFactory.publishedTopics.allSatisfy { selectedTopicIDs.contains($0.id) }
    }

    private var deleteSelectionMessage: String {
        selectedTopicIDs.count == 1
            ? L10n.TopicSelectionView.DeleteSelectionAlert.oneMessage
            : L10n.TopicSelectionView.DeleteSelectionAlert.manyMessage(selectedTopicIDs.count)
    }
    
    private var columns: [GridItem] {
        let minimum: CGFloat = dynamicTypeSize.isAccessibilitySize ? 180 : 120
        return [GridItem(.adaptive(minimum: minimum), spacing: 12, alignment: .top)]
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
            let topic = try repoFactory.createEmptyRepo(setActive: true)
            self.topicToEdit = topic
            if isTopicsMaximized && canRestoreSplitView {
                navigationModel.setTopic(topic)
            }
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
    
    init(appMode: Binding<PECSAppMode>, mainMenuAction: Binding<MainMenuAction?>, topicToEdit: Binding<PECSRepo?>, selectedItems: Binding<[PhotoItem]>, isForSplitView: Bool, isTopicsMaximized: Binding<Bool> = .constant(false), canRestoreSplitView: Bool = false, onTopicSelected: (() -> Void)? = nil) {
        self._appMode = appMode
        self._mainMenuAction = mainMenuAction
        self._topicToEdit = topicToEdit
        self._selectedItems = selectedItems
        self._isTopicsMaximized = isTopicsMaximized
        self.isForSplitView = isForSplitView
        self.canRestoreSplitView = canRestoreSplitView
        self.onTopicSelected = onTopicSelected
        //print("***topicName: \(topicToEdit.wrappedValue?.topicName)")
    }
    
    private func selectTopic(_ topic: PECSRepo) {
        topicToEdit = topic
        navigationModel.setTopic(topic)
        onTopicSelected?()
    }

    func makeTopicCell(for topic: PECSRepo, index: Int?, isCurrentTopic: Bool) -> some View {
        let isSelected = selectedTopicIDs.contains(topic.id)

        return Button(action: {
            if isSelectionMode {
                toggleSelection(for: topic)
            } else {
                selectTopic(topic)
            }
        }) {
            ZStack {
                TopicCell(topic: topic, showDeleteButton: false, index: index)
                .padding(12)
                if isSelected {
                    Color.accentColor.opacity(0.18)
                        .cornerRadius(8)
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
        }
        .topicCellContextMenu(for: topic, topicAction: $topicAction)
        .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index ?? 0))
        .accessibility(label: Text(topic.topicName))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .draggable(topic.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let value = items.first, let id = UUID(uuidString: value) else { return false }
            return repoFactory.moveTopic(id: id, to: topic.id)
        }
        .accessibilityAction(named: Text(L10n.TopicSelectionView.moveEarlier)) {
            repoFactory.moveTopic(id: topic.id, by: -1)
        }
        .accessibilityAction(named: Text(L10n.TopicSelectionView.moveLater)) {
            repoFactory.moveTopic(id: topic.id, by: 1)
        }
        .if(isCurrentTopic && isForSplitView && !isSelectionMode) { view in
            view.accessibilityAddTraits(.isSelected)
                .background(Color.mfVeryBrightBlue.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.mfVeryBrightBlue, lineWidth: 1.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
    }
    
    var body: some View {
        ScrollView {
            
            LazyVGrid(columns: self.columns, spacing: 0) {
                ForEach(repoFactory.publishedTopics) { topic in
                    
                    let index = repoFactory.publishedTopics.firstIndex(of: topic)
                    let isCurrentTopic = topic.id == topicToEdit?.id
                    
                    makeTopicCell(for: topic, index: index, isCurrentTopic: isCurrentTopic)
                }
            }
            
            if repoFactory.publishedTopics.count == 0 {
                TipView(tipText: L10n.TopicSelectionView.noTopicsMessage, canHide: false)
                //.padding(8)
                //.listRowBackground(Color(currentTheme.backgroundColor))
            }
            
            Spacer() // Make sure the topics are top-aligned.
            
        }
        .navigationBarTitle(Text(L10n.TopicSelectionView.title), displayMode: .inline)
        
        .toolbar {
            if isSelectionMode {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(allTopicsAreSelected
                           ? L10n.TopicSelectionView.deselectAllButton
                           : L10n.TopicSelectionView.selectAllButton,
                           action: toggleAllTopicsSelection)
                    .disabled(repoFactory.publishedTopics.isEmpty)
                    .accessibilityIdentifier(allTopicsAreSelected
                                             ? AccessibilityIdentifiers.TopicSelectionView.deselectAllButton
                                             : AccessibilityIdentifiers.TopicSelectionView.selectAllButton)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.TopicSelectionView.doneButton, action: exitSelectionMode)
                        .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.closeSelectionButton)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(role: .destructive) {
                        showDeleteSelectionAlert = true
                    } label: {
                        Label(L10n.TopicSelectionView.deleteButton, systemImage: "trash")
                    }
                    .disabled(selectedTopicIDs.isEmpty)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.deleteSelectionButton)
                    Spacer()
                }
            } else {
                if isTopicsMaximized && canRestoreSplitView && !repoFactory.publishedTopics.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        restoreSplitViewButton
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        selectButton
                        Divider()
                        Button(L10n.MainMenu.settingsButton, systemImage: "gear") {
                            MFAnalytics.logScreenView(screenName: MainMenuAction.settings.rawValue)
                            featuresViewModel.logEvent()
                            navigationModel.setMainMenuAction(.settings)
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.settingsButton)
                        Button(L10n.MainMenu.moreAppsButton, systemImage: "app.gift") {
                            MFAnalytics.logScreenView(screenName: "MoreApps")
                            featuresViewModel.logEvent()
                            showRecommended = true
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.moreAppsButton)
                    } label: {
                        Label(L10n.MainMenu.moreOptions, systemImage: "ellipsis")
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel(L10n.MainMenu.moreOptions)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.menuButton)
                }
                
                if appMode == .choiceBoard && FeatureFlags.current.voiceEnabled {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(L10n.TopicSelectionView.designBoardsButton,
                               systemImage: "square.grid.2x2") {
                            withAnimation {
                                appMode = .pecsMaker
                            }
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.designBoardsButton)
                    }
                }
            }
        }
        .overlay {
            StoreView(storeItemID: AppSettings.shared.developerID,
                      dismissHandler: { showRecommended = false })
                .hidden(!showRecommended)
        }
        
        .onChange(of: topicAction) { newValue in
            guard let topicAction = newValue else {return}
            switch topicAction.action {
            case .view:
                selectTopic(topicAction.topic)
                self.topicAction = nil
            case .duplicate:
                duplicateTopic(topicAction.topic)
                self.topicAction = nil
                return
            case .rename:
                topicToRename = topicAction.topic
                self.topicAction = nil
                return
            case .delete:
                return //Handled by askToDelete
            }
        }
        .askToDeleteTopic(topicAction: $topicAction, theme: currentTheme)
        .sheet(item: $topicToRename) { topic in
            TopicRenameSheet(topic: topic,
                             currentPageLayoutState: navigationModel.pageLayoutState)
        }
        .alert(L10n.TopicSelectionView.DeleteSelectionAlert.title,
               isPresented: $showDeleteSelectionAlert) {
            Button(L10n.PhotoSelectionView.deleteAction, role: .destructive,
                   action: deleteSelectedTopics)
            Button(L10n.PhotoZoomView.cancelButton, role: .cancel) { }
        } message: {
            Text(deleteSelectionMessage)
        }
        
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(NewBoardSafeAreaBar(isVisible: showsNewBoardAction, action: createTopic))
        //.scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Topic Selection")
            featuresViewModel.logEvent()
        }
        .onDisappear(perform: exitSelectionMode)
        
    }
    
    var restoreSplitViewButton: some View {
        Button(action: {
            // A previous version cleared the active topic when maximizing.
            // Select an existing topic so those installations can restore too.
            if topicToEdit == nil {
                topicToEdit = repoFactory.publishedTopics.first
            }
            isTopicsMaximized = false
        }) {
            Image(systemName: "sidebar.left")
        }
        .foregroundColor(Color(currentTheme.headerStyle.textColor))
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.restoreSplitViewButton)
        .accessibilityLabel(L10n.TopicSelectionView.showSidebarButton)
    }
    
    var selectButton: some View {
        Button(L10n.TopicSelectionView.selectButton, systemImage: "checkmark.circle") {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSelectionMode = true
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.selectButton)
    }

    private func toggleSelection(for topic: PECSRepo) {
        withAnimation(.easeInOut(duration: 0.16)) {
            if selectedTopicIDs.contains(topic.id) {
                selectedTopicIDs.remove(topic.id)
            } else {
                selectedTopicIDs.insert(topic.id)
            }
        }
    }

    private func toggleAllTopicsSelection() {
        withAnimation(.easeInOut(duration: 0.16)) {
            selectedTopicIDs = allTopicsAreSelected
                ? []
                : Set(repoFactory.publishedTopics.map(\.id))
        }
    }

    private func exitSelectionMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSelectionMode = false
            selectedTopicIDs.removeAll()
        }
    }

    private func deleteSelectedTopics() {
        let deletesAllTopics = allTopicsAreSelected
        let topics = repoFactory.publishedTopics.filter { selectedTopicIDs.contains($0.id) }
        topics.forEach(repoFactory.deleteTopic)
        if deletesAllTopics {
            exitSelectionMode()
        } else {
            selectedTopicIDs.removeAll()
        }
    }
}

private struct NewBoardActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(L10n.TopicSelectionView.createDesignButton, systemImage: "plus")
                .font(.headline)
                .frame(minWidth: 160)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 5)
        }
        .controlSize(.regular)
        .accessibilityLabel(L10n.TopicSelectionView.createDesignButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.createDesignButton1)
    }
}

private struct NewBoardSafeAreaBar: ViewModifier {
    let isVisible: Bool
    let action: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .bottom) {
                if isVisible {
                    NewBoardActionButton(action: action)
                        .buttonStyle(.glassProminent)
                }
            }
        } else {
            content.safeAreaInset(edge: .bottom) {
                if isVisible {
                    NewBoardActionButton(action: action)
                        .buttonStyle(.borderedProminent)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

extension View {
    
    
    func askToDeleteTopic(topicAction: Binding<TopicAction?>, theme: SharedUITheme) -> some View {
        modifier(TopicDeleteAlertModifier(topicAction: topicAction))
    }
    
}

private struct TopicDeleteAlertModifier: ViewModifier {
    @Binding var topicAction: TopicAction?

    func body(content: Content) -> some View {
        content.alert(L10n.TopicSelectionView.DeleteTopicAlert.title,
                      isPresented: Binding(
                        get: { topicAction?.action == .delete },
                        set: { if !$0 { topicAction = nil } }
                      )) {
            Button(L10n.PhotoSelectionView.deleteAction, role: .destructive) {
                guard let topic = topicAction?.topic else { return }
                PECSRepoFactory.shared.deleteTopic(topic)
                topicAction = nil
            }
            Button(L10n.PhotoZoomView.cancelButton, role: .cancel) { topicAction = nil }
        } message: {
            Text(L10n.TopicSelectionView.DeleteTopicAlert.message(topicAction?.topic.topicName ?? ""))
        }
    }
}

private struct TopicRenameSheet: View {
    @StateObject private var pageLayoutState: PageLayoutState

    init(topic: PECSRepo, currentPageLayoutState: PageLayoutState?) {
        let state: PageLayoutState
        if let currentPageLayoutState, currentPageLayoutState.topic.id == topic.id {
            state = currentPageLayoutState
        } else {
            state = PageLayoutState(topic: topic)
        }
        _pageLayoutState = StateObject(wrappedValue: state)
    }

    var body: some View {
        NavigationStack {
            PhotoCellZoomed(pageLayoutState: pageLayoutState,
                            photo: .constant(nil), onDelete: { _ in },
                            isBoardDetails: true,
                            boardDetailsTitle: L10n.TopicSelectionView.renameTopicButton)
        }
    }
}


struct TopicSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        //TopicSelectionView()
        Text("TO DO")
    }
}
