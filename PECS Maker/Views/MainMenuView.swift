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


enum MainMenuAction { case selectPhoto, selectPageSize, selectLayout, titles, print, settings }

struct MainMenuView: View {
    
    @State private var action: MainMenuAction?
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State private var isShowingPicker = false
    @State private var isShowingStoreView = false
    
    
    var storeVC: SKStoreProductViewController = SKStoreProductViewController()
    
    var body: some View {
        VStack {
            
            //            NavigationLink(destination: Text("Destination_1"), tag: MainMenuAction.selectPhoto, selection: $action) {
            //                    EmptyView()
            //            }
            NavigationLink(destination: PhotoPicker(
                datas: $pageLayoutState.photoData,
                configuration: photoPickerConfig,
                pattern: photoPickerPattern
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarHidden(true),
            tag: MainMenuAction.selectPhoto,
            selection: $action) {
                EmptyView()
            }
            
            NavigationLink(destination: PageSizeAndLayoutView(pageLayoutState: pageLayoutState, isVertical: true, dismissAction: {
                self.action = nil
                self.pageLayoutState.didPageLayout = true
            }), tag: MainMenuAction.selectLayout, selection: $action) {
                EmptyView()
            }
            
            NavigationLink(destination: TitlesView(pageLayoutState: pageLayoutState, dismissAction: {
                self.action = nil
                self.pageLayoutState.didTitles = true
            }), tag: MainMenuAction.titles, selection: $action) {
                EmptyView()
            }

            NavigationLink(destination:
                            PagePreviewView(pageLayoutState: pageLayoutState, dismissAction: {
                self.action = nil
                self.pageLayoutState.didPrint = true
            }), tag: MainMenuAction.print, selection: $action) {
                EmptyView()
            }
            
            NavigationLink(destination: SettingsView(settingsViewModel: SettingsViewModel()),
                           tag: MainMenuAction.settings, selection: $action) {
                EmptyView()
            }
            
            
            
            MainMenuButton(action: {action = .selectPhoto}, systemIconName: "photo", text: "Select Photos", showCheckMark: pageLayoutState.photoData.count>0)
                .padding()
            //                .sheet(isPresented: $isShowingPicker) {
            //                    PhotoPicker(
            //                        datas: $pageLayoutState.photoData,
            //                        configuration: photoPickerConfig,
            //                        pattern: photoPickerPattern
            //                    )
            //                }
            
            MainMenuButton(action: {action = .selectLayout}, systemIconName: "square.grid.2x2", text: "Page Size & Layout", showCheckMark: pageLayoutState.didPageLayout)
                .padding()
            
            MainMenuButton(action: {action = .titles}, systemIconName: "square.and.pencil", text: "Add Titles", showCheckMark: pageLayoutState.didTitles)
                .padding()
            
            MainMenuButton(action: {action = .print}, systemIconName: "printer", text: "Preview & Print", showCheckMark: pageLayoutState.didPrint)
                .padding()
            
            HStack {
                MainMenuButton(action: {action = .settings}, systemIconName: "gear", text: "Settings", isSecondary: true)
                    .padding()
                
                MainMenuButton(action: {
                    storeVC.loadProduct(appID: AppSettings.developerID)
                    
                }, systemIconName: "app.gift", text: "More Apps", isSecondary: true)
                    .padding()
                //                    .sheet(isPresented: $isShowingStoreView) {
                //                        StoreView(appID: AppSettings.developerID)
                //                    }
            }
            
            //Spacer()
        }
        .background {
            Theme.backgroundColor
        }
        
    }
}

//struct MainMenuView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        MainMenuView(photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>photoData: <#Binding<[PhotoPickerData?]>#>, pageLayoutState: <#PageLayoutState#>)
//    }
//}


