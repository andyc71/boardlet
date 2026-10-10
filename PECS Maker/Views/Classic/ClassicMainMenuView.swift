//
//  PageSizeSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Photos
import PhotosUI
import StoreKit
import SharedSwiftUI
import LazyViewSwiftUI
import SwiftUIX
import LogFramework
import LogFrameworkFirebase
import SettingsFramework
import FeatureFramework
import AVFoundation
import MediaFramework
import UIKit

struct ClassicMainMenuView: View, Equatable {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    @EnvironmentObject private var navigationModel: NavigationModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    static func == (lhs: ClassicMainMenuView, rhs: ClassicMainMenuView) -> Bool {
        lhs.pageLayoutState.topic == rhs.pageLayoutState.topic
    }
    
    @Binding var appMode: PECSAppMode
    @Binding var action: MainMenuAction?
    
    @ObservedObject var pageLayoutState: PageLayoutState
    //@StateObject var pageLayoutState = PageLayoutState()
    //@StateObject var pageLayoutState: PageLayoutState
    //@StateObject var pageLayoutState: PageLayoutState
    
    
    var isForSplitView: Bool
    
    @State private var isShowingPicker = false
    @State private var isShowingStoreView = false
    @State private var showClearSelectionsPrompt = false
    @State private var showRenameAlert = false
    @State private var showTopicImageSelector = false
#if EasyPECSPlus
    @State private var showAACStandardSymbolsPicker = false
#endif
    @State private var showARASAACSymbolsPicker = false
    
    @State private var showRecommended = false
    
    var storeVC: SKStoreProductViewController {
        SKStoreProductViewController()
    }
    
    //let topic: PECSRepo

    /*
    init(pageLayoutState: PageLayoutState, action: Binding<MainMenuAction?>, isForSplitView: Bool) {
        self.pageLayoutState = pageLayoutState
        self._action = action
        self.isForSplitView = isForSplitView
        //print("***topicName: \(topic.topicName)")
        //print("***topicName: \(topic.topicName) - \(topic.id.uuidString)")
    }
    */

    init(pageLayoutState: PageLayoutState, appMode: Binding<PECSAppMode>, action: Binding<MainMenuAction?>, isForSplitView: Bool) {
        //self.pageLayoutState = PageLayoutState(
        //pageLayoutState.load(topic: topic)
        //_pageLayoutState = StateObject(wrappedValue: PageLayoutState(topic: topic))
        //_pageLayoutState = State(wrappedValue: PageLayoutState(topic: topic))
        self._appMode = appMode
        self.pageLayoutState = pageLayoutState
        //self.topic = topic
        self._action = action
        self.isForSplitView = isForSplitView
        //print("***topicName: \(topic.topicName)")
        //print("***topicName: \(topic.topicName) - \(topic.id.uuidString)")
    }
    
    func save() {
        DispatchQueue.main.async {
            self.pageLayoutState.save()
        }
    }

    private func selectMainMenuAction(_ newAction: MainMenuAction) {
        action = newAction
        if !isForSplitView {
            navigationModel.setMainMenuAction(newAction)
        }
    }

    private func openSettings() {
        MFAnalytics.logScreenView(screenName: MainMenuAction.settings.rawValue)
        featuresViewModel.logEvent()
        selectMainMenuAction(.settings)
    }

    private func openMoreApps() {
        DispatchQueue.main.async {
            MFAnalytics.logScreenView(screenName: "MoreApps")
            featuresViewModel.logEvent()
            showRecommended = true
        }
    }

//    var buttonWidth: CGFloat {
//        if isForSplitView {
//            return AppSettings.maxButtonWidth
//        }
//        else {
//            if isIPad {
//                return 600
//            }
//            else {
//                return AppSettings.maxButtonWidth
//            }
//        }
//    }
//
    var isLargeButton: Bool {
        if isForSplitView {
            return false
        }
        else {
            if isIPad {
                return true
            }
            else {
                return false
            }
        }
    }

    
    func makeMainMenuButton(action: MainMenuAction, actionFunction: (()->())? = nil, systemIconName: String, text: String, subtitle: String, emphasis: BoardActionButton.Emphasis = .standard) -> some View {
        BoardActionButton(action: actionFunction ?? {
            //If we're already on this screen, ignore a second button press.
            guard !isForSplitView || self.action != action else { return }
            MFAnalytics.logScreenView(screenName: action.rawValue)
            featuresViewModel.logEvent()
            selectMainMenuAction(action)
        }, icon: systemIconName, title: text, subtitle: subtitle, emphasis: emphasis,
           isSelected: self.action == action && isForSplitView,
           accessibilityHint: L10n.MainMenu.openActionHint)
    }

    private var photoStatus: String {
        let count = pageLayoutState.photoBrowserData.photoItems.count
        if count == 0 {
            return L10n.MainMenu.noPhotosStatus
        }
        if count == 1 {
            return L10n.MainMenu.onePhotoStatus
        }
        return L10n.MainMenu.photosSelectedStatus(count)
    }

