//
//  PECSRepoFactory.swift
//  PECS Maker
//
//  Created by Andy on 14/10/2022.
//

import Combine
import PersistenceFramework
import LogFramework
import SwiftUI

class PECSRepoFactory : RepoFactory<PECSRepo>, ObservableObject {
    
    static var shared = PECSRepoFactory()
    
    @Published var publishedTopics: [PECSRepo] = []
    
    @Published var publishedCurrentTopic: PECSRepo? {
        didSet {
            //print("***currentTopic: \(publishedCurrentTopic?.topicName) - \(publishedCurrentTopic?.id.uuidString)")
            if currentTopic != publishedCurrentTopic {
                currentTopic = publishedCurrentTopic
            }
        }
    }
    
    override public func availableTopicsDidChange() {
        DispatchQueue.main.async {
            self.publishedTopics.removeAll()
            self.publishedTopics.append(contentsOf: self.availableTopics)
        }
    }
    
    override public func currentTopicDidChange(newValue: PECSRepo?) {
        //NOTE: Delay removed and re-implemented in the second push
        //within MainMenu
        //We're putting in a delay to avoid undesirable behaviour with
        //NavigationView configured as a split view. When setting currentTopic
        //during the initializer, this results in two pushes into the
        //navigation stack (first one for selected topic, and the next
        //one for the selected page from MainMenu). As a result, the
        //screens are getting pushed into the wrong split view panes, and
        //the delay helps to avoid this.
        //let delay = 0.75
        let delay = 0.0
        //print("currentTopic: \(newValue)")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.publishedCurrentTopic = self.currentTopic
        }
    }
    
    override func createEmptyRepo(directoryURL: URL? = nil, setActive: Bool) throws -> PECSRepo {
        let newTopic = try super.createEmptyRepo(directoryURL: directoryURL, setActive: setActive)
        
        //PageLayoutState will ensure we get a suitable icon based on a thumbnail of
        //all the iamges in the topic.
        _ = PageLayoutState(newTopic: newTopic)
        
        return newTopic
    }
    
    private override init() {
        super.init()
        
        //currentTopic = availableTopics.first
        //publishedCurrentTopic = availableTopics.first
        
        do {
            try loadCurrentRepo(makeActive: true, alternateTopicStrategies: [.createEmptyIfNoTopicsExist])
            //let repo = try loadCurrentRepo(makeActive: true, alternateTopicStrategies: [.createEmptyIfNoTopicsExist])
            //publishedCurrentTopic = repo
        }
        catch {
        }
        
    }

}
