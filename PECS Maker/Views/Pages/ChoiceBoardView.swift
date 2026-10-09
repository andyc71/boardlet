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

struct ChoiceBoardView: View, PhotoCellActionDelegate {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var navigationModel: NavigationModel
    @Environment(\.locale) private var locale
    @AppStorage(ChoiceBoardVoicePreference.storageKey) private var selectedVoiceIdentifier = ""
    @AppStorage(ChoiceBoardVoicePreference.localeStorageKey) private var selectedVoiceLocale = ""

    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @ObservedObject var pageLayoutState: PageLayoutState
    var isForSplitView: Bool

    @State var showTopicSelectionAlert: Bool = false
    @State private var showVoicePicker = false
#if EasyPECSPlus
    @State private var showAACStandardSymbolsPicker = false
    @State private var showDVSymbolsPicker = false
    @State private var showAISymbolsPicker = false
#endif
    @State private var showARASAACSymbolsPicker = false
    
    
    private var speechLocale: String {
        selectedVoiceLocale.isEmpty
            ? ChoiceBoardVoicePreference.normalizedLocale(locale.identifier)
            : selectedVoiceLocale
    }
    
    func playAudio(for photoItem: PhotoItem) {
        guard FeatureFlags.current.voiceEnabled else { return }
        if let audioURL = photoItem.audioURL {
            audioHelper.playAudio(contentsOf: audioURL, canBeMuted: true)
        }
        else if let title = photoItem.title {
            audioHelper.speak(title, canBeMuted: true,
                              voiceIdentifier: selectedVoiceIdentifier, language: speechLocale)
        }
    }
    
    private var cardAspectRatio: CGFloat {
        let size = pageLayoutState.individualCardMeasurements.sizeInMM
        return size.height > 0 ? size.width / size.height : 1
    }

    func speakSelectedItems() {
        guard FeatureFlags.current.voiceEnabled else { return }
        let text = selectedItems.reduce("") { text, item in
            guard let title = item.title else { return text }
            return text + title + " "
        }
        audioHelper.speak(text, canBeMuted: true,
                          voiceIdentifier: selectedVoiceIdentifier, language: speechLocale)
    }
    
    init(pageLayoutState: PageLayoutState, appMode: Binding<PECSAppMode>, action: Binding<MainMenuAction?>, selectedItems: Binding<[PhotoItem]>, isForSplitView: Bool) {
        self._appMode = appMode
        self._mainMenuAction = action
        self._selectedItems = selectedItems
        self.pageLayoutState = pageLayoutState
        self.isForSplitView = isForSplitView
    }
    
    var selectedItemsView : some View {
        HStack(spacing: 8) {
            Button(systemImage: .textBubble, action: {
                speakSelectedItems()
            })
            .imageScale(.large)
            .foregroundColor(Color(currentTheme.linkTextColor))
            .disabled(selectedItems.isEmpty)
            .padding(.vertical, 8)

            HStack {
                if selectedItems.isEmpty {
                    Color.systemBackground.height(60)
                }
                ForEach(selectedItems) { item in
                    ImageViewAsync(symbol: item, size: CGSize(width: 60, height: 60))
                        .background(AppSettings.photoBackgroundColor)
                    //Make sure all the items are square.
                    //.aspectRatio(1, contentMode: .fit)
                    
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.systemBackground)
            .height(60)

            Button(systemImage: .deleteLeft, action: {
                selectedItems.removeLast()
            })
            .imageScale(.large)
            .foregroundColor(.red)
            .padding(.vertical, 8)
            .disabled(selectedItems.isEmpty)
            
        }
    }
    
    var body: some View {
        VStack {
            selectedItemsView
            
            
            GeometryReader { geometry in
                let photoItems = pageLayoutState.photoBrowserData.photoItems
                let cardsPerPage = max(pageLayoutState.pageLayout.total, 1)
                let pageCount = max(1, (photoItems.count + cardsPerPage - 1) / cardsPerPage)
                let screenLayout = pageLayoutState.pageLayout.screenLayout(in: geometry.size,
                                                                           cardAspectRatio: cardAspectRatio)
                let pageSize = screenLayout.pageSize
                let cardSize = CGSize(width: pageSize.width / CGFloat(max(pageLayoutState.pageLayout.width, 1)),
                                      height: pageSize.height / CGFloat(max(pageLayoutState.pageLayout.height, 1)))
                let columns = Array(repeating: GridItem(.fixed(cardSize.width), spacing: 0),
                                    count: max(pageLayoutState.pageLayout.width, 1))

                let pages = ForEach(0..<pageCount, id: \.self) { page in
                    let firstIndex = page * cardsPerPage
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(0..<cardsPerPage, id: \.self) { slot in
                            let index = firstIndex + slot
                            Group {
                                if index < photoItems.count {
                                    PhotoCell<PhotoItem>(item: photoItems[index], isSelected: false,
                                                         showSelectButton: false, showDeleteButton: false,
                                                         index: index, useFitzgeraldKeys: pageLayoutState.useFitzgeraldKey,
                                                         untitledLabel: L10n.PhotoSelectionView.untitledCell,
                                                         canRenameItem: false, delegate: self)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppSettings.pageColor)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(Color.secondary.opacity(0.4))
                                        }
                                        .hidden()
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(width: cardSize.width, height: cardSize.height)
                            .clipped()
                        }
                    }
                    .frame(width: pageSize.width, height: pageSize.height)
                    .background(AppSettings.pageColor.opacity(0.15))
                    .overlay {
                        Rectangle().strokeBorder(Color.secondary.opacity(0.3))
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.ChoiceBoard.page(for: page))
                    .accessibilityValue(L10n.MainMenu.layoutStatus(pageLayoutState.pageLayout.width,
                                                                    pageLayoutState.pageLayout.height))
                }
                ScrollView(screenLayout.scrollHorizontally ? .horizontal : .vertical) {
                    Group {
                        if screenLayout.scrollHorizontally {
                            LazyHStack(spacing: 24) {
                                if AppSettings.showTopicDebugInfo {
                                    let topic = pageLayoutState.topic
                                    Text(topic.topicName)
                                    Text("Photo count: \(topic.photos.photoItems.count)")
                                }
                                pages
                            }
                        } else {
                            LazyVStack(spacing: 24) {
                                if AppSettings.showTopicDebugInfo {
                                    let topic = pageLayoutState.topic
                                    Text(topic.topicName)
                                    Text("Photo count: \(topic.photos.photoItems.count)")
                                }
                                pages
                            }
                        }
                    }
                    .padding(8)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                    .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.collectionView)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.ChoiceBoard.boardScrollView)
                .sheet(isPresented: $showTopicSelectionAlert) {
                    //                TopicAlertView(isPresented: $showTopicSelectionAlert, title: L10n.CopyPhotoList.title(selections.count), exclude: [pageLayoutState.topic], onSelectTopic: { topic in
                    //                    //copySelected(to: topic)
                    //                })
                }
            }
        }
        .navigationBarTitle(pageLayoutState.title, displayMode: .large)
        .boardBackButton(isPresented: !isForSplitView)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button(L10n.MainMenu.changeVoiceButton, systemImage: "waveform") {
                        showVoicePicker = true
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.changeVoiceButton)
                    Button(L10n.PhotoSelectionView.photoLibrary, systemImage: "photo") {
                        selectPhotos(pageLayoutState: pageLayoutState, isAdditive: true,
                                     currentTheme: currentTheme)
                    }
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button(L10n.PhotoSelectionView.camera, systemImage: "camera") {
                            takeBoardPhoto(pageLayoutState: pageLayoutState)
                        }
                    }
