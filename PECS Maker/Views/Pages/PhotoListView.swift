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
                    return [GridItem(.adaptive(minimum: 140), spacing: 15, alignment: .top)]
                }
                else {
                    return [GridItem(.adaptive(minimum: 120), spacing: 15, alignment: .top)]
                }
            }
            else {
                //As many items with min size of 100 as can fit
                return [GridItem(.adaptive(minimum: 80), spacing: 10, alignment: .top)]
            }
        
        
        //return [GridItem(.adaptive(minimum: 100))]
    }
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
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
        selectPhotos(pageLayoutState: pageLayoutState)
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
                Spacer()
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
                    let isSelected = isSelected(photo)
                    PhotoCell(photo: $photo, isSelected: isSelected, showSelectButton: true, index: index, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                              onTapped: {
                        toggleSelection(for: photo)
                    })
                }
            }
            .noPhotosTipView(pageLayoutState: pageLayoutState)
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
                          message: L10n.DeletePhotosAlert.message(selections.count), isDestructive: false, yesAction: { deleteSelected() },
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

/*
 struct TitlesView_Previews: PreviewProvider {
 
 @ObservedObject static var pageLayoutState = PageLayoutState()
 
 static var previews: some View {
 TitlesView(pageLayoutState: pageLayoutState, dismissAction: {})
 }
 }
 */

