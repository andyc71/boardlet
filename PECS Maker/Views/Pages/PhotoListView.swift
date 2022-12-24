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
    
    var dismissAction: ()->()
    
    let gridItem = GridItem(.flexible())
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
    }
    
    func toggleSelection(for photo: PhotoItem) {
        if selections.contains(photo) {
            selections.removeAll { $0 == photo }
        }
        else {
            selections.append(photo)
        }
    }
    
    func isSelected(_ photo: PhotoItem) -> Bool {
        return selections.contains(photo)
    }
    
    func deleteSelected() {
        pageLayoutState.photoBrowserData.deletePhotos(selections)
        for photo in selections {
            selections.removeAll { $0 == photo }
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

    
    @StateObject var pls2 = PageLayoutState()
    
    func copySelected(to topic: PECSRepo) {

        //Can't load PageLayoutState here becuse the add photo
        //happens asynchronously and the PLS will go out of scope
        //and not save the photo repo if we don't have it as a
        //state variable.
        //let pls = PageLayoutState(topic: topic)
        pls2.load(topic: topic)
        pls2.photoBrowserData.add(selections)
        
        showTopicSelectionAlert = false
        showPhotoCopySuccessAlert = true
        
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: self.columns) {
                ForEach($pageLayoutState.photoBrowserData.photoItems) { $photo in
                    let index = pageLayoutState.photoBrowserData.photoItems.firstIndex(of: photo)
                    PhotoCell(photo: $photo, isSelected: isSelected(photo), index: index, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                              onTapped: {
                        toggleSelection(for: photo)
                    })
                    //.padding(8)
                }
            }
            .sheet(isPresented: $showTopicSelectionAlert) {
                TopicAlertView(isPresented: $showTopicSelectionAlert, title: L10n.CopyPhotoList.title(selections.count), exclude: [pageLayoutState.topic!], onSelectTopic: { topic in
                    copySelected(to: topic)
                })
            }
        }
        
        .askQuestionYesNo(isPresented: $showDeleteSelectionAlert, title: nil,
                          message: L10n.DeletePhotoAlert.message(selections.count), isDestructive: false, yesAction: { deleteSelected() },
            noAction: { } )

        .successAlert(isPresented: $showPhotoCopySuccessAlert, title: "Photo Copied")
        //.navigationBarTitle(Text(L10n.PhotoSelectionView.title), displayMode: .inline)
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
                    
                Button(systemImage: /*SFSymbolName.trash*/ SFSymbolName.xmark, action: {
                        showDeleteSelectionAlert = true
                    })
                    //.buttonStyle(MFPlainButtonStyle(purpose: .destructive))
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.deleteButton)
                    .hidden(selections.count == 0)
                    
                    Spacer()
                    
                    Button(systemImage: SFSymbolName.plusRectangleOnRectangle, action: {
                        showTopicSelectionAlert = true
                    })
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
                    .accessibility(identifier: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
                    .accessibilityLabel(L10n.PhotoSelectionView.copyButton)
                    .hidden(selections.count == 0)

                    Spacer()
                    
                    Button(systemImage: SFSymbolName.docOnDoc, action: {
                        duplicateSelected()
                    })
                    .buttonStyle(MFPlainButtonStyle(purpose: .secondary))
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