    private var layoutStatus: String {
        let layout = pageLayoutState.pageLayout
        return L10n.MainMenu.layoutStatus(layout.width, layout.height)
    }

    private var titlesStatus: String {
        let hasPhotoTitles = pageLayoutState.photoBrowserData.photoItems.contains { !($0.title ?? "").isEmpty }
        let isOn = hasPhotoTitles || pageLayoutState.topic.formatting.pageTitleVisible
        return isOn ? L10n.MainMenu.titlesOnStatus : L10n.MainMenu.titlesOffStatus
    }

    private var previewStatus: String {
        return pageLayoutState.photoBrowserData.photoItems.isEmpty
            ? L10n.MainMenu.previewBlankStatus
            : L10n.MainMenu.previewReadyStatus
    }

    
    @State private var buttonMaxHeight: CGFloat?
    
    struct ButtonHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat,
                           nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
    
    
    //For a VGrid we are specifying max width. Item height should be equal.
    private var buttonColumn: GridItem {
        GridItem(.flexible(minimum: 0, maximum: 200))
    }
        
    private var symbolSearchAction: (() -> Void)? {
        guard FeatureFlags.current.arasaacSymbolsEnabled else { return nil }
        return {
            MFAnalytics.logScreenView(screenName: "ARASAACSymbolSearchFromMainMenu")
            featuresViewModel.logEvent()
            showARASAACSymbolsPicker = true
        }

    }

