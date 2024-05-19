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

//typealias MainMenuViewOrChoiceBoardView = ChoiceBoardView
typealias MainMenuViewOrChoiceBoardView = MainMenuView

var audioHelper = AudioHelper()

struct ChoiceBoardView: View {

    @EnvironmentObject private var currentTheme: SharedUITheme

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
    
    init(topic: PECSRepo, action: Binding<MainMenuAction?>, isForSplitView: Bool) {
        pageLayoutState = PageLayoutState(topic: topic)
        self.isForSplitView = isForSplitView
    }
    
    var body: some View {
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
                              onTapped: {
                                playAudio(for: photo)
                    },
                              onDelete: nil, onRename: nil
                    )
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
        
        .navigationBarTitle(pageLayoutState.title, displayMode: .inline)
        .frame(maxWidth: .infinity)
        .padding()
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
    }
}
