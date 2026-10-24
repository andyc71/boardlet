//
//  PhotoListView.swift
//  PECS Maker
//
//  Created by Andy on 18/12/2022.
//

import SwiftUI
import PhotosUI
import LogFramework
import LogFrameworkFirebase
import SharedSwiftUI
import SFSafeSymbols

struct PhotoListView2: View, PhotoCellActionDelegate {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationModel: NavigationModel
    @EnvironmentObject private var presentationContext: ScenePresentationContext
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @ObservedObject var pageLayoutState: PageLayoutState
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    var isForSplitView: Bool

    @State var showTopicSelectionAlert: Bool = false
    @State var showDeleteSelectionAlert: Bool = false
    @State var showPhotoCopySuccessAlert: Bool = false
    @State private var showDuplicateSelectionAlert = false
    @State private var showDuplicateSuccessAlert = false
    @State private var duplicatedPhotoCount = 0
    @State var showDVSymbolsPicker: Bool = false
#if EasyPECSPlus
    @State private var showAACStandardSymbolsPicker = false
#endif
    @State private var showARASAACSymbolsPicker: Bool = false
    @State var showAISymbolsPicker: Bool = false
    
    @State private var showFormatting = false
    @State private var layoutPath: [AppRoute] = []
    @State private var showLayout = false
    @State private var showBoardDetails = false
    @State private var showInspiration = false
    @State private var isLandscape = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var selectedPhotoIDs: Set<UUID> {
        get { navigationModel.selectedPhotoIDs }
        nonmutating set { navigationModel.selectedPhotoIDs = newValue }
    }

    private var isSelectionMode: Bool {
        get { navigationModel.isPhotoSelectionMode }
        nonmutating set { navigationModel.isPhotoSelectionMode = newValue }
    }

    private var selectablePhotos: [PhotoItem] {
        pageLayoutState.photoBrowserData.photoItems.filter { !$0.isPlaceholder }
    }

    private var selectedPhotos: [PhotoItem] {
        selectablePhotos.filter { selectedPhotoIDs.contains($0.itemID) }
    }

    private var allPhotosAreSelected: Bool {
        !selectablePhotos.isEmpty && selectablePhotos.allSatisfy { selectedPhotoIDs.contains($0.itemID) }
    }

    private var boardIsEmpty: Bool {
        pageLayoutState.photoBrowserData.photoItems.isEmpty
    }

    @State var itemToDelete: PhotoItem?
    @State var itemToRename: PhotoItem?
    @State var draggedItem: PhotoItem?
    @State var hasChangedLocation: Bool = false

    @State var didAddMorePhotos: Bool = false
    
    var dismissAction: ()->()

    init(pageLayoutState: PageLayoutState, appMode: Binding<PECSAppMode>,
         mainMenuAction: Binding<MainMenuAction?>, isForSplitView: Bool,
         dismissAction: @escaping () -> Void) {
        self.pageLayoutState = pageLayoutState
        self._appMode = appMode
        self._mainMenuAction = mainMenuAction
        self.isForSplitView = isForSplitView
        self.dismissAction = dismissAction
    }
    
    private var selectionSubtitle: String {
        selectedPhotoIDs.count == 1
            ? L10n.PhotoSelectionView.oneSelectedSubtitle(1)
            : L10n.PhotoSelectionView.manySelectedSubtitle(selectedPhotoIDs.count)
    }

