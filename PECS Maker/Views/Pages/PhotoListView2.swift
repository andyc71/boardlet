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

struct PhotoListView2: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @ObservedObject var pageLayoutState: PageLayoutState
    @Binding var appMode: PECSAppMode
    var isForSplitView: Bool

    private var showDeleteButtons: Bool
    
    //On the latest version of the app we have Select All on the top
    //toolbar and delete, move, copy on the bottom toolbar.
    private let canMultiSelect: Bool = true
    private let canSelectAll: Bool = true
    private let canDeleteAll: Bool = false
    //On older versions of the app (without topics), we have a Delete All
    //button only.
    //private let canMultiSelect: Bool = false
//    private let canSelectAll: Bool = false
//    private let canDeleteAll: Bool = true

    @State var showTopicSelectionAlert: Bool = false
    @State var showDeleteSelectionAlert: Bool = false
    @State var showDeleteAllAlert: Bool = false
    @State var showPhotoCopySuccessAlert: Bool = false
    @State var allPhotosAreSelected: Bool = false
    @State var showSymbolsPicker: Bool = false
    
    @State var selections: [PhotoItem] = []
    
    @State var draggedItem: PhotoItem?
    @State var hasChangedLocation: Bool = false

    @State var didAddMorePhotos: Bool = false
    
    var dismissAction: ()->()
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    //let gridItem = GridItem(.flexible())
    //let columns = [GridItem(.adaptive(minimum: 100))]
    
    private var columns: [GridItem] {
        
        //The sizes are based purely on what looks good for the screenshots on
        //the main supported devices.
        
        if isIPad {
            if pageLayoutState.photoBrowserData.photoCount < 36 {
                return [GridItem(.adaptive(minimum: 140), spacing: 12, alignment: .top)]
            }
            else {
                return [GridItem(.adaptive(minimum: 120), spacing: 12, alignment: .top)]
            }
        }
        else {
            //iPhone
            //As many items with min size of 100 as can fit
            return [GridItem(.adaptive(minimum: 100), spacing: 8, alignment: .top)]
        }
        
        
        //return [GridItem(.adaptive(minimum: 100))]
    }
    
    @ToolbarContentBuilder
    var toolbarForSelectAll: some ToolbarContent {
        let psl = self
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                
                #if EasyPECSPlus
                    Button(L10n.MainMenu.choiceBoardButton) {
                        appMode = .choiceBoard
                    }
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.choiceBoardButton)
                #endif
                
                Button(psl.allPhotosAreSelected ? L10n.PhotoSelectionView.deselectAllButton : L10n.PhotoSelectionView.selectAllButton) {
                    psl.selectAll()
                }
                .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                .foregroundColor(Color(UIColor.mfPlainSecondaryButtonText))
                .accessibility(identifier: psl.allPhotosAreSelected ? AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton : AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                
                if selections.count > 0 {
                    
                    Button(action: { psl.showDeleteSelectionAlert = true },
                           label: Image(systemSymbol: .trash))
                    //.buttonStyle(MFPlainButtonStyle(purpose: .destructive))
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.deleteButton)
                    //.hidden(psl.selections.count == 0)
                    
                    
                #if EasyPECSPlus
                    Spacer()
                    
                    Button(action: { psl.showTopicSelectionAlert = true },
                           label: Image(systemSymbol: .plusRectangleOnRectangle))
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.copyButton)
                    //.hidden(psl.selections.count == 0)
                #endif
                    
                    Spacer()
                    
                    Button(action: { psl.autoCropSelected() },
                           label: Image(systemSymbol: .crop))
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.autoCropButton)
                    //.accessibilityLabel(L10n.PhotoSelectionView.autoCropButton)
                    //.hidden(psl.selections.count == 0)
                    
                    Spacer()
                    
                    Button(action: { psl.duplicateSelected() },
                           label: Image(systemSymbol: .docOnDoc))
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.duplicateButton)
                    //.hidden(psl.selections.count == 0)
                    
                }
                else {
                    EmptyView()
                }
            }
    }
    
    @ToolbarContentBuilder
    var toolbarForDeleteAll: some ToolbarContent {
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(L10n.PhotoSelectionView.deleteAllButton) {
                showDeleteAllAlert = true
            }
            .buttonStyle(MFPlainButtonStyle(purpose: .destructive))
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteAllButton)
            .hidden(pageLayoutState.photoBrowserData.photoCount == 0)
        }
        
    }
    
    init(pageLayoutState: PageLayoutState, appMode: Binding<PECSAppMode>, showDeleteButtons: Bool = true, isForSplitView: Bool, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self._appMode = appMode
        self.showDeleteButtons = showDeleteButtons
        self.isForSplitView = isForSplitView
        self.dismissAction = dismissAction
    }
    
    func toggleSelection(for photo: PhotoItem) {
        if selections.contains(where: {$0.id == photo.id}) {
            selections.removeAll { $0.id == photo.id }
        }
        else {
            selections.append(photo)
        }
    }
    
    func isSelected(_ photo: PhotoItem) -> Bool {
        return selections.contains { $0.id == photo.id }
    }
    
    func deleteSelected() {
        pageLayoutState.photoBrowserData.deletePhotos(selections)
        for photo in selections {
            selections.removeAll { $0.id == photo.id }
        }
    }
    
    func deletePhoto(_ photo: PhotoItem) {
        pageLayoutState.photoBrowserData.deletePhotos([photo])
    }
    
    func renamePhoto(_ photo: PhotoItem, newValue: String) {
        pageLayoutState.photoBrowserData.renamePhoto(photo, newValue: newValue)
    }
    
    func deleteAll() {
        pageLayoutState.photoBrowserData.removeAll()
    }
    

    func duplicateSelected() {
        pageLayoutState.photoBrowserData.duplicatePhotos(selections)
    }
    
    func autoCropSelected() {
        pageLayoutState.photoBrowserData.autoCropPhotos(selections)
    }
    
    func selectAll() {
        if allPhotosAreSelected {
            selections.removeAll()
        }
        else {
            selections.append(contentsOf: pageLayoutState.photoBrowserData.photoItems)
        }
        allPhotosAreSelected.toggle()
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
        
        PageLayoutState.copyPhotos(selections, to: topic)
        
        showTopicSelectionAlert = false
        showPhotoCopySuccessAlert = true
        
    }
    
    func addPhotos() {
        didAddMorePhotos = true
        selectPhotos(pageLayoutState: pageLayoutState, preselectItems: AppSettings.preselectPhotosInPicker, isAdditive: AppSettings.photoPickerIsAdditive, currentTheme: currentTheme)
    }
        
    func addSymbols() {
        didAddMorePhotos = true
        showSymbolsPicker = true
    }
    
    /*
    @ViewBuilder
    var navBarItemsTrailing : some View {
        
        
        HStack {
            if canSelectAll {
                Button(allPhotosAreSelected ? L10n.PhotoSelectionView.deselectAllButton : L10n.PhotoSelectionView.selectAllButton) {
                    selectAll()
                }
                .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                .foregroundColor(Color(UIColor.mfPlainSecondaryButtonText))
                .accessibility(identifier: allPhotosAreSelected ? AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton : AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
            }
            
            if canDeleteAll {
                Button(L10n.PhotoSelectionView.deleteAllButton) {
                    showDeleteAllAlert = true
                }
                .buttonStyle(MFPlainButtonStyle(purpose: .destructive))
                .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteAllButton)
                .hidden(pageLayoutState.photoBrowserData.photoCount == 0)
            }
            
        }
    }
     */
    
    @ViewBuilder
    var toolbarItemsForBottom : some View {
        let psl = self
        HStack {
            Button(action: { psl.showDeleteSelectionAlert = true },
                   label: Image(systemSymbol: .trash))
            //.buttonStyle(MFPlainButtonStyle(purpose: .destructive))
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .toolbarButttonFixIOS14()
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
            .accessibilityLabel(L10n.PhotoSelectionView.deleteButton)
            .hidden(psl.selections.count == 0)
            
            Spacer()
            
            Button(action: { psl.showTopicSelectionAlert = true },
                   label: Image(systemSymbol: .plusRectangleOnRectangle))
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .toolbarButttonFixIOS14()
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
            .accessibilityLabel(L10n.PhotoSelectionView.copyButton)
            .hidden(psl.selections.count == 0)
            
            Spacer()
            
            Button(action: { psl.autoCropSelected() },
                   label: Image(systemSymbol: .crop))
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .toolbarButttonFixIOS14()
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.autoCropButton)
            //.accessibilityLabel(L10n.PhotoSelectionView.autoCropButton)
            .hidden(psl.selections.count == 0)
            
            Spacer()
            
            Button(action: { psl.duplicateSelected() },
                   label: Image(systemSymbol: .docOnDoc))
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .toolbarButttonFixIOS14()
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
            .accessibilityLabel(L10n.PhotoSelectionView.duplicateButton)
            .hidden(psl.selections.count == 0)
        }
    }
    
    var footer: some View {
        VStack {
            let photoCount = pageLayoutState.photoBrowserData.photoCount
            if photoCount > 0 {
                HStack {
                    Text(L10n.PhotoSelectionView.photoCountLabel(photoCount))
                        .foregroundColor(.secondaryLabel)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.photoCountLabel)
                    Spacer()
                }
            }
            let selectionsCount = selections.count
            if selectionsCount >  0 {
                HStack {
                    Text(L10n.PhotoSelectionView.selectedPhotoCountLabel(selectionsCount))
                        .foregroundColor(.secondaryLabel)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.selectedPhotoCountLabel)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
    }
        
    var body: some View {
        ScrollView {
            
            if AppSettings.showTopicDebugInfo {
                let topic = pageLayoutState.topic
                Text(topic.topicName)
                Text("Photo count: \(topic.photos.photoItems.count)")
            }
            
            LazyVGrid(columns: self.columns, spacing: 0) {
                Section(footer: footer) {
                    NewItemCell( text: L10n.PhotoSelectionView.addMorePhotosButton, action: {
                        addPhotos()
                    })
                    .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
                    .padding(12)
                    
#if EasyPECSPlus
                    NewItemCell( text: "Add Symbols", action: {
                        addSymbols()
                    })
                    .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
                    .padding(12)
#endif
                    
                    ForEach($pageLayoutState.photoBrowserData.photoItems) { $photo in
                        let index = pageLayoutState.photoBrowserData.photoItems.firstIndex(where: {$0.id==photo.id})
                        let isSelected = isSelected(photo)
                        PhotoCell<PhotoItem>(item: photo, isSelected: isSelected, showSelectButton: canMultiSelect, showDeleteButton: showDeleteButtons, index: index, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                                             untitledLabel: L10n.PhotoSelectionView.untitledCell,
                                             deleteMessage: L10n.DeletePhotoAlert.message,
                                             canRenameItem: true,
                                             autoCapitalize: false,
                                             renameAlertMessage: L10n.RenamePhotoAlert.title,
                                             renameAlertPlaceholderText: L10n.RenamePhotoAlert.placeholder,
                                             onTapped: {
                            toggleSelection(for: photo)
                        },
                                             onDelete: {
                            deletePhoto(photo)
                        },
                                             onRename: { newValue in
                            renamePhoto(photo, newValue: newValue)
                        }
                                             
                        )
                        .padding(12)
                        .onDrag({
                            draggedItem = photo
                            return NSItemProvider(object: photo.image)
                        })
                        .onDrop(of: [.image], delegate: ReorderDropDelegate(draggedItem: $draggedItem, droppedItem: photo, listData: $pageLayoutState.photoBrowserData.photoItems, hasChangedLocation: $hasChangedLocation))
                    }
                }
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.collectionView)
            .padding()
            .noPhotosTipView(pageLayoutState: pageLayoutState)
            .sheet(isPresented: $showTopicSelectionAlert) {
                TopicAlertView(isPresented: $showTopicSelectionAlert, title: L10n.CopyPhotoList.title(selections.count), exclude: [pageLayoutState.topic], onSelectTopic: { topic in
                    copySelected(to: topic)
                })
            }
#if EasyPECSPlus
            .selectSymbols(isPresented: $showSymbolsPicker, pageLayoutState: pageLayoutState, isAdditive: AppSettings.photoPickerIsAdditive)
#endif
            .onAppear {
                /*
                 if pageLayoutState.photoBrowserData.photoCount == 0 && !didAddMorePhotos && isForSplitView {
                 addPhotos()
                 }
                 */
            }
        }
        
        .askQuestionYesNo(isPresented: $showDeleteSelectionAlert, title: nil,
                          message: L10n.DeletePhotosAlert.message(selections.count), isDestructive: true, theme: currentTheme, yesAction: { deleteSelected() },
                          noAction: { } )
        .askQuestionYesNo(isPresented: $showDeleteAllAlert, title: nil,
                          message: L10n.DeleteAllPhotosAlert.message, isDestructive: true, theme: currentTheme, yesAction: { deleteAll() },
                          noAction: { } )

        .successAlert(isPresented: $showPhotoCopySuccessAlert, title: L10n.PhotoSelectionView.CopyPhotosSuccessAlert.title, theme: currentTheme)
        
#if EasyPECSPlus
        .navigationBarTitle(Text(L10n.PhotoSelectionView.title), displayMode: .large)
        //.navigationBarItems(trailing: navBarItemsTrailing)
#else
        .navigationBarTitle(Text(L10n.PhotoSelectionView.title), displayMode: .inline)
#endif
        .if(canSelectAll) { view in
            view.toolbar { toolbarForSelectAll }
            //selectAllToolbar(self, canDeleteAll)
        }
        .if(canDeleteAll) { view in
            view.toolbar { toolbarForDeleteAll }
        }
        .frame(maxWidth: .infinity)
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear { dismissAction() }
        
    }
}

