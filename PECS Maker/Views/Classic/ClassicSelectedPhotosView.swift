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

struct ClassicSelectedPhotosView: View, PhotoCellActionDelegate {

    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var presentationContext: ScenePresentationContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
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

    static func visiblePhotos(in photos: [PhotoItem]) -> [PhotoItem] {
        photos.filter { !$0.isPlaceholder }
    }

    private var displayedPhotos: [PhotoItem] {
        Self.visiblePhotos(in: pageLayoutState.photoBrowserData.photoItems)
    }

    private var selectedPhotos: [PhotoItem] {
        displayedPhotos.filter { selectedPhotoIDs.contains($0.itemID) }
    }

    private var allPhotosAreSelected: Bool {
        !displayedPhotos.isEmpty && displayedPhotos.allSatisfy { selectedPhotoIDs.contains($0.itemID) }
    }

    @State var itemToDelete: PhotoItem?
    @State var itemToRename: PhotoItem?
    @EnvironmentObject private var navigationModel: NavigationModel
    @State var draggedItem: PhotoItem?
    @State var hasChangedLocation: Bool = false

    @State var didAddMorePhotos: Bool = false
    
    var dismissAction: ()->()
    
    private var columns: [GridItem] {
        let minimum: CGFloat = dynamicTypeSize.isAccessibilitySize ? 180 : 110
        return [GridItem(.adaptive(minimum: minimum), spacing: 10, alignment: .top)]
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
                : Set(displayedPhotos.map(\.itemID))
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
                    .disabled(displayedPhotos.isEmpty)
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
        
        //If not selection mode then we can add items.
        if !isSelectionMode {
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(placement: .navigationBarTrailing)
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                
                PhotoSourceMenu(libraryIdentifier: AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton,
                                onSelect: selectPhotoSource) {
                    Image(systemSymbol: .plus)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(L10n.PhotoSelectionView.addItems)
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.menuButton)
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
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
        ClassicPhotoBottomActionButton(title, symbol: symbol, id: id,
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
        pageLayoutState.deletePhotos(selectedPhotos)
        selectedPhotoIDs.removeAll()
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
        guard let presenter = presentationContext.presenter else { return }
        selectPhotos(pageLayoutState: pageLayoutState,
                     isAdditive: AppSettings.photoPickerIsAdditive,
                     currentTheme: currentTheme,
                     from: presenter)
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


    private var photoGrid: some View { bodyGrid }

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

    private func photoCell(_ photo: PhotoItem, index: Int) -> some View {
        photoCellContent(photo, index: index)
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
            let indicesByID = Dictionary(uniqueKeysWithValues: displayedPhotos.enumerated().map { ($0.element.itemID, $0.offset) })
            if AppSettings.showTopicDebugInfo {
                let topic = pageLayoutState.topic
                Text(topic.topicName)
                Text("Photo count: \(topic.photos.photoItems.count)")
            }
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(displayedPhotos) { photo in
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
        .accessibilityValue("\(displayedPhotos.count)")
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode { selectionActions }
        }
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
        .alert(L10n.PhotoSelectionView.CopyPhotosSuccessAlert.title,
               isPresented: $showPhotoCopySuccessAlert) {
            Button(L10n.PhotoZoomView.closeButton, role: .cancel) { }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!isForSplitView)
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

struct ClassicPhotoBottomActionButton: View {
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