    private func exitSelectionMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSelectionMode = false
            selectedPhotoIDs.removeAll()
        }
    }

    private func toggleAllPhotosSelection() {
        withAnimation(.easeInOut(duration: 0.16)) {
            selectedPhotoIDs = allPhotosAreSelected
                ? []
                : Set(selectablePhotos.map(\.itemID))
        }
    }
    
    private var addPhotosMenu: some View {
        PhotoSourceMenu(libraryIdentifier: AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton,
                        onSelect: selectPhotoSource) {
            Label(L10n.PhotoSelectionView.addMorePhotosButton, systemImage: "plus")
        }
    }

    private func selectPhotoSource(_ source: PhotoSource) {
        switch source {
        case .library:
            addPhotos()
        case .camera:
            guard let presenter = presentationContext.presenter else { return }
            takeBoardPhoto(pageLayoutState: pageLayoutState, from: presenter)
        case .aacStandard:
#if EasyPECSPlus
            showAACStandardSymbolsPicker = true
#else
            break
#endif
        case .dynavox:
            addDVSymbols()
        case .ai:
            addAISymbols()
        case .symbol:
            addARASAACSymbols()
        }
    }
    
    @ToolbarContentBuilder
    private var navigationToolbarSelectionMode: some ToolbarContent {
        ToolbarItem(placement: horizontalSizeClass == .compact ? .navigationBarLeading : .navigationBarTrailing) {
                        
            Button(allPhotosAreSelected
                   ? L10n.PhotoSelectionView.deselectAllButton
                   : L10n.PhotoSelectionView.selectAllButton,
                   action: toggleAllPhotosSelection)
            .disabled(selectablePhotos.isEmpty)
            .accessibilityIdentifier(allPhotosAreSelected
                                     ? AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton
                                     : AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
        }
        
        ToolbarItem(placement: .principal) {
            boardTitleView(isVerticalStack: true)
        }

        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
        }
        
        //Exit selection mode
        DoneToolbarItem(id: AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton) {
            exitSelectionMode()
        }
        
    }


    @ToolbarContentBuilder
    private var navigationToolbarNonSelectionMode: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !isForSplitView {
                BoardNavigationControl(icon: "chevron.left",
                                       label: L10n.MainMenu.back,
                                       action: { dismiss() })
            }
        }
        
        ToolbarItem(placement: .principal) {
            boardTitleView(isVerticalStack: true)
        }
        
        boardOverflowToolbar

        if horizontalSizeClass != .compact {
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
            }
        }

        if horizontalSizeClass != .compact && !boardIsEmpty {
            ToolbarItem(placement: .primaryAction) {
                Button(L10n.PhotoSelectionView.select) {
                    enterSelectionMode()
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.selectModeButton)
            }
        }
    }

    private var boardLanguages: [String] {
        Set((pageLayoutState.topic.localization?.languages ?? []) + [BoardLanguage.appLanguage, "en", "es"])
            .filter { $0 != BoardLanguage.unassigned }.sorted()
    }

    @ViewBuilder
    private var boardMoreMenuActions: some View {
        if horizontalSizeClass == .compact && !boardIsEmpty {
            Button(L10n.PhotoSelectionView.select, systemImage: "checkmark.circle") {
                enterSelectionMode()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.selectModeButton)
            Divider()
        }

        if FeatureFlags.current.arasaacSymbolsEnabled {
            Button(L10n.BoardSuggestions.inspireMe, systemImage: "sparkles") {
                showInspiration = true
            }
            .accessibilityIdentifier("BoardSuggestions.inspireMe")
        }

        Menu(L10n.BoardLanguage.title, systemImage: "globe") {
            Button(L10n.BoardLanguage.followApp) { pageLayoutState.selectBoardLanguage(nil) }
                .accessibilityIdentifier("BoardLanguage.followApp")
            ForEach(boardLanguages, id: \.self) { language in
                Button(Locale.current.localizedString(forIdentifier: language) ?? language) {
                    pageLayoutState.selectBoardLanguage(language)
                }
                .accessibilityIdentifier("BoardLanguage.\(language)")
            }
            Menu(L10n.BoardLanguage.otherLanguages) {
                ForEach(Locale.LanguageCode.isoLanguageCodes.map(\.identifier).filter { !boardLanguages.contains($0) && $0 != "und" }, id: \.self) { language in
                    Button(Locale.current.localizedString(forLanguageCode: language) ?? language) {
                        pageLayoutState.selectBoardLanguage(language)
                    }
                }
            }
        }
        .accessibilityIdentifier("BoardLanguage.menu")

        // Add Photos menu
        addPhotosMenu
        Divider()

        // Save image to photo library
        Button(L10n.PreviewPage.saveImageButton, systemImage: "photo.badge.arrow.down") {
            shareBoard(format: .image)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintImageButton)

        if pageLayoutState.canRepeatSinglePhoto {
            Button(L10n.PreviewPage.repeatButton,
                   systemImage: pageLayoutState.repeatSinglePhoto ? "repeat.circle.fill" : "repeat.circle") {
                pageLayoutState.repeatSinglePhoto.toggle()
            }
                .accessibilityValue(pageLayoutState.repeatSinglePhoto ? Text("On") : Text("Off"))
                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.repeatImageButton)
        }

        Button(L10n.MainMenu.addTitlesButton, systemImage: "textformat") {
            openMainMenuAction(.titles)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.selectTitlesButton)

        Divider()
        Button(L10n.MainMenu.settingsButton, systemImage: "gear") {
            openMainMenuAction(.settings)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.settingsButton)
    }

    @ToolbarContentBuilder
    private var boardOverflowToolbar: some ToolbarContent {
        //Don't use ToolbarOverflowMenu because it re-positions ... button after Select button
        /*
        if #available(iOS 27.0, *) {
            ToolbarOverflowMenu {
                boardMoreMenuActions
            }
        } else {
         */
            ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                boardMoreMenuActions
            } label: {
                Label(L10n.MainMenu.moreOptions, systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
            }
            .accessibilityLabel(L10n.MainMenu.moreOptions)
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.menuButton)
            }
        
    }
    
    @ViewBuilder
    private func boardTitleView(isVerticalStack: Bool) -> some View {
        if isSelectionMode {
            BoardEditorTitle(title: pageLayoutState.title, selectionSubtitle: selectionSubtitle, isVerticalStack: isVerticalStack)
        } else {
            VStack(spacing: 0) {
                Button { showBoardDetails = true } label: {
                    BoardEditorTitle(title: pageLayoutState.title, selectionSubtitle: nil, isVerticalStack: isVerticalStack)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.titleField)

                Button(L10n.PhotoContextMenu.renameButton) {
                    showBoardDetails = true
                }
                .font(.caption2)
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.renameButton)
            }
        }
    }
    

    @ViewBuilder
    private var selectionMenuActions: some View {
#if AppHasTopics
        selectionAction(L10n.PhotoSelectionView.copyAction, systemImage: "plus.rectangle.on.rectangle", id: AccessibilityIdentifiers.PhotoSelectionView.copyButton) {
            showTopicSelectionAlert = true
        }
#endif
        /*
        selectionAction(L10n.PhotoSelectionView.cropAction, systemImage: "crop", id: AccessibilityIdentifiers.PhotoSelectionView.autoCropButton) {
            autoCropSelected()
        }*/
        
        selectionAction(L10n.PhotoSelectionView.duplicateAction, systemImage: "doc.on.doc", id: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton) {
            showDuplicateSelectionAlert = true
        }
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        if isSelectionMode {
            ToolbarItem(placement: boardActionPlacement) {
                selectionAction(L10n.PhotoSelectionView.deleteAction, systemImage: "trash",
                                id: AccessibilityIdentifiers.PhotoSelectionView.deleteButton) {
                    showDeleteSelectionAlert = true
                }
            }
            ToolbarItemGroup(placement: boardActionPlacement) {
                    selectionMenuActions
                .disabled(selectedPhotoIDs.isEmpty)
                .accessibilityLabel(L10n.MainMenu.moreOptions)
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.menuButton)
            }
    
        } else {
            ToolbarItemGroup(placement: boardActionPlacement) {
                ForEach(BoardEditorAction.allCases.filter {
                    $0 != .useBoard || FeatureFlags.current.voiceEnabled
                }) { item in
                    Button(item.title, systemImage: item.symbol) {
                        performBoardAction(item)
                    }
                    .accessibilityIdentifier(item.accessibilityID)
                }
            }
        }
    }

    private var portraitBottomToolbar: some View {
        HStack(spacing: 0) {
            if isSelectionMode {
                selectionAction(L10n.PhotoSelectionView.deleteAction, systemImage: "trash",
                                id: AccessibilityIdentifiers.PhotoSelectionView.deleteButton) {
                    showDeleteSelectionAlert = true
                }
                selectionMenuActions
                    .disabled(selectedPhotoIDs.isEmpty)
            } else {
                BoardEditorActionButtons(vertical: false, action: performBoardAction)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .buttonStyle(.plain)
        .background {
            Rectangle()
                .fill(.bar)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var boardActionPlacement: ToolbarItemPlacement {
        isLandscape ? .navigationBarTrailing : .bottomBar
    }

    private func performBoardAction(_ action: BoardEditorAction) {
        switch action {
        case .layout: showLayout = true
        case .format: showFormatting = true
        case .share: shareBoard()
        case .print: openMainMenuAction(.print)
        case .useBoard:
            navigationModel.enterChoiceBoard(returningTo: nil)
            withAnimation { appMode = .choiceBoard }
        }
    }

    private func openMainMenuAction(_ action: MainMenuAction) {
        navigationModel.setMainMenuAction(action)
    }

    private func enterSelectionMode() {
        withAnimation(.easeInOut(duration: 0.2)) { isSelectionMode = true }
    }

    private func shareBoard(format: ExportCollageFormat = .pdf) {
        let items = pageLayoutState.createShareableItems(format: format)
        guard !items.isEmpty else { return }

        let activityView = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityView.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                pageLayoutState.deleteTempFiles()
            }
        }

        guard let presenter = presentationContext.presenter else { return }
        if let popover = activityView.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX,
                                        y: presenter.view.bounds.midY,
                                        width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        presenter.present(activityView, animated: true)
    }

    private func selectionAction(_ title: String, systemImage: String, id: String,
                                 action: @escaping () -> Void) -> some View {
        PhotoBottomActionButton(title, symbol: systemImage, id: id,
                                isEnabled: !selectedPhotoIDs.isEmpty,
                                verticalLabel: !isLandscape, action: action)
    }

    func toggleSelection(for photo: PhotoItem) {
        withAnimation(.easeInOut(duration: 0.16)) {
            if selectedPhotoIDs.contains(photo.itemID) {
                selectedPhotoIDs.remove(photo.itemID)
            } else {
                selectedPhotoIDs.insert(photo.itemID)
            }
        }
    }
    
    func isSelected(_ photo: PhotoItem) -> Bool {
        selectedPhotoIDs.contains(photo.itemID)
    }
    
    func deleteSelected() {
        let deletesAllPhotos = allPhotosAreSelected
        pageLayoutState.deletePhotos(selectedPhotos)
        if deletesAllPhotos {
            exitSelectionMode()
        } else {
            selectedPhotoIDs.removeAll()
        }
    }
    
    func deletePhoto(_ photo: PhotoItem) {
        pageLayoutState.deletePhotos([photo])
        selectedPhotoIDs.remove(photo.itemID)
    }
    
    func renamePhoto(_ photo: PhotoItem, newValue: String) {
        pageLayoutState.photoBrowserData.renamePhoto(photo, newValue: newValue)
    }
    
    func duplicatePhoto(_ photo: PhotoItem) {
        pageLayoutState.photoBrowserData.duplicatePhotos([photo])
    }
    
    func duplicateSelected() {
        pageLayoutState.photoBrowserData.duplicatePhotos(selectedPhotos) { count in
            duplicatedPhotoCount = count
            showDuplicateSuccessAlert = true
        }
    }
    
    func autoCropSelected() {
        pageLayoutState.photoBrowserData.autoCropPhotos(selectedPhotos)
    }
    
    //@StateObject var pls2: PageLayoutState?
    
    func copySelected(to topic: PECSRepo) {
        
        //Can't load PageLayoutState here becuse the add photo
        //happens asynchronously and the PLS will go out of scope
        //and not save the photo repo if we don't have it as a
        //state variable.
        //pls2 = PageLayoutState(topic: topic)
        //pls2.load(topic: topic)
        //pls2.photoBrowserData.add(selections)
        
        PageLayoutState.copyPhotos(selectedPhotos, to: topic)
        
        showTopicSelectionAlert = false
        showPhotoCopySuccessAlert = true
        
    }
    
    func addPhotos() {
        didAddMorePhotos = true
        guard let presenter = presentationContext.presenter else { return }
        selectPhotos(pageLayoutState: pageLayoutState,
                     isAdditive: AppSettings.photoPickerIsAdditive,
                     currentTheme: currentTheme,
                     from: presenter)
    }
        
    func addDVSymbols() {
        didAddMorePhotos = true
        showDVSymbolsPicker = true
    }
    
    func addARASAACSymbols() {
        didAddMorePhotos = true
        showARASAACSymbolsPicker = true
    }

    func addAISymbols() {
        didAddMorePhotos = true
        showAISymbolsPicker = true
    }
    
    var body: some View {
        photoGrid
        .onDisappear {
            dismissAction()
        }
    }

    private var photoGrid: some View { bodyGrid }

    var bodyGrid: some View {
        BoardEditorGrid(pageLayoutState: pageLayoutState,
                        selectedPage: $navigationModel.selectedBoardPage,
                        selectedPhotoIDs: selectedPhotoIDs,
                        isSelectionMode: isSelectionMode,
                        isLandscape: isLandscape,
                        contextMenuDelegate: self) { index in
            let photos = pageLayoutState.photoBrowserData.photoItems
            if photos.indices.contains(index) {
                onPhotoTapped(photo: photos[index])
            } else if !isSelectionMode {
                navigationModel.push(.emptyCard(index))
            }
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showTopicSelectionAlert) {
            TopicAlertView(isPresented: $showTopicSelectionAlert,
                           title: L10n.CopyPhotoList.title(selectedPhotoIDs.count),
                           exclude: [pageLayoutState.topic], onSelectTopic: { topic in
                copySelected(to: topic)
            })
        }
#if EasyPECSPlus
        .selectDVSymbols(isPresented: $showDVSymbolsPicker, pageLayoutState: pageLayoutState, isAdditive: AppSettings.photoPickerIsAdditive)
        .selectAISymbols(isPresented: $showAISymbolsPicker, pageLayoutState: pageLayoutState, isAdditive: AppSettings.photoPickerIsAdditive)
#endif
#if EasyPECSPlus
        .selectAACStandardSymbols(isPresented: $showAACStandardSymbolsPicker,
                                  pageLayoutState: pageLayoutState,
                                  isAdditive: AppSettings.photoPickerIsAdditive)
#endif
        .selectARASAACSymbols(isPresented: $showARASAACSymbolsPicker, pageLayoutState: pageLayoutState, isAdditive: AppSettings.photoPickerIsAdditive)
        .sheet(isPresented: $showFormatting) {
            FormattingView(formattingOptions: pageLayoutState.topic.formatting) {
                pageLayoutState.save()
                showFormatting = false
            }
        }
        .sheet(isPresented: $showLayout, onDismiss: { layoutPath = [] }) {
            NavigationStack(path: $layoutPath) {
                PageSizeAndLayoutView(pageLayoutState: pageLayoutState,
                                      onSeeAll: { layoutPath.append(.allLayouts) }) {
                    pageLayoutState.save()
                }
                .navigationDestination(for: AppRoute.self) { route in
                    if route == .allLayouts { AllLayoutsView(pageLayoutState: pageLayoutState) }
                }
                .toolbar {
                    CancelToolbarItem(id: "BoardEditor.cancelLayout") {
                        showLayout = false
                    }
                    ConfirmToolbarItem(id: "BoardEditor.closeLayout") {
                        pageLayoutState.save()
                        showLayout = false
                    }
                }
            }
        }
        .sheet(isPresented: $showInspiration) {
            NavigationStack {
                PhotoCellZoomed(pageLayoutState: pageLayoutState,
                                photo: .constant(nil), onDelete: { _ in },
                                isBoardDetails: true, inspireOnOpen: true)
            }
        }
        .sheet(isPresented: $showBoardDetails) {
            NavigationStack {
                PhotoCellZoomed(pageLayoutState: pageLayoutState,
                                photo: .constant(nil), onDelete: { _ in }, isBoardDetails: true,
                                boardDetailsTitle: L10n.TopicSelectionView.renameTopicButton)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { pageLayoutState.flushThumbnail() }
        }
        .onChange(of: pageLayoutState.repeatSinglePhoto) { _ in pageLayoutState.save() }
        .accessibilityElement(children: .contain)

        .askToDeletePhoto(photo: $itemToDelete, theme: currentTheme, deleteAction: { photo in
            deletePhoto(photo)
        })
        .askToRenamePhoto(photo: $itemToRename, theme: currentTheme, renameAction: { photo, newTitle in
            renamePhoto(photo, newValue: newTitle)
        })
        .alert(L10n.PhotoSelectionView.deleteAction,
               isPresented: $showDeleteSelectionAlert) {
            Button(L10n.PhotoSelectionView.deleteAction, role: .destructive) { deleteSelected() }
            Button(L10n.PhotoZoomView.cancelButton, role: .cancel) { }
        } message: {
            Text(L10n.DeletePhotosAlert.message(selectedPhotoIDs.count))
        }
        .alert(L10n.PhotoSelectionView.DuplicateSelectionAlert.title,
               isPresented: $showDuplicateSelectionAlert) {
            Button(L10n.PhotoSelectionView.duplicateAction, action: duplicateSelected)
            Button(L10n.PhotoZoomView.cancelButton, role: .cancel) { }
        } message: {
            Text(selectedPhotos.count == 1
                 ? L10n.PhotoSelectionView.DuplicateSelectionAlert.oneMessage
                 : L10n.PhotoSelectionView.DuplicateSelectionAlert.manyMessage(selectedPhotos.count))
        }
        .alert(L10n.PhotoSelectionView.DuplicateSuccessAlert.title,
               isPresented: $showDuplicateSuccessAlert) {
            Button(L10n.PhotoZoomView.closeButton, role: .cancel) { }
        } message: {
            Text(duplicatedPhotoCount == 1
                 ? L10n.PhotoSelectionView.DuplicateSuccessAlert.oneMessage
                 : L10n.PhotoSelectionView.DuplicateSuccessAlert.manyMessage(duplicatedPhotoCount))
        }
        .alert(L10n.PhotoSelectionView.CopyPhotosSuccessAlert.title,
               isPresented: $showPhotoCopySuccessAlert) {
            Button(L10n.PhotoZoomView.closeButton, role: .cancel) { }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if isSelectionMode {
                navigationToolbarSelectionMode
            }
            else {
                navigationToolbarNonSelectionMode
            }
            if !boardIsEmpty && isLandscape { bottomToolbar }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !boardIsEmpty && !isLandscape {
                portraitBottomToolbar
            }
        }
        .toolbar(.hidden, for: .bottomBar)
        .onGeometryChange(for: Bool.self) { geometry in
            geometry.size.width > geometry.size.height
        } action: { isLandscape = $0 }
        .frame(maxWidth: .infinity)
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
    }

    // MARK: PhotoCellActionDelegate
    func onPhotoTapped(photo: any SharedSwiftUI.ImagePickerItem) {
        guard let photo = photo as? PhotoItem else { return }
        if isSelectionMode {
            toggleSelection(for: photo)
        } else {
            navigationModel.push(.photo(photo.itemID))
        }
    }
    
    func onPhotoSelected(photo: any SharedSwiftUI.ImagePickerItem) {
        guard let photo = photo as? PhotoItem else { return }
        toggleSelection(for: photo)
    }
    
    func onDuplicatePhoto(photo: any SharedSwiftUI.ImagePickerItem) {
        guard let photo = photo as? PhotoItem else { return }
        duplicatePhoto(photo)
    }
    
    func onDeletePhotoSelected(photo: any SharedSwiftUI.ImagePickerItem) {
        guard let photo = photo as? PhotoItem else { return }
        itemToDelete = photo
    }
    
    func onRenamePhotoSelected(photo: any SharedSwiftUI.ImagePickerItem) {
        guard let photo = photo as? PhotoItem else { return }
        itemToRename = photo
    }
}

struct PhotoBottomActionButton: View {
    let title: String
    let symbol: String
    let id: String
    let isEnabled: Bool
    let verticalLabel: Bool
    let action: () -> Void

    init(_ title: String, symbol: String, id: String, isEnabled: Bool = true,
         verticalLabel: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.id = id
        self.isEnabled = isEnabled
        self.verticalLabel = verticalLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            let layout = verticalLabel
                ? AnyLayout(VStackLayout(spacing: 4))
                : AnyLayout(HStackLayout(spacing: 4))
            layout {
                Image(systemName: symbol)
                    .font(verticalLabel ? .title3 : .caption)
                    .frame(minHeight: verticalLabel ? 24 : 0)
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: verticalLabel ? .infinity : nil,
                   minHeight: verticalLabel ? 50 : 44)
            .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .accessibilityIdentifier(id)
        .accessibilityLabel(title)
    }
}

struct ReorderDropDelegate<Data>: DropDelegate
where Data : Equatable {
    @Binding var draggedItem: Data?
    let droppedItem: Data
    @Binding var listData: [Data]
    @Binding var hasChangedLocation: Bool
    
    func dropEntered(info: DropInfo) {
        guard droppedItem != draggedItem,
              let current = draggedItem,
              let from = listData.firstIndex(of: current),
              let to = listData.firstIndex(of: droppedItem)
        else {
            return
        }
        hasChangedLocation = true
        if listData[to] != current {
            withAnimation {
                listData.move(fromOffsets: IndexSet(integer: from),
                              toOffset: (to > from) ? to + 1 : to)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        hasChangedLocation = false
        draggedItem = nil
        return true
    }
}

/*
struct DragRelocateDelegate: DropDelegate {
    let item: PhotoItem
    let listData: Binding<[PhotoItem]>

    func performDrop(info: DropInfo) -> Bool {
        let fromIndex = listData.wrappedValue.firstIndex(of: item)!
        guard let toIndex = index(from: info) else {
            return false
        }

        withAnimation {
            listData.wrappedValue.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex)
        }
        return true
    }

    func index(from info: DropInfo) -> Int? {
        guard var toIndex = listData.wrappedValue.firstIndex(of: item) else {
            return nil
        }

        guard let fromIndex = info.itemProviders(for: [.image]).first else {
            return nil
        }
        
        fromIndex.loadObject(ofClass: UIImage.self) { image, _ in
            guard let image = image else { return }
            guard let currentIndex = listData.wrappedValue.firstIndex(of: item) else { return }
            let fromFrame = info.dragItem.localObject as! CGRect
            let midY = fromFrame.midY
            let toFrame = getFrame(for: currentIndex, columns: 1, itemSize: CGSize(width: 100, height: 100), spacing: 10, alignment: .topLeading)

            if midY > toFrame.midY {
                toIndex += 1
            }
            
        }
        return toIndex
    }

    func getFrame(for index: Int, columns: Int, itemSize: CGSize, spacing: CGFloat, alignment: Alignment) -> CGRect {
        let row = index / columns
        let column = index % columns
        let x = alignment.horizontal == .leading ? CGFloat(column) * (itemSize.width + spacing) : CGFloat(columns - 1 - column) * (itemSize.width + spacing)
        let y = alignment.vertical == .top ? CGFloat(row) * (itemSize.height + spacing) : CGFloat(row - 1) * (itemSize.height + spacing)
        return CGRect(x: x, y: y, width: itemSize.width, height: itemSize.height)
    }
}
*/

extension View {
    
    
    func askToDeletePhoto(photo: Binding<PhotoItem?>, theme: SharedUITheme,
                          title: String = L10n.PhotoSelectionView.deleteAction,
                          message: String = L10n.DeletePhotoAlert.message,
                          deleteAction: @escaping (PhotoItem)->() ) -> some View {
        modifier(PhotoDeleteAlertModifier(photo: photo, title: title, message: message,
                                          deleteAction: deleteAction))
    }
    
    func askToRenamePhoto(photo: Binding<PhotoItem?>, theme: SharedUITheme, renameAction: @escaping (PhotoItem, String) -> () ) -> some View {
        modifier(PhotoRenameAlertModifier(photo: photo, renameAction: renameAction))
    }
}

private struct PhotoDeleteAlertModifier: ViewModifier {
    @Binding var photo: PhotoItem?
    let title: String
    let message: String
    let deleteAction: (PhotoItem) -> Void

    func body(content: Content) -> some View {
        content.alert(title,
                      isPresented: Binding(get: { photo != nil }, set: { if !$0 { photo = nil } })) {
            Button(title, role: .destructive) {
                guard let photo else { return }
                deleteAction(photo)
                self.photo = nil
            }
            Button(L10n.PhotoZoomView.cancelButton, role: .cancel) { photo = nil }
        } message: {
            Text(message)
        }
    }
}

private struct PhotoRenameAlertModifier: ViewModifier {
    @Binding var photo: PhotoItem?
    let renameAction: (PhotoItem, String) -> Void
    @State private var draftTitle = ""

    func body(content: Content) -> some View {
        content
            .onChange(of: photo?.itemID) { _ in
                draftTitle = photo?.title ?? ""
            }
            .alert(L10n.RenamePhotoAlert.title,
                   isPresented: Binding(get: { photo != nil }, set: { if !$0 { photo = nil } })) {
                TextField(L10n.RenamePhotoAlert.placeholder, text: $draftTitle)
                Button(L10n.PhotoZoomView.saveButton) {
                    guard let photo else { return }
                    renameAction(photo, draftTitle)
                    self.photo = nil
                }
                Button(L10n.PhotoZoomView.cancelButton, role: .cancel) { photo = nil }
            }
    }
}
