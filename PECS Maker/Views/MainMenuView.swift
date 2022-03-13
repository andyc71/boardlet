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

struct MainMenuView: View {
    
    @State private var action: MainMenuAction?
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State private var isShowingPicker = false
    @State private var isShowingStoreView = false
    
    
    var storeVC: SKStoreProductViewController = SKStoreProductViewController()
    
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
                //                .sheet(isPresented: $isShowingPicker) {
                //                    PhotoPicker(
                //                        datas: $pageLayoutState.photoData,
                //                        configuration: photoPickerConfig,
                //                        pattern: photoPickerPattern
                //                    )
                //                }
                
                MainMenuButton(action: {action = .selectLayout}, systemIconName: "square.grid.2x2", text: "Page Size & Layout", showCheckMark: pageLayoutState.didPageLayout)
                    .padding(8)
                
                MainMenuButton(action: {action = .titles}, systemIconName: "square.and.pencil", text: "Add Titles", showCheckMark: pageLayoutState.didTitles)
                    .padding(8)
                
                MainMenuButton(action: {action = .print}, systemIconName: "printer", text: "Preview & Print", showCheckMark: pageLayoutState.didPrint)
                    .padding(8)
                
                //LazyVGrid(columns: [col, col]) {
                HStack {
                    MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: "Settings", isSecondary: true)
                        .padding(8)
                        .frame(maxHeight: .infinity)

                    MainMenuButton(action: {
                        storeVC.loadProduct(appID: AppSettings().developerID)
                        
                    }, systemIconName: "app.gift", text: "More Apps", isSecondary: true)
                        .padding(8)
                        .frame(maxHeight: .infinity)
                    //                    .sheet(isPresented: $isShowingStoreView) {
                    //                        StoreView(appID: AppSettings.developerID)
                    //                    }
                    
                }
                //.frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: 200)
                
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