#if EasyPECSPlus
                    Button(L10n.Symbols.aacStandard) { showAACStandardSymbolsPicker = true }
                    Button("Dynavox") { showDVSymbolsPicker = true }
                    Button("Create with AI") { showAISymbolsPicker = true }
#endif
                    if FeatureFlags.current.arasaacSymbolsEnabled {
                        Button(L10n.Symbols.arasaac) { showARASAACSymbolsPicker = true }
                    }
                } label: {
                    BoardNavigationIcon(icon: "ellipsis")
                        .accessibilityIdentifier(AccessibilityIdentifiers.ChoiceBoard.menuButton)
                }
                .accessibilityLabel(L10n.MainMenu.moreOptions)

                Button(L10n.MainMenu.pecsMakerButton) {
                    let returnAction = navigationModel.takeChoiceBoardReturnAction()
                    withAnimation {
                        self.appMode = .pecsMaker
                        if let returnAction {
                            if isForSplitView {
                                mainMenuAction = returnAction
                            } else {
                                navigationModel.setMainMenuAction(returnAction)
                            }
                        }
                    }
                }
                .toolbarButtonStyle()
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.pecsMakerButton)
            }
        }
        .sheet(isPresented: $showVoicePicker) {
            ChoiceBoardVoicePicker()
        }
#if EasyPECSPlus
        .selectAACStandardSymbols(isPresented: $showAACStandardSymbolsPicker,
                                  pageLayoutState: pageLayoutState, isAdditive: true)
        .selectDVSymbols(isPresented: $showDVSymbolsPicker,
                         pageLayoutState: pageLayoutState, isAdditive: true)
        .selectAISymbols(isPresented: $showAISymbolsPicker,
                         pageLayoutState: pageLayoutState, isAdditive: true)
#endif
        .selectARASAACSymbols(isPresented: $showARASAACSymbolsPicker,
                              pageLayoutState: pageLayoutState, isAdditive: true)
        .frame(maxWidth: .infinity)
        .padding()
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
    }
    
    func onPhotoTapped(photo: any SharedSwiftUI.ImagePickerItem) {
        guard let photo = photo as? PhotoItem else { return }
        playAudio(for: photo)
        selectedItems.append(photo)
    }
    
    func onPhotoSelected(photo: any SharedSwiftUI.ImagePickerItem) {
    }
    
    func onDuplicatePhoto(photo: any SharedSwiftUI.ImagePickerItem) {
    }
    
    func onDeletePhotoSelected(photo: any SharedSwiftUI.ImagePickerItem) {
    }
    
    func onRenamePhotoSelected(photo: any SharedSwiftUI.ImagePickerItem) {
    }

}
