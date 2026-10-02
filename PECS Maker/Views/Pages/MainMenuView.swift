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

enum MainMenuAction : String, Codable { case changeTopicIcon, selectPhoto, selectLayout, titles, changeSelections, print, settings }

enum ChoiceBoardVoicePreference {
    static let storageKey = "choiceBoardVoiceIdentifier"
    static let localeStorageKey = "choiceBoardVoiceLocale"

    static func normalizedLocale(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "_", with: "-")
    }

    static func languageCode(for locale: String) -> String {
        normalizedLocale(locale).split(separator: "-").first.map(String.init) ?? locale
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue()) // set the `max` value (from both buttons)
    }
}

struct MainMenuView: View, Equatable {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    @EnvironmentObject private var navigationModel: NavigationModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    static func == (lhs: MainMenuView, rhs: MainMenuView) -> Bool {
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

private struct VoiceLocaleGroup: Identifiable {
    let locale: String
    let voices: [AVSpeechSynthesisVoice]

    var id: String { locale }
}

private enum PersonalVoiceAccess {
    case notDetermined
    case authorized
    case denied
    case unsupported

    static var current: Self {
        guard #available(iOS 17.0, *) else { return .unsupported }
        switch AVSpeechSynthesizer.personalVoiceAuthorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .unsupported: return .unsupported
        @unknown default: return .unsupported
        }
    }
}

struct ChoiceBoardVoicePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(ChoiceBoardVoicePreference.storageKey) private var selectedVoiceIdentifier = ""
    @AppStorage(ChoiceBoardVoicePreference.localeStorageKey) private var selectedVoiceLocale = ""
    @State private var previewAudioHelper = AudioHelper()
    @State private var showMoreVoicesHelp = false
    @State private var showPersonalVoiceHelp = false
    @State private var personalVoiceAccess = PersonalVoiceAccess.current
    @State private var voices = AVSpeechSynthesisVoice.speechVoices()

    private func refreshVoices() {
        personalVoiceAccess = PersonalVoiceAccess.current
        voices = AVSpeechSynthesisVoice.speechVoices()
        if !selectedVoiceIdentifier.isEmpty,
           !voices.contains(where: { $0.identifier == selectedVoiceIdentifier }) {
            selectedVoiceIdentifier = ""
        }
    }

    private func requestPersonalVoiceAccess() {
        guard #available(iOS 17.0, *) else { return }
        Task { @MainActor in
            _ = await AVSpeechSynthesizer.requestPersonalVoiceAuthorization()
            refreshVoices()
        }
    }

    private func preview(_ voice: AVSpeechSynthesisVoice?) {
        guard let voice else { return }
        previewAudioHelper.cancelSpeech()
        previewAudioHelper.speak("1, 2, 3.", canBeMuted: true, voiceIdentifier: voice.identifier)
    }

    private var appVoiceLocale: String {
        ChoiceBoardVoicePreference.normalizedLocale(locale.identifier)
    }

    private var activeVoiceLocale: String {
        selectedVoiceLocale.isEmpty ? appVoiceLocale : selectedVoiceLocale
    }

    private var availableLocales: [String] {
        Set(voices.map(\.language)).sorted {
            localeName($0).localizedStandardCompare(localeName($1)) == .orderedAscending
        }
    }