    private func buttonView(spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            if isForSplitView {
                makeMainMenuButton(action: .changeSelections,
                                   systemIconName: "photo.on.rectangle",
                                   text: L10n.MainMenu.photosCardTitle,
                                   subtitle: photoStatus)
                    .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectPhotoButton)
                if pageLayoutState.photoBrowserData.photoItems.isEmpty {
                    if let symbolSearchAction {
                        CapsuleButton(L10n.MainMenu.symbolSearchButton,
                                      role: .secondary,
                                      action: symbolSearchAction)
                            .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.symbolSearchButton)
                            .accessibilityHint(L10n.MainMenu.symbolSearchHint)
                    }
#if EasyPECSPlus
                    CapsuleButton(L10n.Symbols.aacStandard, role: .secondary) {
                        showAACStandardSymbolsPicker = true
                    }
                    .accessibilityIdentifier("aacStandardSymbolSearchButton")
#endif
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        CapsuleButton(L10n.MainMenu.takePhotoButton,
                                      role: .secondary,
                                      action: {
                            MFAnalytics.logScreenView(screenName: "takePhotoFromMainMenu")
                            featuresViewModel.logEvent()
                            takeBoardPhoto(pageLayoutState: pageLayoutState)
                        })
                            .accessibilityIdentifier("takeBoardPhoto")
                            .accessibilityHint(L10n.MainMenu.takePhotoHint)
                    }
                }
            } else {
                BoardPhotoCard(
                    pageLayoutState: pageLayoutState,
                    photos: pageLayoutState.photoBrowserData.photoItems,
                    status: photoStatus,
                    changeSelections: {
                        MFAnalytics.logScreenView(screenName: "PhotoListView")
                        featuresViewModel.logEvent()
                        selectMainMenuAction(.changeSelections)
                    }
                )
            }

            makeMainMenuButton(action: .selectLayout,
                               systemIconName: "square.grid.2x2",
                               text: L10n.MainMenu.layoutCardTitle,
                               subtitle: layoutStatus)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectLayoutButton)

            makeMainMenuButton(action: .titles,
                               systemIconName: "textformat",
                               text: L10n.MainMenu.titlesCardTitle,
                               subtitle: titlesStatus)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectTitlesButton)

            previewAndPrintButton
        }
    }

    private var previewAndPrintButton: some View {
        makeMainMenuButton(action: .print,
                           systemIconName: "printer",
                           text: L10n.MainMenu.printButton,
                           subtitle: previewStatus)
            .accessibility(identifier: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
    }

    @ViewBuilder
    private var mainMenuMessages: some View {
        if AppSettings.showTopicDebugInfo {
            let topic = pageLayoutState.topic
            Text(topic.topicName)
            Text("Photo count: \(topic.photos.photoItems.count)")
        }

        if let lastError = pageLayoutState.lastError {
            ErrorView(message: lastError.localizedDescription, closeAction: {
                withAnimation { pageLayoutState.lastError = nil }
            })
        }
    }

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    private var isIOS16 : Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        else {
            return false
        }
    }
    
    private var columns: [GridItem] {
        
        //The sizes are based purely on what looks good for the screenshots on
        //the main supported devices.
        
        if isForSplitView {
            //One fixed-width column for split view.
            return [GridItem(.fixed(350))]
        }
        else {
            if isIPad {
                //return [GridItem(.adaptive(minimum: 200), spacing: 15, alignment: .top)]
                return [GridItem(.fixed(350)), GridItem(.fixed(350))]
            }
            else {
                //As many items with min size of 100 as can fit
                return [GridItem(.adaptive(minimum: 100), spacing: 10, alignment: .top)]
            }
        }
        
        //return [GridItem(.adaptive(minimum: 100))]
    }

    @ToolbarContentBuilder
    var toolbarItems: some ToolbarContent {
        
        if !isForSplitView {
            ToolbarItem(placement: .navigation) {
                BoardNavigationControl(icon: "chevron.left",
                                       label: L10n.MainMenu.back,
                                       action: { dismiss() })
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            //Menu(systemImage: .ellipsis) {
            Menu{
                Button(L10n.MainMenu.renameButton, systemImage: SFSymbolName.pencil) {
                    showRenameAlert.toggle()
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.renameButton)
                
                Button(L10n.MainMenu.changeTopicImageButton, systemImage: SFSymbolName.photo) {
                    //showTopicImageSelector.toggle()
                    selectMainMenuAction(.changeTopicIcon)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.changeTopicImageButton)

                Divider()

                Button(L10n.MainMenu.settingsButton, systemImage: "gear") {
                    openSettings()
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.settingsButton)

                Button(L10n.MainMenu.moreAppsButton, systemImage: "app.gift") {
                    openMoreApps()
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.moreAppsButton)
            } label: {
                BoardNavigationIcon(icon: "ellipsis")
                    .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.menuButton)
            }
            .accessibilityLabel(L10n.MainMenu.moreOptions)
        }

        if FeatureFlags.current.voiceEnabled {
            if #available(iOS 26.0, *) {
                ToolbarSpacer(placement: .primaryAction)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(L10n.MainMenu.choiceBoardButton) {
                    navigationModel.enterChoiceBoard(returningTo: nil)
                    withAnimation {
                        self.appMode = .choiceBoard
                    }
                }
                .toolbarButtonStyle()
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.choiceBoardButton)
            }
        }

    }
    
    var body: some View {
        GeometryReader { geometry in
            let isPortraitColumn = geometry.size.height > geometry.size.width
            let usesSpaciousLayout = horizontalSizeClass == .regular
                && geometry.size.width >= 700
                && isPortraitColumn

            if usesSpaciousLayout {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        mainMenuMessages
                        buttonView(spacing: 20)
                    }
                    .padding(16)
                    .frame(maxWidth: min(700, max(500, geometry.size.width * 0.72)))
                    .frame(maxWidth: .infinity)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    mainMenuMessages
                    buttonView(spacing: 16)
                        .padding()
                }
                .frame(maxWidth: isPortraitColumn || horizontalSizeClass == .regular
                    ? 500 : AppSettings.maxViewWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
#if EasyPECSPlus
        .selectAACStandardSymbols(isPresented: $showAACStandardSymbolsPicker,
                                  pageLayoutState: pageLayoutState,
                                  isAdditive: AppSettings.photoPickerIsAdditive)
#endif
        .selectARASAACSymbols(isPresented: $showARASAACSymbolsPicker,
                              pageLayoutState: pageLayoutState,
                              isAdditive: AppSettings.photoPickerIsAdditive)
        
#if AppHasTopics
        .navigationTitle(pageLayoutState.topic.topicName)
        .navigationBarBackButtonHidden(!isForSplitView)
        .toolbar{ toolbarItems }
        .renameItemAlert(isPresented: $showRenameAlert, itemName: $pageLayoutState.title, placeholder: L10n.RenameTopicAlert.placeholder, title: L10n.RenameTopicAlert.title, message: nil, theme: currentTheme, saveAction: { pageLayoutState.save() })
#else
        .navigationTitle(AppInformation.appName)
#endif
        
#if EasyPECSPlus
        .navigationBarTitleDisplayMode(.large)
#else
        .navigationBarTitleDisplayMode(.inline)
#endif
        
        /* 
         // We used to store the current menu page in the pageLayoutState, but
         // it stops the ChoiceBoard having the option to move straight to the
         // change selections view. This would be easier to implement in IOS16
         // because we can bind the NavigationStack directly to the mainMenuAction
         // instead of going via this screen.
        .onChange(of: action) { newValue in
            pageLayoutState.topic.mainMenuAction = newValue
            pageLayoutState.save()
        }
         */
        .overlay {
            StoreView(storeItemID: AppSettings.shared.developerID,
                dismissHandler: { showRecommended = false }
            )
            .hidden(showRecommended == false)
            //.isHidden(false, remove: true)
        }
//        .appStoreOverlay(isPresented: $showRecommended) {
//            SKOverlay.AppConfiguration(appIdentifier: "1440611372", position: .bottom)
//        }
        /*
        .userActivity(PECSStateRestoration.activityKey, element: action) { menuAction, userActivity in
            do {
                try userActivity.setTypedPayload( PECSStateRestoration(topicName: pageLayoutState.topic.topicName, mainMenuAction: action ))
            }
            catch {
                logger.logError(.background, "Unable to save application state", error)
            }
        }
         */

        
    }
    
    private var col: GridItem {
        GridItem(.flexible(minimum: 0, maximum: 200))
    }
    
    
}