/*
extension View {
    
    @ToolbarContentBuilder
    func deselectAllToolbar(_ psl: PhotoListView2) -> some ToolbarContent {
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(L10n.PhotoSelectionView.deselectAllButton) {
                psl.selectAll()
            }
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .foregroundColor(Color(UIColor.mfPlainSecondaryButtonText))
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton)
        }
    }
    
    @ToolbarContentBuilder
    func selectAllToolbar(_ psl: PhotoListView2, _ canSelectAll: Bool) -> some ToolbarContent {
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(L10n.PhotoSelectionView.selectAllButton) {
                psl.selectAll()
            }
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .foregroundColor(Color(UIColor.mfPlainSecondaryButtonText))
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
        }
        
        ToolbarItemGroup(placement: .bottomBar) {
            
            //if selections.count > 0 { //Doesn't work on-device, so having to use hidden
            
            Button(action: { psl.showDeleteSelectionAlert = true },
                   label: Image(systemSymbol: .trash))
            //.buttonStyle(MFPlainButtonStyle(purpose: .destructive))
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .toolbarButttonFixIOS14()
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
            .accessibilityLabel(L10n.PhotoSelectionView.deleteButton)
            .hidden(psl.selections.count == 0)
            
            Spacer()
            
            Button(action: { psl.showTopicSelectionAlert = true },
                   label: Image(systemSymbol: .plusRectangleOnRectangle))
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .toolbarButttonFixIOS14()
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
            .accessibilityLabel(L10n.PhotoSelectionView.copyButton)
            .hidden(psl.selections.count == 0)
            
            Spacer()
            
            Button(action: { psl.autoCropSelected() },
                   label: Image(systemSymbol: .crop))
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .toolbarButttonFixIOS14()
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.autoCropButton)
            .accessibilityLabel(L10n.PhotoSelectionView.autoCropButton)
            .hidden(psl.selections.count == 0)
            
            Spacer()
            
            Button(action: { psl.duplicateSelected() },
                   label: Image(systemSymbol: .docOnDoc))
            .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
            .toolbarButttonFixIOS14()
            .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
            .accessibilityLabel(L10n.PhotoSelectionView.duplicateButton)
            .hidden(psl.selections.count == 0)
            
            //}
        }
    }
}
*/

extension View {
    /// Embeds the content in a view which removes some
    /// default styling in toolbars, so accessibility works.
    /// - Returns: Embedded content.
    /// https://stackoverflow.com/questions/65778208/accessibility-of-image-in-button-in-toolbaritem
    @ViewBuilder func toolbarButttonFixIOS14() -> some View {
        if #available(iOS 15, *) {
            self
        } else {
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
                self
            }
        }
    }
}

/*
 struct TitlesView_Previews: PreviewProvider {
 
 @ObservedObject static var pageLayoutState = PageLayoutState()
 
 static var previews: some View {
 TitlesView(pageLayoutState: pageLayoutState, dismissAction: {})
 }
 }
 */

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
