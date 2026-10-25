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
import AVFoundation

var audioHelper = AudioHelper()

struct ChoiceBoardView: View, PhotoCellActionDelegate {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var presentationContext: ScenePresentationContext
    @Environment(\.locale) private var locale
    @AppStorage(ChoiceBoardVoicePreference.storageKey) private var selectedVoiceIdentifier = ""
    @AppStorage(ChoiceBoardVoicePreference.localeStorageKey) private var selectedVoiceLocale = ""

    @Binding var appMode: PECSAppMode
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var selectedItems: [PhotoItem]
    @EnvironmentObject private var navigationModel: NavigationModel
    @ObservedObject var pageLayoutState: PageLayoutState
    var isForSplitView: Bool

    @AppStorage(PageLayoutMedium.storageKey) private var medium = PageLayoutMedium.preferred()
    @AppStorage(PageLayoutMedium.automaticKey) private var automatic = true
    @AppStorage(PageLayoutMedium.screenLayoutKey) private var screenLayoutData = Data()
    @State private var usableFrame = CGRect.zero

    private var effectiveLayout: PageLayoutType {
        guard medium == .screen else { return pageLayoutState.pageLayout }
        return automatic ? PageLayoutMedium.automaticLayout(in: usableFrame.size)
            : PageLayoutMedium.predefinedLayout(data: screenLayoutData, viewport: usableFrame.size)
    }

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
                              voiceIdentifier: voiceIdentifier(for: photoItem), language: photoItem.resolvedTextLanguage ?? speechLocale)
        }
    }
    
    private func voiceIdentifier(for item: PhotoItem) -> String? {
        guard let resolved = item.resolvedTextLanguage else { return selectedVoiceIdentifier }
        let voiceLanguage = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)?.language ?? speechLocale
        return BoardLanguage.candidates(for: voiceLanguage).contains(resolved) ? selectedVoiceIdentifier : nil
    }

    private var cardAspectRatio: CGFloat {
        if medium == .screen {
            if automatic || effectiveLayout.fixedCardAspectRatio != nil { return 1 }
            return (max(1, usableFrame.width - 16) / CGFloat(effectiveLayout.width))
                / (max(1, usableFrame.height - 16) / CGFloat(effectiveLayout.height))
        }
        let size = pageLayoutState.individualCardMeasurements.sizeInMM
        return size.height > 0 ? size.width / size.height : 1
    }

    func speakSelectedItems() {
        guard FeatureFlags.current.voiceEnabled else { return }
        for item in selectedItems {
            guard let title = item.title else { continue }
            audioHelper.speak(title, canBeMuted: true, voiceIdentifier: voiceIdentifier(for: item),
                              language: item.resolvedTextLanguage ?? speechLocale)
        }
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

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        if selectedItems.isEmpty {
                            Color.systemBackground
                                .frame(width: 1, height: 60)
                        }
                        ForEach(selectedItems) { item in
                            ImageViewAsync(symbol: item, size: CGSize(width: 60, height: 60))
                                .background(AppSettings.photoBackgroundColor)
                                .id(item.itemID)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: selectedItems.count) { _ in
                    guard let lastID = selectedItems.last?.itemID else { return }
                    withAnimation { proxy.scrollTo(lastID, anchor: .trailing) }
                }
            }
            .background(Color.systemBackground)
            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 76)

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
            
            
            Color.clear
                .onGeometryChange(for: CGRect.self) { geometry in
                    usableBoardFrame(in: geometry)
                } action: { usableFrame = $0 }
                .overlay(alignment: .topLeading) {
                let photoItems = pageLayoutState.photoBrowserData.photoItems
                let cardsPerPage = max(effectiveLayout.total, 1)
                let pageCount = max(1, (photoItems.count + cardsPerPage - 1) / cardsPerPage)
                let screenLayout = effectiveLayout.screenLayout(in: usableFrame.size,
                                                                           cardAspectRatio: cardAspectRatio)
                let pageSize = screenLayout.pageSize
                let cardSize = CGSize(width: pageSize.width / CGFloat(max(effectiveLayout.width, 1)),
                                      height: pageSize.height / CGFloat(max(effectiveLayout.height, 1)))
                let columns = Array(repeating: GridItem(.fixed(cardSize.width), spacing: 0),
                                    count: max(effectiveLayout.width, 1))

                let pages = ForEach(0..<pageCount, id: \.self) { page in
                    let firstIndex = page * cardsPerPage
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(0..<cardsPerPage, id: \.self) { slot in
                            let index = firstIndex + slot
                            Group {
                                if index < photoItems.count {
                                    PhotoCell<PhotoItem>(item: photoItems[index], isSelected: navigationModel.selectedPhotoIDs.contains(photoItems[index].itemID),
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
                    .id(page)
                    .accessibilityIdentifier(AccessibilityIdentifiers.ChoiceBoard.page(for: page))
                    .accessibilityValue(L10n.MainMenu.layoutStatus(effectiveLayout.width, effectiveLayout.height))
                }
                ScrollViewReader { proxy in
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
                    .frame(minWidth: usableFrame.width, minHeight: usableFrame.height)
                    .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.collectionView)
                }
                .onChange(of: navigationModel.selectedPhotoIDs) { ids in
                    if let index = photoItems.firstIndex(where: { ids.contains($0.itemID) }) { proxy.scrollTo(index / cardsPerPage, anchor: .topLeading) }
                }
                .onAppear {
                    if let index = photoItems.firstIndex(where: { navigationModel.selectedPhotoIDs.contains($0.itemID) }) { proxy.scrollTo(index / cardsPerPage, anchor: .topLeading) }
                }
                }
                .frame(width: usableFrame.width, height: usableFrame.height)
                .position(x: usableFrame.midX, y: usableFrame.midY)
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
            if #available(iOS 27.0, *) {
                ToolbarOverflowMenu {
                    choiceBoardMoreActions
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                Menu {
                    choiceBoardMoreActions
                } label: {
                    Label(L10n.MainMenu.moreOptions, systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(L10n.MainMenu.moreOptions)
                .accessibilityIdentifier(AccessibilityIdentifiers.ChoiceBoard.menuButton)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button(L10n.MainMenu.pecsMakerButton, systemImage: "square.grid.2x2",
                       action: returnToPECSMaker)
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

    @ViewBuilder
    private var choiceBoardMoreActions: some View {
        Button(L10n.MainMenu.changeVoiceButton, systemImage: "waveform") {
            showVoicePicker = true
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.changeVoiceButton)
        Button(L10n.PhotoSelectionView.photoLibrary, systemImage: "photo") {
            guard let presenter = presentationContext.presenter else { return }
            selectPhotos(pageLayoutState: pageLayoutState, isAdditive: true,
                         currentTheme: currentTheme, from: presenter)
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Button(L10n.PhotoSelectionView.camera, systemImage: "camera") {
                guard let presenter = presentationContext.presenter else { return }
                takeBoardPhoto(pageLayoutState: pageLayoutState, from: presenter)
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
    }

    private func returnToPECSMaker() {
        let returnAction = navigationModel.takeChoiceBoardReturnAction()
        withAnimation {
            appMode = .pecsMaker
            if let returnAction {
                navigationModel.setMainMenuAction(returnAction)
            }
        }
    }

    private func usableBoardFrame(in geometry: GeometryProxy) -> CGRect {
        let bounds = CGRect(origin: .zero, size: geometry.size)
        guard #available(iOS 27.1, *),
              let region = geometry.reservedRegions(kind: .division).first(where: \.isActive)
        else { return bounds }

        let blocked = CGRect(
            x: region.frame.minX - region.margins.leading,
            y: region.frame.minY - region.margins.top,
            width: region.frame.width + region.margins.leading + region.margins.trailing,
            height: region.frame.height + region.margins.top + region.margins.bottom
        ).intersection(bounds)

        let candidates: [CGRect]
        if blocked.height >= blocked.width {
            candidates = [
                CGRect(x: bounds.minX, y: bounds.minY,
                       width: max(0, blocked.minX - bounds.minX), height: bounds.height),
                CGRect(x: blocked.maxX, y: bounds.minY,
                       width: max(0, bounds.maxX - blocked.maxX), height: bounds.height)
            ]
        } else {
            candidates = [
                CGRect(x: bounds.minX, y: bounds.minY,
                       width: bounds.width, height: max(0, blocked.minY - bounds.minY)),
                CGRect(x: bounds.minX, y: blocked.maxY,
                       width: bounds.width, height: max(0, bounds.maxY - blocked.maxY))
            ]
        }
        return candidates.max { $0.width * $0.height < $1.width * $1.height } ?? bounds
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
