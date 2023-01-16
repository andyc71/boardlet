//
//  StateRestoration.swift
//  StateRestoration
//
//  Created by Andy on 24/09/2021.
//
// This code is currently not used because we have moved towards having the selected
// topic driven off RepoFactory.currentTopic and the selected screen stored within
// each topic itself.
// The code is kept to illustrate how we might want to integrate with any combo of
// SceneStorage, AppStorage or some NSUserActvity such as Handoff, Siri or Search.

import SwiftUI
import Combine
import SharedSwiftUI
import LogFramework

struct PECSStateRestoration : Codable {
    static let activityKey = "com.brightblue.EasyPECS.appState" //Need to match Info.plist
    //enum UserInfoKey : String { case topicName, mainMenuAction }
    var topicName: String?
    var mainMenuAction: MainMenuAction?
    
    enum CodingKeys: String, CodingKey { case topicName, mainMenuAction }
    
    init() {
    }
    
    init(topicName: String?, mainMenuAction: MainMenuAction?) {
        self.topicName = topicName
        self.mainMenuAction = mainMenuAction
    }
    
    //MARK: Codable
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        topicName = try values.decode(String.self, forKey: .topicName)
        mainMenuAction = try values.decode(MainMenuAction.self, forKey: .mainMenuAction)
      }

      func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topicName, forKey: .topicName)
        try container.encode(mainMenuAction, forKey: .mainMenuAction)
      }
}

extension PECSStateRestoration : RawRepresentable {
    
    //MARK: RawRepresentable, needed so we can store it within @SceneStorage or @AppStorage
    var rawValue: String {
      guard let data = try? JSONEncoder().encode(self),
            let string = String(data: data, encoding: .utf8)
      else {
        return "{}"
      }
      return string
    }
    
    init?(rawValue: String) {
      guard let data = rawValue.data(using: .utf8),
        let result = try? JSONDecoder().decode(PECSStateRestoration.self, from: data)
      else {
        return nil
      }
      self = result
    }
}

struct ContentViewWithRestoration: View {
    
    //MARK: App Restoration
    //All of this is now handled by the topic which has a menuMenu field to determine
    //which page should be displayed.
    //static let productUserActivityType = "com.brightblue.EasyPECS.PageLayoutState"
    //Don't want to persist mainMenuAction as SceneStorage because it will get
    //restored automatically, and we only want to restore it if the topic hasn't
    //changed (otherwise we should go to the default screen.
    
    @SceneStorage(PECSStateRestoration.activityKey) private var sceneState = PECSStateRestoration()
    
    @Environment(\.scenePhase)var scenePhase: ScenePhase
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    
    @Binding var topicToEdit: PECSRepo?
    @State var mainMenuAction: MainMenuAction?
    
    var body: some View {
        
        ContentView(topicToEdit: $topicToEdit)
        
        //MARK: App Restoration
            .onContinueUserActivity(PECSStateRestoration.activityKey) { userActivity in
                
                do {
                    let state = try userActivity.typedPayload(PECSStateRestoration.self)
                    guard self.topicToEdit?.topicName == state.topicName else { return }
                    mainMenuAction = state.mainMenuAction
                }
                catch {
                    logger.logError(.background, "Unable to restore application state", error)
                    return
                }
            }
            .onChange(of: scenePhase) { newScenePhase in
                if newScenePhase == .background {
                    //guard let sceneState = self.sceneState else { return }
                    self.sceneState = PECSStateRestoration(topicName: topicToEdit?.topicName, mainMenuAction: mainMenuAction)
                }
                else if newScenePhase == .active {
                    guard self.topicToEdit?.topicName == sceneState.topicName else { return }
                    self.mainMenuAction = sceneState.mainMenuAction
                }
            }
    }
}
    



