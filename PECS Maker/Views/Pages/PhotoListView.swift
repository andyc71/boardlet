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

struct PhotoListView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State var showTopicSelectionAlert: Bool = false
    @State var showDeleteSelectionAlert: Bool = false
    @State var showPhotoCopySuccessAlert: Bool = false
    @State var allPhotosAreSelected: Bool = false
    
    @State var selections: [PhotoItem] = []
    
    @State var didAddMorePhotos: Bool = false
    
    var dismissAction: ()->()
    
    let gridItem = GridItem(.flexible())
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
    }
    
    func toggleSelection(for photo: PhotoItem) {
        if selections.contains(photo) {
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
        selectPhotos(photoBrowserData: pageLayoutState.photoBrowserData)
    }
    
    func makeAddMorePhotosCell() -> some View {
        Button(action: { addPhotos() }) {
            VStack {
                Image(systemName: "plus.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: AppSettings.gridAddItemCellImageWidth)
                    .foregroundColor(Color(currentTheme.linkTextColor))
                
                Text(L10n.PhotoSelectionView.addMorePhotosButton)
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .foregroundColor(Color(currentTheme.linkTextColor))
            }
        }
        //.buttonStyle(RoundedButtonStyle( purpose: ButtonPurpose.secondary, cornerRadius:8))
        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
        .padding(12)
    }
    
    var body: some View {
        ScrollView {
            
            if AppSettings.showTopicDebugInfo {
                if let topic = pageLayoutState.topic {
                    Text(topic.topicName)
                    Text("Photo count: \(topic.photos.photoItems.count)")
                }
            }
            
            LazyVGrid(columns: self.columns) {
                
                makeAddMorePhotosCell()

                ForEach($pageLayoutState.photoBrowserData.photoItems) { $photo in
                    let index = pageLayoutState.photoBrowserData.photoItems.firstIndex(where: {$0.id==photo.id})
                    PhotoCell(photo: $photo, isSelected: isSelected(photo), index: index, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                              onTapped: {
                        toggleSelection(for: photo)
                    })
                    //.padding(8)
                }
            }
            .noPhotosTipView(photoBrowserData: pageLayoutState.photoBrowserData)
            .sheet(isPresented: $showTopicSelectionAlert) {
                TopicAlertView(isPresented: $showTopicSelectionAlert, title: L10n.CopyPhotoList.title(selections.count), exclude: [pageLayoutState.topic], onSelectTopic: { topic in
                    copySelected(to: topic)
                })
            }
//            .onAppear {
//                if pageLayoutState.photoBrowserData.photoCount == 0 && !didAddMorePhotos {
//                    addPhotos()
//                }
//            }
        }
        
        .askQuestionYesNo(isPresented: $showDeleteSelectionAlert, title: nil,
                          message: L10n.DeletePhotoAlert.message(selections.count), isDestructive: false, yesAction: { deleteSelected() },
            noAction: { } )

        .successAlert(isPresented: $showPhotoCopySuccessAlert, title: L10n.PhotoSelectionView.CopyPhotosSuccessAlert.title)
        .navigationBarTitle(Text(L10n.PhotoSelectionView.title), displayMode: .inline)
        .frame(maxWidth: .infinity)
        .padding()
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .toolbar {
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(allPhotosAreSelected ? L10n.PhotoSelectionView.deselectAllButton : L10n.PhotoSelectionView.selectAllButton) {
                    selectAll()
                }
                .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                .foregroundColor(Color(UIColor.mfPlainSecondaryButtonText))
                .accessibility(identifier: allPhotosAreSelected ? AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton : AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
            }

            ToolbarItemGroup(placement: .bottomBar) {
 
                //if selections.count > 0 { //Doesn't work on-device, so having to use hidden
                    
                    Button(systemImage: SFSymbolName.trash /*SFSymbolName.xmark*/, action: {
                        showDeleteSelectionAlert = true
                    })
                    //.buttonStyle(MFPlainButtonStyle(purpose: .destructive))
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.deleteButton)
                    .hidden(selections.count == 0)
                    
                    Spacer()
                    
                    Button(systemImage: SFSymbolName.plusRectangleOnRectangle, action: {
                        showTopicSelectionAlert = true
                    })
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.copyButton)
                    .hidden(selections.count == 0)

                    Spacer()
                    
                    Button(systemImage: SFSymbolName.docOnDoc, action: {
                        duplicateSelected()
                    })
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .toolbarButttonFixIOS14()
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.duplicateButton)
                    .hidden(selections.count == 0)
                
                //}

            }
        }
        .onDisappear { dismissAction() }
        .onAppear {
            MFAnalytics.logScreenView(screenName: "PhotoSelections")
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
                    self.selectPhotos(photoBrowserData: photoBrowserData)
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

