//
//  PhotoListView.swift
//  PECS Maker
//
//  Created by Andy on 18/12/2022.
//

import SwiftUI
import PhotosUI
import LogFramework
import SharedSwiftUI
import SFSafeSymbols

struct PhotoListView2: View, PhotoCellActionDelegate {

    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @ObservedObject var pageLayoutState: PageLayoutState
    @Binding var appMode: PECSAppMode
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

    private var selectedPhotos: [PhotoItem] {
        pageLayoutState.photoBrowserData.photoItems.filter { selectedPhotoIDs.contains($0.itemID) }
    }

    private var allPhotosAreSelected: Bool {
        let photos = pageLayoutState.photoBrowserData.photoItems
        return !photos.isEmpty && photos.allSatisfy { selectedPhotoIDs.contains($0.itemID) }
    }

    @State var itemToDelete: PhotoItem?
    @State var itemToRename: PhotoItem?
    @State var zoomedItem: PhotoItem?
    @State var draggedItem: PhotoItem?
    @State var hasChangedLocation: Bool = false

    @State var didAddMorePhotos: Bool = false
    
    var dismissAction: ()->()
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    private var columns: [GridItem] {
        if isIPad {
            if pageLayoutState.photoBrowserData.photoCount < 36 {
                return [GridItem(.adaptive(minimum: 140), spacing: 12, alignment: .top)]
            }
            return [GridItem(.adaptive(minimum: 120), spacing: 12, alignment: .top)]
        }
        return [GridItem(.adaptive(minimum: 100), spacing: 8, alignment: .top)]
    }
    
    private var selectionSubtitle: String {
        selectedPhotoIDs.count == 1
            ? L10n.PhotoSelectionView.oneSelectedSubtitle(1)
            : L10n.PhotoSelectionView.manySelectedSubtitle(selectedPhotoIDs.count)
    }

