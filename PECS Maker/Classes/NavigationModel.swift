//
//  NavigationModel.swift
//  PECS Maker
//
//  Created by Andy on 05/03/2025.
//
import SwiftUI
import SettingsFramework

enum AppRoute: Hashable, Codable {
    case topic(UUID)
    case action(topicID: UUID, action: MainMenuAction)

    var topicID: UUID {
        switch self {
        case .topic(let topicID), .action(let topicID, _):
            topicID
        }
    }

    var action: MainMenuAction? {
        guard case .action(_, let action) = self else { return nil }
        return action
    }
}

enum NavigationPresentation: String, Codable, Equatable {
    case compact
    case split
}

/// Owns the editor lifetime for one persisted board identity. Views can keep
/// consuming PageLayoutState while routing and ownership move to this boundary.
@MainActor
final class BoardEditorStore: ObservableObject, Identifiable {
    let id: UUID
    let pageLayoutState: PageLayoutState

    init(topic: PECSRepo) {
        id = topic.id
        pageLayoutState = PageLayoutState(topic: topic)
    }
}

@MainActor
final class NavigationModel: ObservableObject {
    
    @Published private(set) var route: AppRoute?
    @Published private(set) var presentation: NavigationPresentation = .compact
    @Published private(set) var activeEditor: BoardEditorStore?

    private var topicsByID: [UUID: PECSRepo] = [:]
    private var editorsByTopicID: [UUID: BoardEditorStore] = [:]

    var pageLayoutState: PageLayoutState? { activeEditor?.pageLayoutState }
    var currentAction: MainMenuAction? { route?.action }

    var compactPath: [AppRoute] {
        guard let route else { return [] }
        switch route {
        case .topic:
            return [route]
        case .action(let topicID, _):
            return [.topic(topicID), route]
        }
    }

    func prepareTopic(_ topic: PECSRepo) {
        topicsByID[topic.id] = topic
        if let editor = editorsByTopicID[topic.id], editor.pageLayoutState.topic === topic {
            activeEditor = editor
        } else {
            let editor = BoardEditorStore(topic: topic)
            editorsByTopicID[topic.id] = editor
            activeEditor = editor
        }
    }
    
    func setTopic(_ topic: PECSRepo) {
        let existingEditor = editorsByTopicID[topic.id]
        prepareTopic(topic)
        existingEditor?.pageLayoutState.refreshPhotosFromTopic()
        route = .topic(topic.id)
    }
    
    func setMainMenuAction(_ action: MainMenuAction) {
        guard let topicID = activeEditor?.id else { return }
        route = .action(topicID: topicID, action: action)
    }

    func clearMainMenuAction() {
        guard let topicID = route?.topicID else { return }
        route = .topic(topicID)
    }

    func updateMainMenuAction(_ action: MainMenuAction?) {
        if let action {
            setMainMenuAction(action)
        } else {
            clearMainMenuAction()
        }
    }

    func updateCompactPath(_ path: [AppRoute]) {
        guard let newRoute = path.last else {
            clearSelection()
            return
        }

        guard let topic = topicsByID[newRoute.topicID] else {
            clearSelection()
            return
        }

        prepareTopic(topic)
        route = newRoute
    }

    func adapt(toSplitView isSplitView: Bool) {
        presentation = isSplitView ? .split : .compact
    }

    func restore(_ restoredRoute: AppRoute?, from topics: [PECSRepo]) {
        topicsByID = Dictionary(uniqueKeysWithValues: topics.map { ($0.id, $0) })
        guard let restoredRoute,
              let topic = topicsByID[restoredRoute.topicID] else {
            clearSelection()
            return
        }
        prepareTopic(topic)
        route = restoredRoute
    }

    func topic(for id: UUID) -> PECSRepo? {
        topicsByID[id]
    }

    func clearSelection() {
        route = nil
        activeEditor = nil
    }

    @ViewBuilder
    func makeDetailView(for action: MainMenuAction, isForSplitView: Bool, appMode: Binding<PECSAppMode>) -> some View {
        let pageLayoutState = route.flatMap { editorsByTopicID[$0.topicID]?.pageLayoutState }
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
                    pageLayoutState.save()
                })
            }
            else {
                Text("Error: PageLayoutState not set")
            }
            
        case .selectLayout:
            if let pageLayoutState {
                PageSizeAndLayoutView(pageLayoutState: pageLayoutState, dismissAction: {
                    pageLayoutState.checkmarks.didPageLayout = true
                    pageLayoutState.save()
                })
            }
            else {
                Text("Error: PageLayoutState not set")
            }

        case .titles:
            if let pageLayoutState {
                TitlesView(pageLayoutState: pageLayoutState, dismissAction: {
                    pageLayoutState.checkmarks.didTitles = true
                    pageLayoutState.save()
                })
            }
            else {
                Text("Error: PageLayoutState not set")
            }

        case .print:
            if let pageLayoutState {
                PagePreviewView(pageLayoutState: pageLayoutState, dismissAction: {
                    pageLayoutState.checkmarks.didPrint = true
                    pageLayoutState.save()
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
