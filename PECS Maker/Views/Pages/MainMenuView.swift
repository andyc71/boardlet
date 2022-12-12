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

enum MainMenuAction { case selectPhoto, selectPageSize, selectLayout, titles, clearSelections, print, settings }

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue()) // set the `max` value (from both buttons)
    }
}

struct MainMenuView: View {
    
    @State private var action: MainMenuAction?
    
    //@ObservedObject var pageLayoutState: PageLayoutState
    //@StateObject var pageLayoutState = PageLayoutState()
    @StateObject var pageLayoutState: PageLayoutState
    
    @State private var isShowingPicker = false
    @State private var isShowingStoreView = false
    @State private var showClearSelectionsPrompt = false
    
    var storeVC: SKStoreProductViewController = SKStoreProductViewController()
    
    @State var maximumSubViewHeight: CGFloat = 0
    
    struct MaximumHeightPreferenceKey: PreferenceKey
    {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat)
        {
            value = max(value, nextValue())
        }
    }
    
//    init(pageLayoutState: PageLayoutState) {
//        self.pageLayoutState = pageLayoutState
//    }
    
    let topic: PECSRepo
    
    init(topic: PECSRepo) {
        //self.pageLayoutState = PageLayoutState(
        //pageLayoutState.load(topic: topic)
        _pageLayoutState = StateObject(wrappedValue: PageLayoutState(topic: topic))
        self.topic = topic
    }
    
    @MainActor
    func save() {
        DispatchQueue.main.async {
            self.pageLayoutState.save()
        }
    }
    
    //https://www.wooji-juice.com/blog/stupid-swiftui-tricks-equal-sizes.html
    var settingsAndMoreAppsView: some View {
        
        HStack(spacing: 8) {
            Group {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: L10n.MainMenu.settingsButton, isSecondary: true)
                //.padding(8)
                //.background(Color.secondary.opacity(0.25))
                    .overlay(DetermineHeight())
                    .frame(maxHeight: maximumSubViewHeight)
                
                MainMenuButton(action: {
                    storeVC.loadProduct(appID: AppSettings.shared.developerID)
                    
                }, systemIconName: "app.gift", text: L10n.MainMenu.moreAppsButton, isSecondary: true)
                //.padding(8)
                //.background(Color.secondary.opacity(0.25))
                .overlay(DetermineHeight())
                .frame(maxHeight: maximumSubViewHeight)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.settingsButton)
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
    
    
    var body: some View {
        ScrollView {
        //VStack {
            
            //MARK: Navigation Links
            //If we put this in a Group/VStack instead of a Form we get errors:
            //NavigationLink presenting a value must appear inside a NavigationContent-based NavigationView. Link will be disabled.
            Form {
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
                
                //Page size and layout
                let pageSizeAndLayoutView = LazyView(PageSizeAndLayoutView(pageLayoutState: pageLayoutState, dismissAction: {
                    DispatchQueue.main.async {
                        self.save()
                        self.action = nil
                        self.pageLayoutState.checkmarks.didPageLayout = true
                    }
                }))
                NavigationLink(destination: pageSizeAndLayoutView, tag: MainMenuAction.selectLayout, selection: $action) {
                    EmptyView()
                }
                
                //Titles
                let titlesView = LazyView(TitlesView(pageLayoutState: pageLayoutState, dismissAction: {
                    DispatchQueue.main.async {
                        self.action = nil
                        self.pageLayoutState.checkmarks.didTitles = true
                        self.save()
                    }
                }))
                NavigationLink(destination: titlesView, tag: MainMenuAction.titles, selection: $action) {
                    EmptyView()
                }
                
                //Page preview, Save and Print
                let pagePreviewView = LazyView(PagePreviewView(pageLayoutState: pageLayoutState, dismissAction: {
                    DispatchQueue.main.async {
                        self.action = nil
                        self.pageLayoutState.checkmarks.didPrint = true
                    }
                }))
                NavigationLink(destination: pagePreviewView, tag: MainMenuAction.print, selection: $action) {
                    EmptyView()
                }
                
                //Settings
                let settingsView = LazyView(SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings.shared)))
                NavigationLink(destination: settingsView, tag: MainMenuAction.settings, selection: $action) {
                    EmptyView()
                }
                
                TopicToolbarView(title: $pageLayoutState.title, confirmAction: { save() },
                                 deleteAction: { PECSRepoFactory.shared.deleteCurrentTopic() }
                )
                .padding(.bottom, 8)
            }
            
            //MARK: Views
            VStack {
                
                if let lastError = pageLayoutState.lastError {
                    ErrorView(message: lastError.localizedDescription, closeAction: {
                        withAnimation {
                            pageLayoutState.lastError = nil }
                    })
                }
                
                MainMenuButton(action: {
                    //action = .selectPhoto
                    selectPhotos()
                }, systemIconName: "photo", text: L10n.MainMenu.selectPhotosButton, showCheckMark: pageLayoutState.photos.count>0)
                //.padding(8)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectPhotoButton)
                //                .sheet(isPresented: $isShowingPicker) {
                //                    PhotoPicker(
                //                        datas: $pageLayoutState.photoData,
                //                        configuration: photoPickerConfig,
                //                        pattern: photoPickerPattern
                //                    )
                //                }
                
                
                
                if !pageLayoutState.photos.isEmpty {
                    /*
                     Button( action: { showClearSelectionsPrompt = true } ) {
                     Text(L10n.MainMenu.clearSelectionsButton)
                     }
                     .frame(alignment: .trailing)
                     */
                    
                    CapsuleButton(text: L10n.MainMenu.clearSelectionsButton, purpose: .secondary, action: { showClearSelectionsPrompt = true })
                        .padding(.horizontal,64)
                        .accessibility(identifier: AccessibilityIdentifiers.MainMenu.clearSelectionsButton)
                        .askQuestionYesNo(isPresented: $showClearSelectionsPrompt, title: L10n.ClearSelectionsAlert.title, message: L10n.ClearSelectionsAlert.message, yesAction: {
                            self.pageLayoutState.clearSelections()
                        }, noAction: {})
                    
                    /*
                     MainMenuButton(action: { showClearSelectionsPrompt = true }, /*systemIconName: "clear", */ text: L10n.MainMenu.clearSelectionsButton, isHorizontal: true, isSecondary: true)
                     .padding(8)
                     .accessibility(identifier: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
                     .askQuestionYesNo(isPresented: $showClearSelectionsPrompt, title: "Clear Selections", message: "Clear selected photos and start a new design?", yesAction: {
                     self.pageLayoutState.clearSelections()
                     }, noAction: {})
                     */
                }
            }
            .padding(8)
            
            MainMenuButton(action: {action = .selectLayout}, systemIconName: "square.grid.2x2", text: L10n.MainMenu.selectLayoutButton, showCheckMark: pageLayoutState.checkmarks.didPageLayout)
                .padding(8)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
            
            MainMenuButton(action: {action = .titles}, systemIconName: "square.and.pencil",
                           text: L10n.MainMenu.addTitlesButton,
                           showCheckMark: pageLayoutState.checkmarks.didTitles)
            .padding(8)
            .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectTitlesButton)
            
            MainMenuButton(action: {action = .print}, systemIconName: "printer", text: L10n.MainMenu.printButton, showCheckMark: pageLayoutState.checkmarks.didPrint)
                .padding(8)
                .accessibility(identifier: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
            
            settingsAndMoreAppsView
            
            Spacer()
            //}
        }
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
//        .onAppear {
//            pageLayoutState.load(topic: topic)
//        }

    }
    
    private var col: GridItem {
        GridItem(.flexible(minimum: 0, maximum: 200))
    }
    
    
    func selectPhotos() {
        let scene = UIApplication.shared.connectedScenes.first
        let root = (scene as? UIWindowScene)?.windows.first?.rootViewController
        if root != nil {
            
            ZLPhotoConfiguration.default().allowSelectImage = true
            ZLPhotoConfiguration.default().allowSelectVideo = false
            ZLPhotoConfiguration.default().allowEditImage = true
            //ZLPhotoConfiguration.default().editImageTools = [.clip, .filter]
            ZLPhotoConfiguration.default().allowTakePhoto = true
            ZLPhotoConfiguration.default().maxSelectCount = AppSettings.maxSelectionsInPhotoPicker
            ZLPhotoConfiguration.default().showSelectedPhotoPreview = false
            ZLPhotoConfiguration.default().allowSelectOriginal = false
            ZLPhotoConfiguration.default().saveNewImageAfterEdit = false
            ZLPhotoConfiguration.default().showSelectedIndex = false
            ZLPhotoConfiguration.default().allowPreviewPhotos = false
            ZLPhotoConfiguration.default().showPreviewButtonInAlbum = false
            //ZLPhotoConfiguration.default().editImageClipRatios = [ZLImageClipRatio(title: "", whRatio: CGFloat(1) / aspectRatio)]
            //ZLPhotoConfiguration.default().frontFacingCamera = true
            //ZLPhotoConfiguration.default().supportedCameraOrientations = [.all]
            //ZLPhotoConfiguration.default().defaultCameraPosition = .front
            
            //Custom camera doesn't rotate properly on iPad, and I can't
            //see a good reason for using it anyway.
            ZLPhotoConfiguration.default().useCustomCamera = false
            
            
            let theme = ZLPhotoUIConfiguration.default()
            
            //Bottom toolbar theme
            let colorScheme = currentTheme.buttonStyle(for: .primary)
            
            //**Thunbnail page.
            theme.thumbnailBgColor = currentTheme.backgroundColor
            
            //Nav bar theme
            theme.navViewBlurEffectOfAlbumList = nil
            theme.navTitleColor = currentTheme.headerStyle.textColor
            theme.navBarColor = currentTheme.headerStyle.backgroundColor
            theme.navCancelButtonStyle = .text
            
            //Bottom toolbar
            theme.bottomViewBlurEffectOfAlbumList  = nil
            theme.bottomToolViewBgColor = currentTheme.headerStyle.backgroundColor
            
            //Done button
            theme.bottomToolViewBtnNormalTitleColor = colorScheme.textColor
            theme.bottomToolViewBtnNormalBgColor = colorScheme.fillColor
            
            /*
             //Preview button
             theme.bottomToolViewBtnNormalTitleColor = currentTheme.headerStyle.backButtonTextColor
             
             // Preview page
             theme.previewVCBgColor = currentTheme.backgroundColor
             
             //Preview page - nav bar
             theme.navViewBlurEffectOfPreview = nil
             theme.navTitleColorOfPreviewVC = currentTheme.headerStyle.backButtonTextColor
             theme.navBarColorOfPreviewVC = currentTheme.headerStyle.backgroundColor
             //theme.sheetBtnTitleColor = currentTheme.headerStyle.backButtonTextColor
             
             
             //theme.bottomViewBlurEffectOfPreview = nil
             */
            
            
            //                theme.bottomToolViewBtnNormalTitleColor = colorScheme.textColor
            //                theme.bottomToolViewBtnNormalBgColor = colorScheme.fillColor
            //                theme.bottomToolViewDoneBtnNormalTitleColor = colorScheme.textColor
            //                theme.bottomToolViewBtnNormalBgColorOfPreviewVC = colorScheme.fillColor
            //                theme.bottomToolViewDoneBtnNormalTitleColorOfPreviewVC = colorScheme.textColor
            //                theme.bottomToolViewBtnNormalTitleColorOfPreviewVC = colorScheme.textColor
            //                theme.bottomToolViewDoneBtnNormalTitleColor = colorScheme.textColor
            
            
            let ac = ZLPhotoPreviewSheet(selectedAssets: pageLayoutState.photoBrowserData.photoAssets)
            
            ac.selectImageBlock = { (images, assets, isOriginal) in
                DispatchQueue.main.async {
                    var photoItems = [PhotoItem]()
                    for i in 0..<images.count {
                        let image = images[i]
                        let asset = assets[i]
                        let photoItem = PhotoItem(image: image, asset: asset)
                        photoItems.append(photoItem)
                    }
                    pageLayoutState.photoBrowserData.photoItems = photoItems
                    self.save()
                }
            }
            
            ac.showPhotoLibrary(sender: root!)
        }
    }
    
}



//struct MainMenuView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        MainMenuView(photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>)
//    }
//}