    private var premiumVoices: [AVSpeechSynthesisVoice] {
        let language = ChoiceBoardVoicePreference.languageCode(for: activeVoiceLocale)
        return voices.filter {
            $0.quality == .premium
                && ChoiceBoardVoicePreference.languageCode(for: $0.language) == language
                && !isPersonalVoice($0)
        }
        .sorted {
            let firstRank = $0.language == activeVoiceLocale ? 0 : 1
            let secondRank = $1.language == activeVoiceLocale ? 0 : 1
            if firstRank != secondRank { return firstRank < secondRank }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private var allPersonalVoices: [AVSpeechSynthesisVoice] {
        voices.filter(isPersonalVoice)
    }

    private var personalVoices: [AVSpeechSynthesisVoice] {
        let language = ChoiceBoardVoicePreference.languageCode(for: activeVoiceLocale)
        return allPersonalVoices
            .filter { ChoiceBoardVoicePreference.languageCode(for: $0.language) == language }
            .sorted {
                let firstRank = $0.language == activeVoiceLocale ? 0 : 1
                let secondRank = $1.language == activeVoiceLocale ? 0 : 1
                if firstRank != secondRank { return firstRank < secondRank }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    private var effectiveVoice: AVSpeechSynthesisVoice? {
        if let selected = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            return selected
        }
        return AudioHelper.defaultVoice(for: activeVoiceLocale)
    }

    private var qualityNotice: String {
        guard let voice = effectiveVoice else {
            return L10n.MainMenu.noPremiumVoiceNotice
        }
        if isPersonalVoice(voice) {
            return L10n.MainMenu.personalVoiceSelectedNotice
        }
        if voice.quality == .premium {
            return L10n.MainMenu.premiumVoiceNotice
        }
        if voice.quality == .enhanced {
            return L10n.MainMenu.enhancedVoiceNotice
        }
        return L10n.MainMenu.standardVoiceNotice
    }

    private func isPersonalVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        if #available(iOS 17.0, *) {
            return voice.voiceTraits.contains(.isPersonalVoice)
        }
        return false
    }

    private var voiceGroups: [VoiceLocaleGroup] {
        let language = ChoiceBoardVoicePreference.languageCode(for: activeVoiceLocale)
        let matchingVoices = voices.filter {
            ChoiceBoardVoicePreference.languageCode(for: $0.language) == language
                && !isPersonalVoice($0)
        }
        let recommendedLocale = AudioHelper.defaultVoice(for: activeVoiceLocale)?.language
        return Dictionary(grouping: matchingVoices, by: \.language)
            .map { VoiceLocaleGroup(locale: $0.key, voices: $0.value.sorted { $0.name < $1.name }) }
            .sorted {
                let firstRank = $0.locale == activeVoiceLocale ? 0 : ($0.locale == recommendedLocale ? 1 : 2)
                let secondRank = $1.locale == activeVoiceLocale ? 0 : ($1.locale == recommendedLocale ? 1 : 2)
                if firstRank != secondRank { return firstRank < secondRank }
                return localeName($0.locale).localizedStandardCompare(localeName($1.locale)) == .orderedAscending
            }
    }

    private var localeSelection: Binding<String> {
        Binding(get: { selectedVoiceLocale }, set: { newLocale in
            selectedVoiceLocale = newLocale
            selectedVoiceIdentifier = ""
        })
    }

    private func localeName(_ identifier: String) -> String {
        locale.localizedString(forIdentifier: identifier) ?? identifier
    }

    private func voiceRow(_ voice: AVSpeechSynthesisVoice, isRecommendation: Bool = false,
                          isPersonal: Bool = false) -> some View {
        HStack {
            Button {
                selectedVoiceLocale = voice.language
                selectedVoiceIdentifier = voice.identifier
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(voice.name)
                        if isRecommendation || isPersonal {
                            Text("\(localeName(voice.language)) (\(voice.language))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if selectedVoiceIdentifier == voice.identifier {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .accessibilityIdentifier("VoicePicker.\(isPersonal ? "personalVoice" : (isRecommendation ? "recommendedVoice" : "voice")).\(voice.identifier)")
            .accessibilityAddTraits(selectedVoiceIdentifier == voice.identifier ? .isSelected : [])

            Button {
                preview(voice)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
            }
            .accessibilityLabel(L10n.MainMenu.previewVoice(voice.name))
            .accessibilityIdentifier("VoicePicker.\(isPersonal ? "personalPreview" : (isRecommendation ? "recommendedPreview" : "preview")).\(voice.identifier)")
        }
        .buttonStyle(.borderless)
    }

    private func personalVoiceHelpButton(_ title: String) -> some View {
        Button(title) {
            showPersonalVoiceHelp = true
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.personalVoiceHelpButton)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(L10n.MainMenu.voiceLanguage, selection: localeSelection) {
                        Text("\(L10n.MainMenu.appLanguage) (\(localeName(appVoiceLocale)))")
                            .tag("")
                        ForEach(availableLocales, id: \.self) { voiceLocale in
                            Text("\(localeName(voiceLocale)) (\(voiceLocale))")
                                .tag(voiceLocale)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.voiceLanguagePicker)
                }

                Section {
                    HStack {
                        Button {
                            selectedVoiceIdentifier = ""
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(L10n.MainMenu.defaultVoice)
                                    if let recommendedVoice = AudioHelper.defaultVoice(for: activeVoiceLocale) {
                                        Text(recommendedVoice.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if selectedVoiceIdentifier.isEmpty {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.defaultVoiceButton)
                        .accessibilityAddTraits(selectedVoiceIdentifier.isEmpty ? .isSelected : [])

                        Button {
                            preview(AudioHelper.defaultVoice(for: activeVoiceLocale))
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                        }
                        .accessibilityLabel(L10n.MainMenu.previewVoice(L10n.MainMenu.defaultVoice))
                        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.defaultVoicePreviewButton)
                    }
                    .buttonStyle(.borderless)
                }

                if premiumVoices.isEmpty {
                    Section {
                        Text(qualityNotice)
                            .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.voiceQualityNotice)
                        Button(L10n.MainMenu.getMoreVoices) {
                            showMoreVoicesHelp = true
                        }
                    }
                } else {
                    Section(L10n.MainMenu.premiumVoices) {
                        ForEach(premiumVoices, id: \.identifier) { voice in
                            voiceRow(voice, isRecommendation: true)
                        }
                    }
                }

                if #available(iOS 17.0, *) {
                    Section(L10n.MainMenu.personalVoice) {
                        switch personalVoiceAccess {
                        case .notDetermined:
                            Text(L10n.MainMenu.personalVoiceAccessExplanation)
                            Button(L10n.MainMenu.allowPersonalVoice) {
                                requestPersonalVoiceAccess()
                            }
                            .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.personalVoiceAccessButton)
                            personalVoiceHelpButton(L10n.MainMenu.createPersonalVoice)
                        case .authorized:
                            if personalVoices.isEmpty {
                                Text(allPersonalVoices.isEmpty
                                     ? L10n.MainMenu.noPersonalVoices
                                     : L10n.MainMenu.noPersonalVoiceForLanguage)
                                if allPersonalVoices.isEmpty {
                                    personalVoiceHelpButton(L10n.MainMenu.createPersonalVoice)
                                }
                            } else {
                                ForEach(personalVoices, id: \.identifier) { voice in
                                    voiceRow(voice, isPersonal: true)
                                }
                            }
                        case .denied:
                            Text(L10n.MainMenu.personalVoiceAccessDenied)
                            personalVoiceHelpButton(L10n.MainMenu.personalVoiceSettingsHelp)
                        case .unsupported:
                            Text(L10n.MainMenu.personalVoiceUnsupported)
                        }
                    }
                    .alert(L10n.MainMenu.personalVoice, isPresented: $showPersonalVoiceHelp) {
                        Button(L10n.doneButton, role: .cancel) { }
                    } message: {
                        Text(L10n.MainMenu.personalVoiceHelp)
                    }
                }

                ForEach(voiceGroups) { group in
                    Section {
                        ForEach(group.voices, id: \.identifier) { voice in
                            voiceRow(voice)
                        }
                    } header: {
                        Text("\(localeName(group.locale)) (\(group.locale))")
                    }
                }

            }
            .navigationTitle(L10n.MainMenu.changeVoiceButton)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.doneButton) { dismiss() }
                }
            }
            .onAppear {
                refreshVoices()
                if selectedVoiceLocale.isEmpty,
                   let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier),
                   ChoiceBoardVoicePreference.languageCode(for: voice.language)
                    != ChoiceBoardVoicePreference.languageCode(for: appVoiceLocale) {
                    selectedVoiceLocale = voice.language
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    refreshVoices()
                }
            }
            .onDisappear {
                previewAudioHelper.cancelSpeech()
            }
            .sheet(isPresented: $showMoreVoicesHelp) {
                MoreVoicesHelpSheet()
            }
        }
    }
}

