//
//  TopicSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 13/10/2022.
//

import SwiftUI
import BoardLibrary
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
    @State private var showDuplicateSelectionAlert = false
    @State private var showDuplicateSuccessAlert = false
    @State private var duplicatedTopicCount = 0
    @State private var draggedTopicID: UUID?
    
    @State private var topicAction: TopicAction?
    @State private var topicToRename: PECSRepo?
    @State private var showRecommended = false
    @State private var showLayout = false
    @State private var showSearch = false
    @State private var viewportSize = CGSize.zero
    private var viewportWidth: CGFloat { viewportSize.width }
    @AppStorage("topicScreenLayout") private var layoutData = Data()
    @AppStorage("topicScreenRecommendedLayout") private var recommendationID = ""
    @AppStorage("topicScreenCustomCardWidth") private var customCardWidth = 100.0

    @AppStorage("topicScreenCustomCardAspectRatio") private var customCardAspectRatio = 0.0

    private var recommendation: TopicLayoutRecommendation? {
        TopicLayoutRecommendation(rawValue: recommendationID)
    }

    private var selectedLayout: PageLayoutType? {
        guard let layout = try? JSONDecoder().decode(PageLayoutType.self, from: layoutData),
              (1...PageLayoutType.maxColumns).contains(layout.width),
              (1...PageLayoutType.maxRows).contains(layout.height) else { return nil }
        return layout
    }

    private var topicGridGeometry: ScreenCardGridGeometry {
        let aspectRatio: CGFloat
        if let recommendation {
            aspectRatio = recommendation.aspectRatio
        } else if let layout = selectedLayout {
            let previewSize = PageLayout.cardSize(
                pageSize: PageMeasurements2.forSize(.a4, orientation: .portrait), pageLayout: layout)
            aspectRatio = customCardAspectRatio > 0 ? customCardAspectRatio : previewSize.width / previewSize.height
        } else {
            aspectRatio = 1
        }
        let columns = selectedColumnCount
        let rows = max(1, (repoFactory.publishedTopics.count + columns - 1) / columns)
        if let layout = selectedLayout {
            // The shared page fitter reserves 8 points per side; topics reserve 20.
            let fittingViewport = CGSize(width: viewportWidth - 24, height: viewportSize.height)
            return ScreenCardGridGeometry.fittingPage(layout, in: fittingViewport,
                cardAspectRatio: aspectRatio, spacing: 12).withRows(rows)
        }
        return .fillingWidth(viewportWidth, columns: columns, rows: rows, cardAspectRatio: aspectRatio)
    }

    private var fittedCardSize: CGSize? {
        recommendation != nil || selectedLayout != nil ? topicGridGeometry.cardSize : nil
    }

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

    private var duplicateSelectionMessage: String {
        selectedTopicIDs.count == 1
            ? L10n.TopicSelectionView.DuplicateSelectionAlert.oneMessage
            : L10n.TopicSelectionView.DuplicateSelectionAlert.manyMessage(selectedTopicIDs.count)
    }

    private var duplicateSuccessMessage: String {
        duplicatedTopicCount == 1
            ? L10n.TopicSelectionView.DuplicateSuccessAlert.oneMessage
            : L10n.TopicSelectionView.DuplicateSuccessAlert.manyMessage(duplicatedTopicCount)
    }

    private var appTitle: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? L10n.TopicSelectionView.title
    }
    
    private var selectedColumnCount: Int {
        if let selectedLayout { return selectedLayout.width }
        if let recommendation {
            return recommendation.columns(in: viewportWidth, accessibility: dynamicTypeSize.isAccessibilitySize)
        }
        let preferredWidth = dynamicTypeSize.isAccessibilitySize ? 180.0 : 100.0
        return TopicLayoutRecommendation.columns(in: viewportWidth, preferredWidth: preferredWidth)
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
            topic.offersSuggestionsAfterNaming = true
            try topic.saveToFile()
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
        Task { @MainActor in
            do {
                try await PECSRepoFactory.shared.duplicateTopic(repo: topic)
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
    
    private func performSummaryAction(_ summary: BoardSummary, _ action: TopicAction.Action) {
        do { topicAction = TopicAction(try repoFactory.open(summary), action) } catch { errorHandler.setLastError(error) }
    }

    private func selectTopic(_ topic: PECSRepo) {
        topicToEdit = topic
        navigationModel.setTopic(topic)
        onTopicSelected?()
    }

    func makeTopicCell(for topic: BoardSummary, index: Int?, isCurrentTopic: Bool) -> some View {
        let isSelected = selectedTopicIDs.contains(topic.id)

        return Button(action: {
            if isSelectionMode {
                toggleSelection(for: topic)
            } else {
                do { selectTopic(try repoFactory.open(topic)) } catch { errorHandler.setLastError(error) }
            }
        }) {
            BoardSummaryCell(summary: topic, size: fittedCardSize, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(L10n.TopicContextMenu.editButton) { performSummaryAction(topic, .view) }.accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.editButton)
            Button(L10n.TopicContextMenu.renameButton) { performSummaryAction(topic, .rename) }.accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.renameButton)
            Button(L10n.TopicContextMenu.duplicate) { performSummaryAction(topic, .duplicate) }.accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.duplicateButton)
            Button(L10n.TopicContextMenu.deleteButton, role: .destructive) { performSummaryAction(topic, .delete) }.accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.deleteButton)
        }
        .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index ?? 0))
        .accessibility(label: Text(topic.topicName))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onDrag {
            draggedTopicID = topic.id
            return TopicReorderDropDelegate.itemProvider(for: topic.id)
        }
        .onDrop(of: [TopicReorderDropDelegate.typeIdentifier],
                delegate: TopicReorderDropDelegate(targetID: topic.id,
                                                   draggedTopicID: $draggedTopicID,
                                                   repoFactory: repoFactory))
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
    
    private var topicScrollView: some View {
        ScrollView(topicGridGeometry.pageSize.width + 40 > viewportWidth + 0.5 ? [.horizontal, .vertical] : .vertical) {
            VStack {
                if repoFactory.isIndexing { ProgressView("Indexing — results may be incomplete") }
                if !repoFactory.diagnostics.isEmpty {
                    Text(repoFactory.diagnostics.joined(separator: "\n")).font(.caption).foregroundStyle(.secondary)
                }
                if !repoFactory.publishedTopics.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(topicGridGeometry.cardSize.width), spacing: topicGridGeometry.spacing), count: topicGridGeometry.columns), spacing: topicGridGeometry.spacing) {
                        ForEach(Array(repoFactory.publishedTopics.enumerated()), id: \.element.id) { index, topic in
                            makeTopicCell(for: topic, index: index, isCurrentTopic: topic.id == topicToEdit?.id)
                                .frame(width: topicGridGeometry.cardSize.width,
                                       height: fittedCardSize == nil ? nil : topicGridGeometry.cardSize.height)
                        }
                    }
                    .frame(width: topicGridGeometry.pageSize.width)
                }

                if repoFactory.publishedTopics.isEmpty {
                    TipView(tipText: L10n.TopicSelectionView.noTopicsMessage, canHide: false)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("TopicSelectionView.gridScrollView")
    }

    var body: some View {
        Color.clear
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
        .overlay { topicScrollView }
        .sheet(isPresented: $showLayout) {
            NavigationStack {
                TopicLayoutSelectionView(layoutData: $layoutData,
                                         recommendationID: $recommendationID,
                                         customCardWidth: $customCardWidth,
                                         customCardAspectRatio: $customCardAspectRatio,
                                         viewportSize: viewportSize)
            }
        }
        .navigationBarTitle(Text(appTitle), displayMode: .inline)
        
        .sheet(isPresented: $showSearch) { BoardSearchView { repo, card in
            showSearch = false
            selectTopic(repo)
            if let card { navigationModel.revealCard(card) }
        } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { Button("Search", systemImage: "magnifyingglass") { showSearch = true } }
            if isSelectionMode {
                            
                //Exit Selection mode.
                let doneButtonPlacement: ToolbarItemPlacement = isForSplitView && !isTopicsMaximized ? ToolbarItemPlacement.topBarLeading : ToolbarItemPlacement.topBarTrailing
                DoneToolbarItem(placement: doneButtonPlacement, id: AccessibilityIdentifiers.TopicSelectionView.closeSelectionButton) { exitSelectionMode() }
                
                //Select all
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
                
                //Duplicate and delete.
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(L10n.PhotoSelectionView.duplicateAction,
                           systemImage: "doc.on.doc") {
                        showDuplicateSelectionAlert = true
                    }
                    .disabled(selectedTopicIDs.isEmpty)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.duplicateSelectionButton)
                    
                }
                
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                }

                ToolbarItemGroup(placement: .bottomBar) {

                    Button(role: .destructive) {
                        showDeleteSelectionAlert = true
                    } label: {
                        Label(L10n.TopicSelectionView.deleteButton, systemImage: "trash")
                    }
                    .disabled(selectedTopicIDs.isEmpty)
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.deleteSelectionButton)
                }
                
            } else {

                if isTopicsMaximized && canRestoreSplitView && !repoFactory.publishedTopics.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        restoreSplitViewButton
                    }
                }

                let moreMenuPlacement = isForSplitView && !isTopicsMaximized ? ToolbarItemPlacement.topBarLeading : ToolbarItemPlacement.topBarTrailing
                ToolbarItemGroup(placement: moreMenuPlacement) {
                    Menu {
                        selectButton
                        Button(L10n.PhotoSelectionView.layoutAction, systemImage: "square.grid.2x2") {
                            showLayout = true
                        }
                        .accessibilityIdentifier("TopicSelectionView.layoutButton")
                        maximizeButton
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
        .alert(L10n.TopicSelectionView.DuplicateSelectionAlert.title,
               isPresented: $showDuplicateSelectionAlert) {
            Button(L10n.PhotoSelectionView.duplicateAction, action: duplicateSelectedTopics)
            Button(L10n.PhotoZoomView.cancelButton, role: .cancel) { }
        } message: {
            Text(duplicateSelectionMessage)
        }
        .alert(L10n.TopicSelectionView.DuplicateSuccessAlert.title,
               isPresented: $showDuplicateSuccessAlert) {
            Button(L10n.PhotoZoomView.closeButton, role: .cancel) { }
        } message: {
            Text(duplicateSuccessMessage)
        }
        
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(NewBoardSafeAreaBar(isVisible: showsNewBoardAction, action: createTopic))
        //.scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Topic Selection")
            featuresViewModel.logEvent()
        }
        .onDisappear(perform: exitSelectionMode)
        .onDisappear { draggedTopicID = nil }
        
    }
    
    var restoreSplitViewButton: some View {
        Button(action: {
            // A previous version cleared the active topic when maximizing.
            // Select an existing topic so those installations can restore too.
            if topicToEdit == nil {
                topicToEdit = repoFactory.publishedTopics.first.flatMap { try? repoFactory.open($0) }
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
    
    @ViewBuilder
    var maximizeButton: some View {
        if isForSplitView && !isTopicsMaximized {
                Button {
                    isTopicsMaximized = true
                } label: {
                    Label(L10n.TopicSelectionView.maximizeButton,
                          systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.maximizeButton)
        }
    }

    private func toggleSelection(for topic: BoardSummary) {
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

    private func duplicateSelectedTopics() {
        let topics = repoFactory.publishedTopics.filter { selectedTopicIDs.contains($0.id) }
        guard !topics.isEmpty else { return }
        // Let the confirmation dismiss before presenting the result or an error.
        Task { @MainActor in
            do {
                for topic in topics {
                    try await repoFactory.duplicateTopic(repo: topic)
                }
                duplicatedTopicCount = topics.count
                showDuplicateSuccessAlert = true
            } catch {
                errorHandler.setLastError(error)
            }
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
