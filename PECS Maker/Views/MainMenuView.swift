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
import ZLPhotoBrowser
import SwiftUIX
import LogFramework

enum MainMenuAction : String, Codable { case selectPhoto, selectLayout, titles, changeSelections, print, settings }

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue()) // set the `max` value (from both buttons)
    }
}

struct MainMenuView: View {
//    static func == (lhs: MainMenuView, rhs: MainMenuView) -> Bool {
//        lhs.pageLayoutState.topic == rhs.pageLayoutState.topic
//    }
    

    
    //@State private var action: MainMenuAction?
    @Binding var action: MainMenuAction?
    
    @ObservedObject var pageLayoutState: PageLayoutState
    //@StateObject var pageLayoutState = PageLayoutState()
    //@StateObject var pageLayoutState: PageLayoutState
    //@StateObject var pageLayoutState: PageLayoutState
    
    //@State var pageLayoutState: PageLayoutState
    
    
    var isForSplitView: Bool
    
    @State private var isShowingPicker = false
    @State private var isShowingStoreView = false
    @State private var showClearSelectionsPrompt = false
    @State private var showRenameAlert = false
    
    @State private var showRecommended = false
    
    var storeVC: SKStoreProductViewController {
        SKStoreProductViewController()
    }
    
    @State var maximumSubViewHeight: CGFloat = 0
    
    struct MaximumHeightPreferenceKey: PreferenceKey
    {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat)
        {
            value = max(value, nextValue())
        }
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

    init(topic: PECSRepo, action: Binding<MainMenuAction?>, isForSplitView: Bool) {
        //self.pageLayoutState = PageLayoutState(
        //pageLayoutState.load(topic: topic)
        //_pageLayoutState = StateObject(wrappedValue: PageLayoutState(topic: topic))
        //_pageLayoutState = State(wrappedValue: PageLayoutState(topic: topic))
        //pageLayoutState = PageLayoutState(topic: topic)
        self.pageLayoutState = topic
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
    
    var isVerticalLayoutForSettingsSettingsAndMoreApps: Bool {
        isForSplitView && UIScreen.main.bounds.height > 1000 //Only iPad Pro 12.9
    }
    
    //https://www.wooji-juice.com/blog/stupid-swiftui-tricks-equal-sizes.html
    @ViewBuilder
    var settingsAndMoreAppsView: some View {
        if isVerticalLayoutForSettingsSettingsAndMoreApps {
            settingsAndMoreAppsViewVertical
        }
        else {
            settingsAndMoreAppsViewHorizontal
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

    
    func makeMainMenuButton(action: MainMenuAction, actionFunction: (()->())? = nil, systemIconName: String, text: String, showCheckMark: Bool) -> some View {
        MainMenuButton(action: actionFunction ?? {self.action = action}, systemIconName: systemIconName, text: text, showCheckMark: showCheckMark, isSecondary: false, isSelected: self.action == action && isForSplitView, isLarge: isLargeButton)
            .selectionAndPadding(isSelected: self.action == action, isForSplitView: isForSplitView)
            //.frame(maxWidth: buttonWidth)
    }
    
    var settingsAndMoreAppsViewVertical : some View {
    
        VStack(spacing: 0) {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: L10n.MainMenu.settingsButton, isSecondary: true, isSelected: action == .settings && isForSplitView, isLarge: isLargeButton)
                    .selectionAndPadding(isSelected: action == .settings, isForSplitView: isForSplitView)
                    .accessibility(identifier: AccessibilityIdentifiers.MainMenu.settingsButton)

                MainMenuButton(action: {
                    DispatchQueue.main.async {
                        //storeVC.loadProduct(appID: AppSettings.shared.developerID)
                        showRecommended = true
                    }
                    
                }, systemIconName: "app.gift", text: L10n.MainMenu.moreAppsButton, isSecondary: true, isLarge: isLargeButton)
                .selectionAndPadding(isSelected: false, isForSplitView: isForSplitView)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.moreAppsButton)
        }
    }
    
    var settingsAndMoreAppsViewHorizontal : some View {
    
        HStack(spacing: 16) {
            Group {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: L10n.MainMenu.settingsButton, isSecondary: true, isLarge: isLargeButton)
                    .overlay(DetermineHeight())
                    .frame(maxHeight: maximumSubViewHeight)
                    .accessibility(identifier: AccessibilityIdentifiers.MainMenu.settingsButton)

                MainMenuButton(action: {
                    DispatchQueue.main.async {
                        //storeVC.loadProduct(appID: AppSettings.shared.developerID)
                        showRecommended = true
                    }
                    
                }, systemIconName: "app.gift", text: L10n.MainMenu.moreAppsButton, isSecondary: true, isLarge: isLargeButton)
                .overlay(DetermineHeight())
                .frame(maxHeight: maximumSubViewHeight)
            }
            
        }
        .onPreferenceChange(DetermineHeight.Key.self) {
            maximumSubViewHeight = $0
        }
        .padding(8)
    }
    
    
    struct DetermineHeight: View
    {
        typealias Key = MaximumHeightPreferenceKey
        var body: some View {
            GeometryReader
            {
                proxy in
                Color.clear
                    .anchorPreference(key: Key.self, value: .bounds)
                {
                    anchor in proxy[anchor].size.height
                }
            }
        }
    }
    
    
    