    private var navigationTitleFont: Font {
        if let font = Theme.headerFontDefault {
            return .custom(font.fontName, fixedSize: font.pointSize)
        }
        return .system(size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
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

    @ToolbarContentBuilder
    private var selectionNavigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if isSelectionMode {
                Button(allPhotosAreSelected
                       ? L10n.PhotoSelectionView.deselectAllButton
                       : L10n.PhotoSelectionView.selectAllButton,
                       action: toggleAllPhotosSelection)
                    .frame(minHeight: 44)
                    .disabled(pageLayoutState.photoBrowserData.photoItems.isEmpty)
                    .accessibilityIdentifier(allPhotosAreSelected
                                             ? AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton
                                             : AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
            } else if !isForSplitView {
                BoardNavigationControl(icon: "chevron.left",
                                       label: L10n.MainMenu.back,
                                       action: { dismiss() })
            }
        }
        ToolbarItem(placement: .principal) {
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.PhotoSelectionView.photosTitle)
                    .font(navigationTitleFont)
                if isSelectionMode {
                    Text(selectionSubtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.selectionCountLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !isSelectionMode {
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
                    Image(systemSymbol: .plus)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(L10n.PhotoSelectionView.addItems)
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.menuButton)
            }

            if isSelectionMode {
                Button(action: exitSelectionMode) {
                    Label(L10n.PhotoSelectionView.closeSelection, systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton)
                .accessibilityLabel(L10n.PhotoSelectionView.closeSelection)
            } else {
                Button(L10n.PhotoSelectionView.select) {
                    withAnimation(.easeInOut(duration: 0.2)) { isSelectionMode = true }
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.selectModeButton)
            }
        }
    }

    private var selectionActions: some View {
        PhotoBottomActionBar {
            selectionAction(L10n.PhotoSelectionView.deleteAction, symbol: "trash",
                            id: AccessibilityIdentifiers.PhotoSelectionView.deleteButton) {
                showDeleteSelectionAlert = true
            }
#if AppHasTopics
            selectionAction(L10n.PhotoSelectionView.copyAction, symbol: "plus.rectangle.on.rectangle",
                            id: AccessibilityIdentifiers.PhotoSelectionView.copyButton) {
                showTopicSelectionAlert = true
            }
#endif
            selectionAction(L10n.PhotoSelectionView.cropAction, symbol: "crop",
                            id: AccessibilityIdentifiers.PhotoSelectionView.autoCropButton) {
                autoCropSelected()
            }
            selectionAction(L10n.PhotoSelectionView.duplicateAction, symbol: "doc.on.doc",
                            id: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton) {
                duplicateSelected()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func selectionAction(_ title: String, symbol: String, id: String,
                                 action: @escaping () -> Void) -> some View {
        PhotoBottomActionButton(title, symbol: symbol, id: id,
                                isEnabled: !selectedPhotoIDs.isEmpty, action: action)
    }

    init(pageLayoutState: PageLayoutState, appMode: Binding<PECSAppMode>, isForSplitView: Bool, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self._appMode = appMode
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
        pageLayoutState.photoBrowserData.deletePhotos(selectedPhotos)
        selectedPhotoIDs.removeAll()
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
        Group {
            if isForSplitView {
                NavigationStack { photoGrid }
            } else {
                photoGrid
            }
        }
        .onDisappear {
            selectedPhotoIDs.removeAll()
            isSelectionMode = false
            dismissAction()
        }
    }

    @Namespace private var namespace

    @ViewBuilder
    private var photoGrid: some View {
        bodyGrid
            .navigationDestination(isPresented: Binding(
                get: { zoomedItem != nil },
                set: { if !$0 { zoomedItem = nil } }
            )) {
                if let photo = zoomedItem {
                    photoDestination(for: photo)
                }
            }
    }

    @ViewBuilder
    private func photoDestination(for photo: PhotoItem) -> some View {
        if #available(iOS 18.0, *) {
            PhotoCellZoomed(photo: $zoomedItem, onDelete: deletePhoto)
                .boardBackButton()
                .navigationTransition(.zoom(sourceID: photo.itemID, in: namespace))
        } else {
            PhotoCellZoomed(photo: $zoomedItem, onDelete: deletePhoto)
                .boardBackButton()
        }
    }
    
    private func selectedBadge(for photo: PhotoItem, index: Int) -> some View {
        Button {
            toggleSelection(for: photo)
        } label: {
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.selectedBadge(for: index))
        .accessibilityLabel(L10n.PhotoSelectionView.deselectPhoto)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    @ViewBuilder
    private func photoCell(_ photo: PhotoItem, index: Int) -> some View {
        if #available(iOS 18.0, *) {
            photoCellContent(photo, index: index)
                .matchedTransitionSource(id: photo.itemID, in: namespace)
        } else {
            photoCellContent(photo, index: index)
        }
    }

    private func photoCellContent(_ photo: PhotoItem, index: Int) -> some View {
        PhotoCell<PhotoItem>(item: photo, isSelected: isSelected(photo),
                             showSelectButton: false,
                             showDeleteButton: false,
                             index: index,
                             useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                             untitledLabel: L10n.PhotoSelectionView.untitledCell,
                             canRenameItem: true,
                             delegate: self)
            .overlay(alignment: .topTrailing) {
                if isSelectionMode && isSelected(photo) {
                    selectedBadge(for: photo, index: index)
                }
            }
            .padding(12)
            .onDrag {
                draggedItem = photo
                return NSItemProvider(object: photo.image)
            }
            .onDrop(of: [.image], delegate: ReorderDropDelegate(draggedItem: $draggedItem,
                      droppedItem: photo, listData: $pageLayoutState.photoBrowserData.photoItems,
                      hasChangedLocation: $hasChangedLocation))
            .if(!isSelectionMode) { view in
                view.photoCellContextMenu(for: photo, delegate: self)
            }
    }

    var bodyGrid: some View {
        ScrollView {
            let photoItems = pageLayoutState.photoBrowserData.photoItems
            let indicesByID = Dictionary(uniqueKeysWithValues: photoItems.enumerated().map { ($0.element.itemID, $0.offset) })
            if AppSettings.showTopicDebugInfo {
                let topic = pageLayoutState.topic
                Text(topic.topicName)
                Text("Photo count: \(topic.photos.photoItems.count)")
            }
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(photoItems) { photo in
                    photoCell(photo, index: indicesByID[photo.itemID] ?? 0)
                }
            }
            .padding()
            .noPhotosTipView(pageLayoutState: pageLayoutState, source: .photoList)
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.collectionView)
        .accessibilityValue("\(pageLayoutState.photoBrowserData.photoCount)")
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode { selectionActions }
        }
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
        .toolbar { selectionNavigationToolbar }
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

struct PhotoBottomActionBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) { content }
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.secondary.opacity(0.3)))
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
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
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.body)
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
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
