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

enum MainMenuAction { case selectPhoto, selectPageSize, selectLayout, titles, print, settings }

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue()) // set the `max` value (from both buttons)
    }
}

struct MainMenuView: View {
    
    @State private var action: MainMenuAction?
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State private var isShowingPicker = false
    @State private var isShowingStoreView = false
    
    
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
    
    //https://www.wooji-juice.com/blog/stupid-swiftui-tricks-equal-sizes.html
    var settingsAndMoreAppsView: some View {

        HStack {
            Group {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: "Settings", isSecondary: true)
                    //.padding(8)
                    //.background(Color.secondary.opacity(0.25))
                    .overlay(DetermineHeight())
                    .frame(maxHeight: maximumSubViewHeight)

                MainMenuButton(action: {
                    storeVC.loadProduct(appID: AppSettings().developerID)

                }, systemIconName: "app.gift", text: "More Apps", isSecondary: true)
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
                    storeVC.loadProduct(appID: AppSettings().developerID)

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
                    storeVC.loadProduct(appID: AppSettings().developerID)

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
        //ScrollView {
            VStack {

                //MARK: Navigation Links
                
                //Photo picker
                let photoPickerView = LazyView(PhotoPicker(
                    datas: $pageLayoutState.photoData,
                    configuration: photoPickerConfig,
                    pattern: photoPickerPattern
                ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationBarHidden(true)
                NavigationLink(destination: photoPickerView,
                               tag: MainMenuAction.selectPhoto,
                               selection: $action) {
                    EmptyView()
                }
                
                //Page size and layout
                let pageSizeAndLayoutView = LazyView(PageSizeAndLayoutView(pageLayoutState: pageLayoutState, isVertical: true, dismissAction: {
                    self.action = nil
                    self.pageLayoutState.didPageLayout = true
                }))
                NavigationLink(destination: pageSizeAndLayoutView, tag: MainMenuAction.selectLayout, selection: $action) {
                    EmptyView()
                }
                
                //Titles
                let titlesView = LazyView(TitlesView(pageLayoutState: pageLayoutState, dismissAction: {
                    self.action = nil
                    self.pageLayoutState.didTitles = true
                }))
                NavigationLink(destination: titlesView, tag: MainMenuAction.titles, selection: $action) {
                    EmptyView()
                }
                
                //Page preview
                let pagePreviewView = LazyView(PagePreviewView(pageLayoutState: pageLayoutState, dismissAction: {
                    self.action = nil
                    self.pageLayoutState.didPrint = true
                }))
                NavigationLink(destination: pagePreviewView, tag: MainMenuAction.print, selection: $action) {
                    EmptyView()
                }
                
                //Settings
                let settingsView = LazyView(SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings())))
                NavigationLink(destination: settingsView, tag: MainMenuAction.settings, selection: $action) {
                    EmptyView()
                }

                //MARK: Views
                
                MainMenuButton(action: {action = .selectPhoto}, systemIconName: "photo", text: "Select Photos", showCheckMark: pageLayoutState.photoData.count>0)
                    .padding(8)
                    .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectPhotoButton)
                //                .sheet(isPresented: $isShowingPicker) {
                //                    PhotoPicker(
                //                        datas: $pageLayoutState.photoData,
                //                        configuration: photoPickerConfig,
                //                        pattern: photoPickerPattern
                //                    )
                //                }
                
                MainMenuButton(action: {action = .selectLayout}, systemIconName: "square.grid.2x2", text: "Page Size & Layout", showCheckMark: pageLayoutState.didPageLayout)
                    .padding(8)
                    .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectLayoutButton)

                MainMenuButton(action: {action = .titles}, systemIconName: "square.and.pencil", text: "Add Titles", showCheckMark: pageLayoutState.didTitles)
                    .padding(8)
                    .accessibility(identifier: AccessibilityIdentifiers.MainMenu.selectTitlesButton)
                
                MainMenuButton(action: {action = .print}, systemIconName: "printer", text: "Preview & Print", showCheckMark: pageLayoutState.didPrint)
                    .padding(8)
                    .accessibility(identifier: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
                
                settingsAndMoreAppsView
                
                
                //Spacer()
            //}
        }
        .background {
            Theme.backgroundColor
        }
        
    }
    
    private var col: GridItem {
       GridItem(.flexible(minimum: 0, maximum: 200))
   }
}



//struct MainMenuView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        MainMenuView(photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>)
//    }
//}


