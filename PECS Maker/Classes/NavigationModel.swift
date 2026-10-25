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
    
    enum Focus {
        case boards, menu, editor
    }

    // Selection and editor ownership are independent of how many columns fit.
    @Published private(set) var pageLayoutState: PageLayoutState?
    @Published private(set) var mainMenuAction: MainMenuAction?
    @Published var topicsAreMaximized = false
    @Published var focus: Focus = .boards {
        didSet {
            if oldValue == .editor && focus != .editor { finishEditing() }
        }
    }

    var selectedTopic: PECSRepo? { pageLayoutState?.topic }

    func selectTopic(_ topic: PECSRepo?) {
        topicsAreMaximized = false
        if selectedTopic?.id != topic?.id {
            finishEditing()
            pageLayoutState = topic.map { PageLayoutState(topic: $0) }
            if topic == nil {
                mainMenuAction = nil
            } else if mainMenuAction == nil {
                mainMenuAction = .changeSelections
            }
        }
        focus = topic == nil ? .boards : (focus == .editor ? .editor : .menu)
    }

    func synchronizeTopic(_ topic: PECSRepo?) {
        guard selectedTopic?.id != topic?.id else { return }
        selectTopic(topic)
    }

    func setMainMenuAction(_ action: MainMenuAction?) {
        guard selectedTopic != nil else { return }
        if mainMenuAction != action { finishEditing() }
        mainMenuAction = action
        focus = action == nil ? .menu : .editor
    }

    // Navigation commits cannot depend on disappearance: adaptive columns may
    // remain mounted when Back hides them, or disappear merely while resizing.
    private func finishEditing() {
        guard let pageLayoutState else { return }
        switch mainMenuAction {
        case .titles?: pageLayoutState.checkmarks.didTitles = true
        case .selectLayout?: pageLayoutState.checkmarks.didPageLayout = true
        case .print?: pageLayoutState.checkmarks.didPrint = true
        default: break
        }
        pageLayoutState.save()
    }

    private lazy var settingsViewModel = SettingsViewModel(config: AppSettings.shared)

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
            SettingsView(settingsViewModel: settingsViewModel)
            
        }
        
    }
    
}
