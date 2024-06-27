//
//  ChoiceBoardView.swift
//  PECS Maker
//
//  Created by Andy on 16/07/2023.
//

import SwiftUI
import PhotosUI
import LogFramework
import SharedSwiftUI
import SFSafeSymbols
import MediaFramework

var audioHelper = AudioHelper()

struct ChoiceBoardView: View {

    @EnvironmentObject private var currentTheme: SharedUITheme

    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @ObservedObject var pageLayoutState: PageLayoutState
    var isForSplitView: Bool

    @State var showTopicSelectionAlert: Bool = false
    
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    func playAudio(for photoItem: PhotoItem) {
        if let audioURL = photoItem.audioURL {
            audioHelper.playAudio(contentsOf: audioURL)
        }
        else if let title = photoItem.title {
            audioHelper.speak(title)
        }
    }
    
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
    
    func speakSelectedItems() {
        let text = selectedItems.reduce("") { text, item in
            guard let title = item.title else { return text }
            return text + title + " "
        }
        audioHelper.speak(text)
    }
    
    init(topic: PECSRepo, appMode: Binding<PECSAppMode>, action: Binding<MainMenuAction?>, selectedItems: Binding<[PhotoItem]>, isForSplitView: Bool) {
        self._appMode = appMode
        self._mainMenuAction = action
        self._selectedItems = selectedItems
        pageLayoutState = PageLayoutState(topic: topic)
        self.isForSplitView = isForSplitView
    }
    
    var selectedItemsView : some View {
        HStack {
            Color.white.opacity(0).width(12)
            
            Button(systemImage: .textBubble, action: {
                speakSelectedItems()
            })
            .imageScale(.large)
            .foregroundColor(Color(currentTheme.linkTextColor))
            .padding(.vertical, 8)
            .disabled(selectedItems.isEmpty)
            
            ForEach(selectedItems) { item in
                ImageViewAsync(symbol: item, size: CGSize(width: 60, height: 60))
                //Make sure all the items are square.
                //.aspectRatio(1, contentMode: .fit)
                
            }
            .padding(.vertical, 8)
            Spacer()

            Button(systemImage: .deleteLeft, action: {
                    selectedItems.removeLast()
                })
                .imageScale(.large)
                .foregroundColor(.red)
                .padding(.vertical, 8)
                .disabled(selectedItems.isEmpty)
            
        
            Color.white.opacity(0).width(12)
        }
        .frame(height: 60)
        .background(Color.systemBackground)
    }
    
    var body: some View {
        VStack {
            selectedItemsView
            
            
            ScrollView {
                
                if AppSettings.showTopicDebugInfo {
                    let topic = pageLayoutState.topic
                    Text(topic.topicName)
                    Text("Photo count: \(topic.photos.photoItems.count)")
                }
                
                LazyVGrid(columns: self.columns, spacing: 0) {
                    
                    ForEach($pageLayoutState.photoBrowserData.photoItems) { $photo in
                        let index = pageLayoutState.photoBrowserData.photoItems.firstIndex(where: {$0.id==photo.id})
                        PhotoCell<PhotoItem>(item: photo, isSelected: false, showSelectButton: false, showDeleteButton: false, index: index, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                                             untitledLabel: L10n.PhotoSelectionView.untitledCell,
                                             deleteMessage: L10n.DeletePhotoAlert.message,
                                             canRenameItem: false,
                                             autoCapitalize: false,
                                             renameAlertMessage: L10n.RenamePhotoAlert.title,
                                             renameAlertPlaceholderText: L10n.RenamePhotoAlert.placeholder,
                                             onTap: {
                            playAudio(for: photo)
                            selectedItems.append(photo)
                        },
                                             onDelete: nil, onRename: nil
                        )
                        //Make sure all the items are square.
                        .aspectRatio(1, contentMode: .fit)
                        .padding(12)
                    }
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.collectionView)
                //.noPhotosTipView(pageLayoutState: pageLayoutState)
                .sheet(isPresented: $showTopicSelectionAlert) {
                    //                TopicAlertView(isPresented: $showTopicSelectionAlert, title: L10n.CopyPhotoList.title(selections.count), exclude: [pageLayoutState.topic], onSelectTopic: { topic in
                    //                    //copySelected(to: topic)
                    //                })
                }
                
                .padding(8)
                .padding(.top, 8)
                
            }
        }
        .navigationBarTitle(pageLayoutState.title, displayMode: .large)
        .toolbar {
            Button(L10n.MainMenu.pecsMakerButton) {
                //Button(systemImage: SFSymbolName.pencil) {
                self.mainMenuAction = .changeSelections
                self.appMode = .pecsMaker
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.pecsMakerButton)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
    }
}