private struct MoreVoicesHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var appDisplayName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? Bundle.main.bundleURL.deletingPathExtension().lastPathComponent
    }

    private var voicesPath: String {
        if #available(iOS 26.0, *) {
            return L10n.MainMenu.moreVoicesPathModern
        }
        return L10n.MainMenu.moreVoicesPathLegacy
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                        .frame(width: 60, height: 60)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 18))
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.MainMenu.moreVoicesTitle)
                        .font(.title.bold())
                        .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.moreVoicesHelpTitle)
                    Text(L10n.MainMenu.moreVoicesIntro)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    MoreVoicesHelpStep(number: 1,
                                       title: L10n.MainMenu.moreVoicesStepOneTitle,
                                       detail: L10n.MainMenu.moreVoicesStepOneDetail)
                    MoreVoicesHelpStep(number: 2,
                                       title: L10n.MainMenu.moreVoicesStepTwoTitle,
                                       detail: voicesPath,
                                       highlightsDetail: true)
                    MoreVoicesHelpStep(number: 3,
                                       title: L10n.MainMenu.moreVoicesStepThreeTitle,
                                       detail: L10n.MainMenu.moreVoicesStepThreeDetail)
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.MainMenu.moreVoicesReturnTitle(appDisplayName))
                            .font(.headline)
                        Text(L10n.MainMenu.moreVoicesReturnDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            Button { dismiss() } label: {
                Text(L10n.MainMenu.moreVoicesGotIt)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 15))
            }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.moreVoicesHelpDoneButton)
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.regularMaterial)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct MoreVoicesHelpStep: View {
    let number: Int
    let title: String
    let detail: String
    var highlightsDetail = false

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.blue, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(highlightsDetail ? .subheadline.weight(.semibold) : .subheadline)
                    .foregroundStyle(highlightsDetail ? Color.primary : Color.secondary)
                    .accessibilityIdentifier(highlightsDetail
                                             ? AccessibilityIdentifiers.MainMenu.moreVoicesHelpPath
                                             : "MoreVoicesHelp.step\(number)Detail")
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
    }
}

extension View {
    @ViewBuilder
    func selectionAndPadding(isSelected: Bool, isForSplitView: Bool) -> some View {
        //let isSelected = false
        
        let screenHeight = UIScreen.main.bounds.height

        //Smaller padding for iPhone 8, etc
        self.padding(screenHeight < 700 ? 6 : 12 )
        
        //self.modifier(DynamicPadding())
        
//        if isForSplitView {
//            if isSelected {
//                self.padding(12)
//                    .background(Color.systemFill)
//            }
//            else {
//                self.padding(12)
//                //self.padding(.horizontal, 12)
//                //    .padding(.vertical, 12)
//            }
//        }
//        else {
//            self.padding(.horizontal, 16)
//                .padding(.vertical, 8)
//        }
    }
}

extension View {
    @ViewBuilder
    func toolbarButtonStyle() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self
        } else {
            self
                //.menuStyle(.button)
                .buttonStyle(.bordered)
                //.clipShape(.circle)
                //.imageScale(.medium)
        }
        #else
        self
#endif
    }
}



//struct MainMenuView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        MainMenuView(photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>)
//    }
//}
