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

struct MainMenuView: View, Equatable {
    static func == (lhs: MainMenuView, rhs: MainMenuView) -> Bool {
        lhs.pageLayoutState.topic == rhs.pageLayoutState.topic
    }
    

    
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
        pageLayoutState = PageLayoutState(topic: topic)
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
    
    var settingsAndMoreAppsViewVertical : some View {
    
        VStack(spacing: 0) {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: L10n.MainMenu.settingsButton, isSecondary: true)
                    .selectionAndPadding(isSelected: action == .settings, isForSplitView: isForSplitView)
                
                MainMenuButton(action: {
                    DispatchQueue.main.async {
                        //storeVC.loadProduct(appID: AppSettings.shared.developerID)
                        showRecommended = true
                    }
                    
                }, systemIconName: "app.gift", text: L10n.MainMenu.moreAppsButton, isSecondary: true)
                .selectionAndPadding(isSelected: false, isForSplitView: isForSplitView)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.settingsButton)
        }
    }
    
    var settingsAndMoreAppsViewHorizontal : some View {
    
        HStack(spacing: 16) {
            Group {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: L10n.MainMenu.settingsButton, isSecondary: true)
                    .overlay(DetermineHeight())
                    .frame(maxHeight: maximumSubViewHeight)
                
                MainMenuButton(action: {
                    DispatchQueue.main.async {
                        //storeVC.loadProduct(appID: AppSettings.shared.developerID)
                        showRecommended = true
                    }
                    
                }, systemIconName: "app.gift", text: L10n.MainMenu.moreAppsButton, isSecondary: true)
                .overlay(DetermineHeight())
                .frame(maxHeight: maximumSubViewHeight)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.settingsButton)
            }
            
        }
        .onPreferenceChange(DetermineHeight.Key.self) {
            maximumSubViewHeight = $0
        }
        .padding(16)
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
    static func makeDetailView(for action: MainMenuAction, pageLayoutState: PageLayoutState, selection: Binding<MainMenuAction?>) -> some View {
        switch action {

        case .selectPhoto:
            let selectPhotoView = LazyView(PhotoListView(pageLayoutState: pageLayoutState, dismissAction: {
                DispatchQueue.main.async {
                    //self.action = nil
                    pageLayoutState.save()
                }}))
            selectPhotoView

        case .changeSelections:
            let changeSelectionsView = LazyView(PhotoListView(pageLayoutState: pageLayoutState, dismissAction: {
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
    
    static func makeNavigationLink(for action: MainMenuAction, pageLayoutState: PageLayoutState, selection: Binding<MainMenuAction?>, isDetailLink: Bool = true) -> some View {
        let destinationView = makeDetailView(for: action, pageLayoutState: pageLayoutState, selection: selection)
        return NavigationLink(destination: destinationView, tag: action, selection: selection) {
            EmptyView()
        }
        .isDetailLink(isDetailLink)
    }
    
    static func makeNavigationLinks(pageLayoutState: PageLayoutState, selection: Binding<MainMenuAction?>) -> some View {
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
            makeNavigationLink(for: .selectPhoto, pageLayoutState: pageLayoutState, selection: selection)
            
            //Page size and layout
            makeNavigationLink(for: .selectLayout, pageLayoutState: pageLayoutState, selection: selection)
            
            //Titles
            //makeNavigationLink(for: .changeSelections, pageLayoutState: pageLayoutState, selection: selection)

            //Titles
            makeNavigationLink(for: .titles, pageLayoutState: pageLayoutState, selection: selection)

            //Page preview, Save and Print
            makeNavigationLink(for: .print, pageLayoutState: pageLayoutState, selection: selection)

            //Settings
            makeNavigationLink(for: .settings, pageLayoutState: pageLayoutState, selection: selection)
        }

    }
    
    
    
    var body: some View {
        ScrollView(showsIndicators: false)  {
        //VStack {
            
            //Image(uiImage: topic.topicImage)
            
            if AppSettings.showTopicDebugInfo {
                if let topic = pageLayoutState.topic {
                    Text(topic.topicName)
                    Text("Photo count: \(topic.photos.photoItems.count)")
                }
            }
            
            //MARK: Navigation Links
            MainMenuView.makeNavigationLinks(pageLayoutState: pageLayoutState, selection: $action)
            
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
                
                MainMenuButton(action: {
                    action = .selectPhoto
                    //selectPhotos(photoBrowserData: pageLayoutState.photoBrowserData)
                }, systemIconName: "photo", text: L10n.MainMenu.selectPhotosButton, showCheckMark: pageLayoutState.photoBrowserData.photoItems.count>0)
                .selectionAndPadding(isSelected: action == .selectPhoto, isForSplitView: isForSplitView)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectPhotoButton)
                //                .sheet(isPresented: $isShowingPicker) {
                //                    PhotoPicker(
                //                        datas: $pageLayoutState.photoData,
                //                        configuration: photoPickerConfig,
                //                        pattern: photoPickerPattern
                //                    )
                //                }
                
                
                
                if !pageLayoutState.photoBrowserData.photoItems.isEmpty {

                    /*
                    CapsuleButton(text: L10n.MainMenu.clearSelectionsButton, purpose: .secondary, action: { showClearSelectionsPrompt = true })
                        .padding(.horizontal,32)
                        .accessibility(identifier: AccessibilityIdentifiers.MainMenu.clearSelectionsButton)
                        .askQuestionYesNo(isPresented: $showClearSelectionsPrompt, title: L10n.ClearSelectionsAlert.title, message: L10n.ClearSelectionsAlert.message, yesAction: {
                            self.pageLayoutState.clearSelections()
                        }, noAction: {})
                     */
                    
                    /*
                     //This was the last one we used
                    CapsuleButton(text: L10n.MainMenu.changeSelectionsButton, purpose: .secondary, action: { action = .changeSelections })
                        .accessibility(identifier: AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
                        .padding(.horizontal, 16)
                        .selectionAndPadding(isSelected: action == .changeSelections, isForSplitView: isForSplitView)
                     */
                    
                    
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
            
            MainMenuButton(action: {action = .selectLayout}, systemIconName: "square.grid.2x2", text: L10n.MainMenu.selectLayoutButton, showCheckMark: pageLayoutState.checkmarks.didPageLayout)
                .selectionAndPadding(isSelected: action == .selectLayout, isForSplitView: isForSplitView)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
            
            MainMenuButton(action: {action = .titles}, systemIconName: "square.and.pencil",
                           text: L10n.MainMenu.addTitlesButton,
                           showCheckMark: pageLayoutState.checkmarks.didTitles)
                .selectionAndPadding(isSelected: action == .titles, isForSplitView: isForSplitView)
            .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectTitlesButton)
            
            MainMenuButton(action: {action = .print}, systemIconName: "printer", text: L10n.MainMenu.printButton, showCheckMark: pageLayoutState.checkmarks.didPrint)
                .selectionAndPadding(isSelected: action == .print, isForSplitView: isForSplitView)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
            
            settingsAndMoreAppsView
            
            //Spacer()
            //}
        }
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .navigationTitle(pageLayoutState.topic.topicName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            Button(L10n.MainMenu.renameButton) {
            //Button(systemImage: SFSymbolName.pencil) {
                showRenameAlert.toggle()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicTitleView.editButton)
        )
        .renameItemAlert(isPresented: $showRenameAlert, itemName: $pageLayoutState.title, placeholder: L10n.RenameTopicAlert.placeholder, title: L10n.RenameTopicAlert.title, message: nil, saveAction: { pageLayoutState.save() })
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
                self.action = .selectPhoto
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
        if isForSplitView {
            if isSelected {
                self.padding(12)
                    .background(Color.systemFill)
            }
            else {
                self.padding(12)
                //self.padding(.horizontal, 12)
                //    .padding(.vertical, 12)
            }
        }
        else {
            self.padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }
}




//struct MainMenuView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        MainMenuView(photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>)
//    }
//}


