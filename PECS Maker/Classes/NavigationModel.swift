//
//  NavigationModel.swift
//  PECS Maker
//
//  Created by Andy on 05/03/2025.
//
import SwiftUI
import SettingsFramework

@MainActor
class NavigationModel: ObservableObject {
    
    @Published var path = NavigationPath()
    @Published var splitPath: [MainMenuAction] = []
    // The depth at which the compact stack opened its current menu screen.
    private var compactActionPathDepth: Int?
    private var choiceBoardReturnAction: MainMenuAction?
    
    @Published var pageLayoutState: PageLayoutState?

    func prepareTopic(_ topic: PECSRepo) {
        guard pageLayoutState?.topic != topic else { return }
        choiceBoardReturnAction = nil
        splitPath = []
        pageLayoutState = PageLayoutState(topic: topic)
    }

    func enterChoiceBoard(returningTo action: MainMenuAction?) {
        choiceBoardReturnAction = action
    }

    func takeChoiceBoardReturnAction() -> MainMenuAction? {
        defer { choiceBoardReturnAction = nil }
        return choiceBoardReturnAction
    }
    
    /// Preserve the current board while leaving screens belonging to the previous interface.
    func resetInterfaceNavigation() {
        pageLayoutState?.save()
        splitPath = []
        choiceBoardReturnAction = nil
        compactActionPathDepth = nil
        if !path.isEmpty {
            path = NavigationPath()
            if let topic = pageLayoutState?.topic { path.append(topic) }
        }
    }

    func setTopic(_ topic: PECSRepo) {
        prepareTopic(topic)
        
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
        compactActionPathDepth = path.count
        self.path = path
    }

    func setSplitAction(_ action: MainMenuAction) {
        splitPath.append(action)
    }

    func didPopCompactAction() -> Bool {
        guard let compactActionPathDepth, path.count < compactActionPathDepth else { return false }
        self.compactActionPathDepth = nil
        return true
    }

    func popCompactAction() {
        guard let compactActionPathDepth, path.count >= compactActionPathDepth else { return }
        var path = self.path
        path.removeLast(path.count - compactActionPathDepth + 1)
        self.path = path
    }
    
    @ViewBuilder
    func makeDetailView(for action: MainMenuAction, isForSplitView: Bool,
                        appMode: Binding<PECSAppMode>, mainMenuAction: Binding<MainMenuAction?>,
                        interfaceStyle: InterfaceStyle = .modern) -> some View {
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
                if interfaceStyle == .classic {
                    ClassicSelectedPhotosView(pageLayoutState: pageLayoutState, appMode: appMode,
                                              isForSplitView: isForSplitView, dismissAction: { pageLayoutState.save() })
                } else {
                    PhotoListView2(pageLayoutState: pageLayoutState,
                                   appMode: appMode,
                                   mainMenuAction: mainMenuAction,
                                   isForSplitView: isForSplitView,
                                   dismissAction: {
                        DispatchQueue.main.async {
                            //self.action = nil
                            pageLayoutState.save()
                        }})
                }
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
                if interfaceStyle == .classic {
                    ClassicPreviewAndPrintView(pageLayoutState: pageLayoutState, dismissAction: {
                        pageLayoutState.checkmarks.didPrint = true
                        pageLayoutState.save()
                    })
                } else {
                    PhotoListView2(pageLayoutState: pageLayoutState, appMode: appMode,
                                   mainMenuAction: mainMenuAction, isForSplitView: isForSplitView, dismissAction: {
                        DispatchQueue.main.async {
                            //self.action = nil
                            pageLayoutState.checkmarks.didPrint = true
                            pageLayoutState.save()
                        }
                    })
                }
            }
            else {
                Text("Error: PageLayoutState not set")
            }

            
        case .settings:
            SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings.shared), isForSplitView: false)
            
        }
        
    }
    
}
