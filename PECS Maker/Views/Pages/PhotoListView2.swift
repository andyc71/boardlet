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
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @ObservedObject var pageLayoutState: PageLayoutState
    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    var isForSplitView: Bool

    @State var showTopicSelectionAlert: Bool = false
    @State var showDeleteSelectionAlert: Bool = false
    @State var showPhotoCopySuccessAlert: Bool = false
    @State var showDVSymbolsPicker: Bool = false
#if EasyPECSPlus
    @State private var showAACStandardSymbolsPicker = false
#endif
    @State private var showARASAACSymbolsPicker: Bool = false
    @State var showAISymbolsPicker: Bool = false
    
    @State private var selectedPhotoIDs: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var showBoardDetails = false
    @State private var selectedPage = 0
    @State private var showFormatting = false
    @State private var showLayout = false
    @State private var boardZoom = BoardPageViewport.fitZoom
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeCardSourceID: String?

    private let boardDetailsTransitionID = "board-details"

    private var usesCompactControls: Bool {
        verticalSizeClass == .compact && UIDevice.current.userInterfaceIdiom == .phone
    }

    private var usesCompactTitle: Bool {
        horizontalSizeClass == .compact &&
            (verticalSizeClass == .regular || UIDevice.current.userInterfaceIdiom == .pad)
    }

    private var selectedPhotos: [PhotoItem] {
        pageLayoutState.photoBrowserData.photoItems.filter { selectedPhotoIDs.contains($0.itemID) }
    }

    private var allPhotosAreSelected: Bool {
        let photos = pageLayoutState.photoBrowserData.photoItems
        return !photos.isEmpty && photos.allSatisfy { selectedPhotoIDs.contains($0.itemID) }
    }

    private var boardIsEmpty: Bool {
        pageLayoutState.photoBrowserData.photoItems.isEmpty
    }

    @State var itemToDelete: PhotoItem?
    @State var itemToRename: PhotoItem?
    @State var zoomedItem: PhotoItem?
    @State private var zoomedEmptyIndex: Int?
    @State var draggedItem: PhotoItem?
    @State var hasChangedLocation: Bool = false

    @State var didAddMorePhotos: Bool = false
    
    var dismissAction: ()->()
    
    private var cardAspectRatio: CGFloat {
        let size = pageLayoutState.individualCardMeasurements.sizeInMM
        return size.height > 0 ? size.width / size.height : 1
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
                : Set(pageLayoutState.photoBrowserData.photoItems.map(\.itemID))
        }
    }
    
    private var addPhotosMenu: some View {
        Menu {
            Button(L10n.PhotoSelectionView.photoLibrary, systemImage: "photo") {
                addPhotos()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(L10n.PhotoSelectionView.camera, systemImage: "camera") {
                    takeBoardPhoto(pageLayoutState: pageLayoutState)
                }
            }
#if EasyPECSPlus
            Button(L10n.Symbols.aacStandard) { showAACStandardSymbolsPicker = true }
            Button("Dynavox") { addDVSymbols() }
            Button("Create with AI") { addAISymbols() }
#endif
            if FeatureFlags.current.arasaacSymbolsEnabled {
                Button(L10n.Symbols.arasaac) { addARASAACSymbols() }
            }
        } label: {
            Label(L10n.PhotoSelectionView.addMorePhotosButton, systemImage: "plus")
        }
    }
    
    @ToolbarContentBuilder
    private var navigationToolbarSelectionMode: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(allPhotosAreSelected
                   ? L10n.PhotoSelectionView.deselectAllButton
                   : L10n.PhotoSelectionView.selectAllButton,
                   action: toggleAllPhotosSelection)
            .frame(minHeight: 44)
            .disabled(pageLayoutState.photoBrowserData.photoItems.isEmpty)
            .accessibilityIdentifier(allPhotosAreSelected
                                     ? AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton
                                     : AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
        }
        
        //Title
        if !usesCompactTitle {
            ToolbarItem(placement: .principal) {
                boardTitleView(isVerticalStack: true)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            //Exit selection mode
            Button(L10n.PhotoSelectionView.closeSelection, action: exitSelectionMode)
                .frame(minHeight: 44)
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton)
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
        
        if !usesCompactTitle {
            ToolbarItem(placement: .principal) {
                boardTitleView(isVerticalStack: true)
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                
                //Add Photos menu
                addPhotosMenu
                
                //Save image to photo library
                Button(L10n.PreviewPage.saveImageButton, systemImage: "photo.badge.arrow.down") { shareBoard(format: .image) }
                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintImageButton)
                
                //Repeat single photo in every cell
                if pageLayoutState.canRepeatSinglePhoto {
                    Toggle(L10n.PreviewPage.repeatButton, isOn: $pageLayoutState.repeatSinglePhoto)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.repeatImageButton)
                }
                
                //Enable the user to edit all the photo titles on one screen.
                //May be quicker than tapping each photo.
                Button(L10n.MainMenu.addTitlesButton, systemImage: "textformat") {
                    openMainMenuAction(.titles)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.selectTitlesButton)

                Divider()
                Button(L10n.MainMenu.settingsButton, systemImage: "gear") {
                    openMainMenuAction(.settings)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.settingsButton)

                
                //Zoom controls.
                /*
                 Menu {
                 Button(L10n.BoardEditor.zoomFit, systemImage: "arrow.down.right.and.arrow.up.left") {
                 boardZoom = BoardPageViewport.fitZoom
                 }
                 .accessibilityIdentifier("BoardEditor.zoomFit")
                 } label: {
                 Label(L10n.BoardEditor.zoom, systemImage: "plus.magnifyingglass")
                 }
                 */
                
            } label: {
                Image(systemName: "ellipsis")
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel(L10n.MainMenu.moreOptions)
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.menuButton)
            
        }
        
        if #available(iOS 26.0, *) {
            ToolbarSpacer(placement: .navigationBarTrailing)
        }
        
        if !pageLayoutState.photoBrowserData.photoItems.isEmpty {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(L10n.PhotoSelectionView.select) {
                    withAnimation(.easeInOut(duration: 0.2)) { isSelectionMode = true }
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.selectModeButton)
            }
        }
    }
    
    @ViewBuilder
    private func boardTitleView(isVerticalStack: Bool) -> some View {
        if isSelectionMode {
            BoardEditorTitle(title: pageLayoutState.title, selectionSubtitle: selectionSubtitle, isVerticalStack: isVerticalStack)
        } else {
            Button { showBoardDetails = true } label: {
                BoardEditorTitle(title: pageLayoutState.title, selectionSubtitle: nil, isVerticalStack: isVerticalStack)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.titleField)
            .boardCardTransitionSource(id: boardDetailsTransitionID, namespace: namespace)
        }
    }
    

    @ViewBuilder
    private var selectionMenuActions: some View {
#if AppHasTopics
        Button(L10n.PhotoSelectionView.copyAction, systemImage: "plus.rectangle.on.rectangle") {
            showTopicSelectionAlert = true
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.copyButton)
#endif
        Button(L10n.PhotoSelectionView.cropAction, systemImage: "crop") {
            autoCropSelected()
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.autoCropButton)
        Button(L10n.PhotoSelectionView.duplicateAction, systemImage: "doc.on.doc") {
            duplicateSelected()
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            if isSelectionMode {
                selectionAction(L10n.PhotoSelectionView.deleteAction, symbol: "trash",
                                id: AccessibilityIdentifiers.PhotoSelectionView.deleteButton) {
                    showDeleteSelectionAlert = true
                }
                Spacer()
                Menu {
                    selectionMenuActions
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .disabled(selectedPhotoIDs.isEmpty)
                .accessibilityLabel(L10n.MainMenu.moreOptions)
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.menuButton)
            } else {
                BoardEditorActionButtons(vertical: false, action: performBoardAction)
            }
        }
    }

    private func performBoardAction(_ action: BoardEditorAction) {
        switch action {
        case .layout: showLayout = true
        case .format: showFormatting = true
        case .share: shareBoard()
        case .print: printBoard()
        case .useBoard:
            navigationModel.enterChoiceBoard(returningTo: nil)
            withAnimation { appMode = .choiceBoard }
        }
    }

    private func openMainMenuAction(_ action: MainMenuAction) {
        if isForSplitView {
            navigationModel.setSplitAction(action)
        } else {
            navigationModel.setMainMenuAction(action)
        }
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

        if let popover = activityView.popoverPresentationController,
           let presenter = topViewController() {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX,
                                        y: presenter.view.bounds.midY,
                                        width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topViewController()?.present(activityView, animated: true)
    }

    private func printBoard() {
        guard let pdfURL = pageLayoutState.createPDF() else { return }
        let jobName = pageLayoutState.title.isEmpty ? L10n.PreviewPage.title : pageLayoutState.title
        let didPresent = presentSystemPrintController(
            printingItem: pdfURL,
            jobName: jobName,
            from: topViewController()
        ) { _, completed, error in
            DispatchQueue.main.async {
                pageLayoutState.deleteTempFiles()
                if let error {
                    logger.logError(.general, "Error returned from print controller", error)
                }
                if completed {
                    MFAnalytics.logSuccess("Print")
                }
            }
        }
        if !didPresent {
            pageLayoutState.deleteTempFiles()
        }
    }

    private func selectionAction(_ title: String, symbol: String, id: String,
                                 action: @escaping () -> Void) -> some View {
        PhotoBottomActionButton(title, symbol: symbol, id: id,
                                isEnabled: !selectedPhotoIDs.isEmpty, action: action)
    }

    init(pageLayoutState: PageLayoutState, appMode: Binding<PECSAppMode>,
         mainMenuAction: Binding<MainMenuAction?>, isForSplitView: Bool,
         dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self._appMode = appMode
        self._mainMenuAction = mainMenuAction
        self.isForSplitView = isForSplitView
        self.dismissAction = dismissAction
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
        pageLayoutState.photoBrowserData.deletePhotos(selectedPhotos)
        if deletesAllPhotos {
            exitSelectionMode()
        } else {
            selectedPhotoIDs.removeAll()
        }
    }
    
    func deletePhoto(_ photo: PhotoItem) {
        pageLayoutState.photoBrowserData.deletePhotos([photo])
        selectedPhotoIDs.remove(photo.itemID)
    }
    
    func renamePhoto(_ photo: PhotoItem, newValue: String) {
        pageLayoutState.photoBrowserData.renamePhoto(photo, newValue: newValue)
    }
    
    func duplicatePhoto(_ photo: PhotoItem) {
        pageLayoutState.photoBrowserData.duplicatePhotos([photo])
    }
    
    func duplicateSelected() {
        pageLayoutState.photoBrowserData.duplicatePhotos(selectedPhotos)
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
        selectPhotos(pageLayoutState: pageLayoutState, isAdditive: AppSettings.photoPickerIsAdditive, currentTheme: currentTheme)
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
            selectedPhotoIDs.removeAll()
            isSelectionMode = false
            dismissAction()
        }
    }

    @Namespace private var namespace

    private var zoomedPhotoBinding: Binding<PhotoItem?> {
        Binding(get: { zoomedItem }, set: { item in
            zoomedItem = item
            if item == nil { zoomedEmptyIndex = nil }
        })
    }

    @ViewBuilder
    private var photoGrid: some View {
        bodyGrid
            .navigationDestination(isPresented: $showBoardDetails) {
                boardDetailsDestination
            }
            .navigationDestination(isPresented: Binding(
                get: { zoomedItem != nil || zoomedEmptyIndex != nil },
                set: {
                    if !$0 {
                        zoomedItem = nil
                        zoomedEmptyIndex = nil
                    }
                }
            )) {
                if let photo = zoomedItem {
                    photoDestination(for: photo)
                } else if let index = zoomedEmptyIndex {
                    emptyDestination(for: index)
                }
            }
    }

    private var boardDetailsDestination: some View {
        PhotoCellZoomed(pageLayoutState: pageLayoutState,
                        photo: .constant(nil), onDelete: { _ in }, isBoardDetails: true)
            .boardCardZoomTransition(sourceID: boardDetailsTransitionID,
                                     namespace: namespace,
                                     reduceMotion: reduceMotion)
    }

    private func photoDestination(for photo: PhotoItem) -> some View {
        PhotoCellZoomed(pageLayoutState: pageLayoutState, photo: zoomedPhotoBinding, onDelete: deletePhoto)
            .boardCardZoomTransition(sourceID: activeCardSourceID, namespace: namespace, reduceMotion: reduceMotion)
    }

    private func emptyDestination(for index: Int) -> some View {
        PhotoCellZoomed(pageLayoutState: pageLayoutState, photo: zoomedPhotoBinding,
                        onDelete: deletePhoto, isEmptySlot: true, index: index)
            .boardCardZoomTransition(sourceID: activeCardSourceID, namespace: namespace, reduceMotion: reduceMotion)
    }

    var bodyGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            if usesCompactTitle {
                boardTitleView(isVerticalStack: false)
                    .padding(.horizontal)
                    .padding(.top)
                    //.padding(.vertical, .small)
            }

            CollageView(pageLayoutState: pageLayoutState, selectedPage: $selectedPage,
                        selectedPhotoIDs: selectedPhotoIDs, isSelectionMode: isSelectionMode,
                        usesBoardIdentifiers: true, compactControls: usesCompactControls,
                        showsNoPhotosOverlay: true, pageControlsVerticalPadding: 8,
                        zoom: $boardZoom,
                        transitionNamespace: namespace,
                        onTransitionSourceSelected: { activeCardSourceID = $0 },
                        compactActions: BoardEditorActionButtons(vertical: true, action: performBoardAction)) { index in
                let photos = pageLayoutState.photoBrowserData.photoItems
                if photos.indices.contains(index) {
                    onPhotoTapped(photo: photos[index])
                } else if !isSelectionMode {
                    zoomedEmptyIndex = index
                }
            }
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
        }
        .sheet(isPresented: $showFormatting) {
            FormattingView(formattingOptions: pageLayoutState.topic.formatting) {
                pageLayoutState.save()
                showFormatting = false
            }
        }
        .sheet(isPresented: $showLayout) {
            NavigationStack {
                PageSizeAndLayoutView(pageLayoutState: pageLayoutState) {
                    pageLayoutState.save()
                    showLayout = false
                }
                .toolbar {
                    CancelToolbarButton(id: "BoardEditor.cancelLayout") {
                        showLayout = false
                    }
                    ConfirmToolbarButton(id: "BoardEditor.closeLayout") {
                        pageLayoutState.save()
                        showLayout = false
                    }
                }
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
        .askQuestionYesNo(isPresented: $showDeleteSelectionAlert, title: nil,
                          message: L10n.DeletePhotosAlert.message(selectedPhotoIDs.count),
                          isDestructive: true, theme: currentTheme, yesAction: { deleteSelected() },
                          noAction: { })
        .successAlert(isPresented: $showPhotoCopySuccessAlert,
                      title: L10n.PhotoSelectionView.CopyPhotosSuccessAlert.title, theme: currentTheme)
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
            if !usesCompactControls && !boardIsEmpty { bottomToolbar }
        }
        .toolbar(usesCompactControls || boardIsEmpty ? .hidden : .automatic, for: .bottomBar)
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
            zoomedItem = photo
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
    let action: () -> Void

    init(_ title: String, symbol: String, id: String, isEnabled: Bool = true,
         action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.id = id
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                Text(title).lineLimit(1)
            }
            .font(.caption)
            .frame(minHeight: 44)
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
    
    
    func askToDeletePhoto(photo: Binding<PhotoItem?>, theme: SharedUITheme, deleteAction: @escaping (PhotoItem)->() ) -> some View {
        
        let photoToDelete = photo.wrappedValue
        
        let isPresented = Binding<Bool> (
            get: { return photo.wrappedValue != nil },
            set: { newValue in
                if !newValue { photo.wrappedValue = nil }
            }
        )
        
        return self.askQuestionYesNo(isPresented: isPresented, title: nil, message: L10n.DeletePhotoAlert.message, isDestructive: true, theme: theme, yesAction: {
                guard let photoToDelete else { return }
                deleteAction(photoToDelete)
        }, noAction: { } )
    }
    
    func askToRenamePhoto(photo: Binding<PhotoItem?>, theme: SharedUITheme, renameAction: @escaping (PhotoItem, String) -> () ) -> some View {
        
        let photoToRename = photo.wrappedValue
        
        let isPresented = Binding<Bool> (
            get: { return photo.wrappedValue != nil },
            set: { newValue in
                if !newValue { photo.wrappedValue = nil }
            }
        )
        
        let photoTitle = Binding<String> (
            get: {
                guard let photo = photo.wrappedValue else { return "" }
                return photo.title ?? ""
            },
            set: { newValue in
                guard let photo = photo.wrappedValue else { return }
                photo.title = newValue
            }
        )
        
        return self.renameItemAlert(isPresented: isPresented, itemName: photoTitle, placeholder: L10n.RenamePhotoAlert.placeholder, title: L10n.RenamePhotoAlert.title, message: nil, theme: theme, saveAction: {
                guard let photoToRename else { return }
                renameAction(photoToRename, photoTitle.wrappedValue)
        })
    }
    

}
