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
import SwiftUIX

struct PhotoListView2: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    var isForSplitView: Bool
    
    private var isMultiSelect: Bool
    private var showDeleteButtons: Bool
    private let canSelectAll: Bool = false
    private let canDeleteAll: Bool = true
    
    @State var showTopicSelectionAlert: Bool = false
    @State var showDeleteSelectionAlert: Bool = false
    @State var showDeleteAllAlert: Bool = false
    @State var showPhotoCopySuccessAlert: Bool = false
    @State var allPhotosAreSelected: Bool = false
    
    @State var selections: [PhotoItem] = []
    
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
                Button(psl.allPhotosAreSelected ? L10n.PhotoSelectionView.deselectAllButton : L10n.PhotoSelectionView.selectAllButton) {
                    psl.selectAll()
                }
                .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                .foregroundColor(Color(UIColor.mfPlainSecondaryButtonText))
                .accessibility(identifier: psl.allPhotosAreSelected ? AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton : AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                
                //if selections.count > 0 { //Doesn't work on-device, so having to use hidden
                
                Button(systemImage: SFSymbolName.trash /*SFSymbolName.xmark*/, action: {
                    psl.showDeleteSelectionAlert = true
                })
                //.buttonStyle(MFPlainButtonStyle(purpose: .destructive))
                .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                .toolbarButttonFixIOS14()
                .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
                .accessibilityLabel(L10n.PhotoSelectionView.deleteButton)
                .hidden(psl.selections.count == 0)
                
                Spacer()
                
                Button(systemImage: SFSymbolName.plusRectangleOnRectangle, action: {
                    psl.showTopicSelectionAlert = true
                })
                .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                .toolbarButttonFixIOS14()
                .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
                .accessibilityLabel(L10n.PhotoSelectionView.copyButton)
                .hidden(psl.selections.count == 0)
                
                Spacer()
                
                Button(systemImage: SFSymbolName.docOnDoc, action: {
                    psl.duplicateSelected()
                })
                .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                .toolbarButttonFixIOS14()
                .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
                .accessibilityLabel(L10n.PhotoSelectionView.duplicateButton)
                .hidden(psl.selections.count == 0)
                
                //}
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

    
    
    init(pageLayoutState: PageLayoutState, isMultiSelect: Bool = false, showDeleteButtons: Bool = true, isForSplitView: Bool, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.isMultiSelect = isMultiSelect
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
    
    func deleteAll() {
        pageLayoutState.photoBrowserData.removeAll()
    }
    

    func duplicateSelected() {
        pageLayoutState.photoBrowserData.duplicatePhotos(selections)
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
    /*
    func copySelected(to topic: PECSRepo) {
        PageLayoutState.copyPhotos(selections, to: topic)
        showTopicSelectionAlert = false
        showPhotoCopySuccessAlert = true
    }
    */
     
    func addPhotos() {
        didAddMorePhotos = true
        selectPhotos(photoBrowserData: pageLayoutState.photoBrowserData)
    }
        
    var body: some View {
        ScrollView {
            
            if AppSettings.showTopicDebugInfo {
                if let topic = pageLayoutState.topic {
                    Text(topic.topicName)
                }
            }
            
            LazyVGrid(columns: self.columns, spacing: 0) {
                
                NewItemCell( text: L10n.PhotoSelectionView.addMorePhotosButton, action: {
                    addPhotos()
                })
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
                .padding(12)
                
                ForEach($pageLayoutState.photoBrowserData.photoItems) { $photo in
                    let index = pageLayoutState.photoBrowserData.photoItems.firstIndex(where: {$0.id==photo.id})
                    let isSelected = isSelected(photo)
                    PhotoCell(photo: $photo, isSelected: isSelected, showDeleteButton: showDeleteButtons, index: index, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                              onTapped: {
                        //toggleSelection(for: photo)
                    },
                              onDelete: {
                        deletePhoto(photo)
                    }
                    )
                    .padding(12)
                }
            }
            .noPhotosTipView(photoBrowserData: pageLayoutState.photoBrowserData)
            /*
            .sheet(isPresented: $showTopicSelectionAlert) {
                TopicAlertView(isPresented: $showTopicSelectionAlert, title: L10n.CopyPhotoList.title(selections.count), exclude: [pageLayoutState.topic], onSelectTopic: { topic in
                    copySelected(to: topic)
                })
            }
            */
            
            .onAppear {
                /*
                if pageLayoutState.photoBrowserData.photoCount == 0 && !didAddMorePhotos && isForSplitView {
                    addPhotos()
                }
                 */
            }
            
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
            .padding(8)
            .padding(.top, 8)
            
        }
        
        .askQuestionYesNo(isPresented: $showDeleteSelectionAlert, title: nil,
                          message: L10n.DeletePhotosAlert.message(selections.count), isDestructive: true, yesAction: { deleteSelected() },
                          noAction: { } )
        .askQuestionYesNo(isPresented: $showDeleteAllAlert, title: nil,
                          message: L10n.DeleteAllPhotosAlert.message, isDestructive: true, yesAction: { deleteAll() },
                          noAction: { } )

        .successAlert(isPresented: $showPhotoCopySuccessAlert, title: L10n.PhotoSelectionView.CopyPhotosSuccessAlert.title)
        .navigationBarTitle(Text(L10n.PhotoSelectionView.title), displayMode: .inline)
        .frame(maxWidth: .infinity)
        .padding()
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        //.selectAllToolbar(self, canSelectAll)
        .if(canSelectAll) { view in
            view.toolbar { toolbarForSelectAll }
        }
        .if(canDeleteAll) { view in
            view.toolbar { toolbarForDeleteAll }
        }
        .onDisappear { dismissAction() }
        .onAppear {
            MFAnalytics.logScreenView(screenName: "PhotoSelections")
        }
        
    }
}

extension View {
    
    @ViewBuilder
    func selectAllToolbar(_ psl: PhotoListView2, _ canSelectAll: Bool) -> some View {
        
        if !canSelectAll {
            self
        }
        else {
            self.toolbar(content: {
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(psl.allPhotosAreSelected ? L10n.PhotoSelectionView.deselectAllButton : L10n.PhotoSelectionView.selectAllButton) {
                        psl.selectAll()
                    }
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .foregroundColor(Color(UIColor.mfPlainSecondaryButtonText))
                    .accessibility(identifier: psl.allPhotosAreSelected ? AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton : AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    
                    //if selections.count > 0 { //Doesn't work on-device, so having to use hidden
                    
                    Button(systemImage: SFSymbolName.trash /*SFSymbolName.xmark*/, action: {
                        psl.showDeleteSelectionAlert = true
                    })
                    //.buttonStyle(MFPlainButtonStyle(purpose: .destructive))
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.deleteButton)
                    .hidden(psl.selections.count == 0)
                    
                    Spacer()
                    
                    Button(systemImage: SFSymbolName.plusRectangleOnRectangle, action: {
                        psl.showTopicSelectionAlert = true
                    })
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.copyButton)
                    .hidden(psl.selections.count == 0)
                    
                    Spacer()
                    
                    Button(systemImage: SFSymbolName.docOnDoc, action: {
                        psl.duplicateSelected()
                    })
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.duplicateButton)
                    .hidden(psl.selections.count == 0)
                    
                    //}
                }
            }
                         )
        }
    }
}

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

extension View {
    func noPhotosTipView(photoBrowserData: PhotoBrowserData) -> some View {
        self.emptyListPlaceholder(photoBrowserData.photoItems) {
            VStack {
                TipView(tipText: L10n.NoPhotosView.message, canHide: false, accessibilityIdentifier: AccessibilityIdentifiers.NoPhotosView.tipView)
                CapsuleButton(text: L10n.NoPhotosView.addPhotosButton, action: {
                    self.selectPhotos(photoBrowserData: photoBrowserData, preselectItems: AppSettings.preselectPhotosInPicker)
                })
                .accessibilityIdentifier(AccessibilityIdentifiers.NoPhotosView.addPhotosButton)
                .frame(maxWidth: AppSettings.maxButtonWidth)
                Spacer()
            }
            .frame(maxWidth: AppSettings.maxViewWidth)
            .padding()
            .listRowBackground(Color(currentTheme.backgroundColor))
            .hideListRowSeparatorIfAvailable()
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