    @State private var buttonMaxHeight: CGFloat?
    
    struct ButtonHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat,
                           nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
    
    //https://www.swiftbysundell.com/questions/syncing-the-width-or-height-of-two-swiftui-views/
    var settingsAndMoreAppsView3: some View {
        
        HStack {
            Group {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: "Settings", isSecondary: true)
                //.padding(8)
                MainMenuButton(action: {
                    storeVC.loadProduct(appID: AppSettings.shared.developerID)
                    
                }, systemIconName: "app.gift", text: "More Apps", isSecondary: true)
                //.padding(8)
            }
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: ButtonHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            })
            .frame(height: buttonMaxHeight)
        }
        .onPreferenceChange(ButtonHeightPreferenceKey.self) {
            buttonMaxHeight = $0
        }
    }
    
    
    //For a VGrid we are specifying max width. Item height should be equal.
    private var buttonColumn: GridItem {
        GridItem(.flexible(minimum: 0, maximum: 200))
    }
    
    var settingsAndMoreAppsView4: some View {
        
        //https://www.swiftbysundell.com/questions/syncing-the-width-or-height-of-two-swiftui-views/
        LazyVGrid(columns: [buttonColumn, buttonColumn]) {
            
            Group {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: "Settings", isSecondary: true)
                //.padding(8)
                //.frame(maxWidth: .infinity, maxHeight: .infinity)
                //.frame(width: geometry.size.width / 2.0)
                MainMenuButton(action: {
                    storeVC.loadProduct(appID: AppSettings.shared.developerID)
                    
                }, systemIconName: "app.gift", text: "More Apps", isSecondary: true)
                //.padding(8)
                //.frame(maxWidth: .infinity, maxHeight: .infinity)
                //.frame(width: geometry.size.width / 2.0)
            }
            .frame(maxHeight: .infinity)
        }
        //.frame(maxHeight: .infinity)
        .padding(8)
    }
    
    @ViewBuilder
    static func makeDetailView(for action: MainMenuAction, pageLayoutState: PageLayoutState, selection: Binding<MainMenuAction?>, isForSplitView: Bool) -> some View {
        switch action {

        case .selectPhoto:
            /*
            let selectPhotoView = LazyView(PhotoListView2(pageLayoutState: pageLayoutState, isForSplitView: isForSplitView, dismissAction: {
                DispatchQueue.main.async {
                    //self.action = nil
                    pageLayoutState.save()
                }}))
            selectPhotoView
             */
            EmptyView()

        case .changeSelections:
            //EmptyView()
            let changeSelectionsView = LazyView(PhotoListView2(pageLayoutState: pageLayoutState, isForSplitView: isForSplitView,
                dismissAction: {
                DispatchQueue.main.async {
                    //self.action = nil
                    pageLayoutState.save()
                }}))
            changeSelectionsView
            
        case .selectLayout:
            let pageSizeAndLayoutView = LazyView(PageSizeAndLayoutView(pageLayoutState: pageLayoutState, dismissAction: {
                DispatchQueue.main.async {
                    pageLayoutState.save()
                    //selection.wrappedValue = nil
                    pageLayoutState.checkmarks.didPageLayout = true
                }
            }))
            pageSizeAndLayoutView

        case .titles:
            let titlesView = LazyView(TitlesView(pageLayoutState: pageLayoutState, dismissAction: {
                DispatchQueue.main.async {
                    //self.action = nil
                    pageLayoutState.save()
                    pageLayoutState.checkmarks.didTitles = true
                }
            }))
            titlesView

        case .print:
            let pagePreviewView = LazyView(PagePreviewView(pageLayoutState: pageLayoutState, dismissAction: {
                DispatchQueue.main.async {
                    //self.action = nil
                    pageLayoutState.checkmarks.didPrint = true
                }
            }))
            pagePreviewView
            
        case .settings:
            let settingsView = LazyView(SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings.shared)))
            settingsView
            
        }
        
    }
    
    static func makeNavigationLink(for action: MainMenuAction, pageLayoutState: PageLayoutState, selection: Binding<MainMenuAction?>, isDetailLink: Bool = true, isForSplitView: Bool) -> some View {
        let destinationView = makeDetailView(for: action, pageLayoutState: pageLayoutState, selection: selection, isForSplitView: isForSplitView)
        return NavigationLink(destination: destinationView, tag: action, selection: selection) {
            EmptyView()
        }
        .isDetailLink(isDetailLink)
    }
    
    static func makeNavigationLinks(pageLayoutState: PageLayoutState, selection: Binding<MainMenuAction?>, isForSplitView: Bool) -> some View {
        VStack {
            
            //If we put this in a Group/VStack instead of a Form we get errors:
            //NavigationLink presenting a value must appear inside a NavigationContent-based NavigationView. Link will be disabled.
            
                /*
                 //Photo picker
                 let photoPickerView = LazyView(YPImagePickerWrapper(
                 photos: $pageLayoutState.photoBrowserData,
                 configuration: photoPickerConfig,
                 pattern: photoPickerPattern
                 ))
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
                 .navigationBarHidden(true)
                 NavigationLink(destination: photoPickerView,
                 tag: MainMenuAction.selectPhoto,
                 selection: $action) {
                 EmptyView()
                 }*/
            
            //Select photos
            makeNavigationLink(for: .selectPhoto, pageLayoutState: pageLayoutState, selection: selection, isForSplitView: isForSplitView)

            //Change selections photos
            makeNavigationLink(for: .changeSelections, pageLayoutState: pageLayoutState, selection: selection, isForSplitView: isForSplitView)

            
            //Page size and layout
            makeNavigationLink(for: .selectLayout, pageLayoutState: pageLayoutState, selection: selection, isForSplitView: isForSplitView)
            
            //Titles
            //makeNavigationLink(for: .changeSelections, pageLayoutState: pageLayoutState, selection: selection, isForSplitView: isForSplitView)

            //Titles
            makeNavigationLink(for: .titles, pageLayoutState: pageLayoutState, selection: selection, isForSplitView: isForSplitView)

            //Page preview, Save and Print
            makeNavigationLink(for: .print, pageLayoutState: pageLayoutState, selection: selection, isForSplitView: isForSplitView)

            //Settings
            makeNavigationLink(for: .settings, pageLayoutState: pageLayoutState, selection: selection, isForSplitView: isForSplitView)
        }

    }
    
    var buttonView : some View {
        Group {
            makeMainMenuButton(action: .selectPhoto, actionFunction: { selectPhotos(photoBrowserData: pageLayoutState.photoBrowserData, preselectItems: AppSettings.preselectPhotosInPicker)}, systemIconName: "photo", text: L10n.MainMenu.selectPhotosButton, showCheckMark: pageLayoutState.photoBrowserData.photoItems.count>0) .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectPhotoButton)
            
            if !pageLayoutState.photoBrowserData.photoItems.isEmpty || isForSplitView {
                
                /*
                 CapsuleButton(text: L10n.MainMenu.clearSelectionsButton, purpose: .secondary, action: { showClearSelectionsPrompt = true })
                 .padding(.horizontal,32)
                 .accessibility(identifier: AccessibilityIdentifiers.MainMenu.clearSelectionsButton)
                 .askQuestionYesNo(isPresented: $showClearSelectionsPrompt, title: L10n.ClearSelectionsAlert.title, message: L10n.ClearSelectionsAlert.message, yesAction: {
                 self.pageLayoutState.clearSelections()
                 }, noAction: {})
                
                 */

                //This was the last one we used
                 CapsuleButton(text: L10n.MainMenu.changeSelectionsButton, purpose: .secondary, action: { action = .changeSelections })
                    .padding(.horizontal,32)
                 .accessibility(identifier: AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
                 .padding(.horizontal, 16)
//                 .selectionAndPadding(isSelected: action == .changeSelections, isForSplitView: isForSplitView)

                /*
                 NavigationLink(destination: {
                 LazyView(PhotoListView(pageLayoutState: pageLayoutState, dismissAction: {
                 DispatchQueue.main.async {
                 //self.action = nil
                 self.save()
                 }
                 }))
                 }, label: {
                 //CapsuleButton(text: "Change Selections", purpose: .secondary, action: { })
                 Text(L10n.MainMenu.changeSelectionsButton)
                 })
                 .buttonStyle(RoundedButtonStyle( purpose: .secondary ))
                 .selectionAndPadding(isSelected: action == .changeSelections)
                 .accessibility(identifier: AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
                 .padding(8)
                 */
                
                /*
                 MainMenuButton(action: { showClearSelectionsPrompt = true }, /*systemIconName: "clear", */ text: L10n.MainMenu.clearSelectionsButton, isHorizontal: true, isSecondary: true)
                 .padding(8)
                 .accessibility(identifier: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
                 .askQuestionYesNo(isPresented: $showClearSelectionsPrompt, title: "Clear Selections", message: "Clear selected photos and start a new design?", yesAction: {
                 self.pageLayoutState.clearSelections()
                 }, noAction: {})
                 */
            }
            //}
            //.padding(8)
            
            makeMainMenuButton(action: .selectLayout, systemIconName: "square.grid.2x2", text: L10n.MainMenu.selectLayoutButton, showCheckMark: pageLayoutState.checkmarks.didPageLayout)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
            
            makeMainMenuButton(action: .titles, systemIconName: "square.and.pencil",
                           text: L10n.MainMenu.addTitlesButton,
                           showCheckMark: pageLayoutState.checkmarks.didTitles)
            .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectTitlesButton)
            
            makeMainMenuButton(action: .print, systemIconName: "printer", text: L10n.MainMenu.printButton, showCheckMark: pageLayoutState.checkmarks.didPrint)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
            
            settingsAndMoreAppsView
            
            //Spacer()
            //}
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
    
    var buttonViewGrid : some View {
        
        LazyVGrid(columns: columns) {
            makeMainMenuButton(action: .selectPhoto, systemIconName: "photo", text: L10n.MainMenu.selectPhotosButton, showCheckMark: pageLayoutState.photoBrowserData.photoItems.count>0)
            .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectPhotoButton)
           
        makeMainMenuButton(action: .selectLayout, systemIconName: "square.grid.2x2", text: L10n.MainMenu.selectLayoutButton, showCheckMark: pageLayoutState.checkmarks.didPageLayout)
            .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
        
        makeMainMenuButton(action: .titles, systemIconName: "square.and.pencil", text: L10n.MainMenu.addTitlesButton, showCheckMark: pageLayoutState.checkmarks.didTitles)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectTitlesButton)
        
        makeMainMenuButton(action: .print, systemIconName: "printer", text: L10n.MainMenu.printButton, showCheckMark: pageLayoutState.checkmarks.didPrint)
            .accessibility(identifier: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
        
        settingsAndMoreAppsView
        
        }
        
    }
    
    var maxViewWidth: CGFloat {
        if isForSplitView {
            return AppSettings.maxViewWidth
        }
        else {
            if isIPad {
                return 500
            }
            else {
                return AppSettings.maxViewWidth
            }
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false)  {
        //VStack {
            
            //Image(uiImage: topic.topicImage)
            
            if AppSettings.showTopicDebugInfo {
                if let topic = pageLayoutState.topic {
                    Text(topic.topicName)
                    Text("Photo count: \(pageLayoutState.photos.count)")
                }
            }
            
            //MARK: Navigation Links
            MainMenuView.makeNavigationLinks(pageLayoutState: pageLayoutState, selection: $action, isForSplitView: isForSplitView)
            
            //MARK: Views
            //VStack {
                
            /*
                TopicToolbarView(title: $pageLayoutState.title, confirmAction: { save() },
                                 deleteAction: { PECSRepoFactory.shared.deleteCurrentTopic() }
                )
                .padding(.bottom, 8)
             */
                
                if let lastError = pageLayoutState.lastError {
                    ErrorView(message: lastError.localizedDescription, closeAction: {
                        withAnimation {
                            pageLayoutState.lastError = nil }
                    })
                }
            
            buttonView
            //buttonViewGrid

        }
        .frame(maxWidth: maxViewWidth)
        //.padding(.vertical, 16)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .navigationTitle(pageLayoutState.topic.topicName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            /*
            if isForSplitView {
                //Need to put a delay here because SwiftUI doesn't suppport
                //pushing 2 views onto the navigation stack (the prior one
                //being the selected topic).
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.action = .print
                }
            }*/
            
            if action != pageLayoutState.topic.mainMenuAction {
                self.action = pageLayoutState.topic.mainMenuAction
            }
            if action == nil && isForSplitView {
                self.action = .changeSelections
            }
        }
        //.onValueChange(of: action) { newValue, arg  in
        .onChange(of: action) { newValue in
            pageLayoutState.topic.mainMenuAction = newValue
            pageLayoutState.save()
        }
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

extension View {
    @ViewBuilder
    func selectionAndPadding(isSelected: Bool, isForSplitView: Bool) -> some View {
        let isSelected = false
        
        self.padding(12)
        
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




//struct MainMenuView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        MainMenuView(photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>)
//    }
//}


