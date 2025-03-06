//
//  NavigationModel.swift
//  PECS Maker
//
//  Created by Andy on 05/03/2025.
//
import SwiftUI
import SettingsFramework

class NavigationModel: ObservableObject {
    
    @Published var path = NavigationPath()
    
    @Published var pageLayoutState: PageLayoutState?
    
    func setTopic(_ topic: PECSRepo) {
        self.pageLayoutState = PageLayoutState(topic: topic)
        
        //Append to the path. It's a struct so we need to re-assign the
        //modified copy afterwards.
        var path = self.path
        path.append(topic)
        self.path = path
    }
    
    func setMainMenuAction(_ action: MainMenuAction) {
        //Append to the path. It's a struct so we need to re-assign the
        //modified copy afterwards.
        var path = self.path
        path.append(action)
        self.path = path
    }
    
    @ViewBuilder
    func makeDetailView(for action: MainMenuAction, isForSplitView: Bool, appMode: Binding<PECSAppMode>) -> some View {
        switch action {

        case .changeTopicIcon:
            if let pageLayoutState {
                TopicImageSelector(pageLayoutState: pageLayoutState)
            }
            else {
                Text("Error: PageLayoutState not set")
            }
            
        case .selectPhoto:
            EmptyView()
            /*
            let selectPhotoView = LazyView(PhotoListView2(pageLayoutState: pageLayoutState, dismissAction: {
                DispatchQueue.main.async {
                    //self.action = nil
                    pageLayoutState.save()
                }}))
            selectPhotoView
             */

        case .changeSelections:
            if let pageLayoutState {
                PhotoListView2(pageLayoutState: pageLayoutState,
                               appMode: appMode,
                               isForSplitView: isForSplitView,
                               dismissAction: {
                    DispatchQueue.main.async {
                        //self.action = nil
                        pageLayoutState.save()
                    }})
            }
            else {
                Text("Error: PageLayoutState not set")
            }
            
        case .selectLayout:
            if let pageLayoutState {
                PageSizeAndLayoutView(pageLayoutState: pageLayoutState, dismissAction: {
                    DispatchQueue.main.async {
                        pageLayoutState.checkmarks.didPageLayout = true
                        //selection.wrappedValue = nil
                        pageLayoutState.save()
                    }
                })
            }
            else {
                Text("Error: PageLayoutState not set")
            }

        case .titles:
            if let pageLayoutState {
                TitlesView(pageLayoutState: pageLayoutState, dismissAction: {
                    DispatchQueue.main.async {
                        //self.action = nil
                        pageLayoutState.checkmarks.didTitles = true
                        pageLayoutState.save()
                    }
                })
            }
            else {
                Text("Error: PageLayoutState not set")
            }

        case .print:
            if let pageLayoutState {
                PagePreviewView(pageLayoutState: pageLayoutState, dismissAction: {
                    DispatchQueue.main.async {
                        //self.action = nil
                        pageLayoutState.checkmarks.didPrint = true
                        pageLayoutState.save()
                    }
                })
            }
            else {
                Text("Error: PageLayoutState not set")
            }

            
        case .settings:
            SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings.shared), isForSplitView: isForSplitView)
            
        }
        
    }
    
}
