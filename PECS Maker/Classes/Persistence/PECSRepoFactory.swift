//
//  PECSRepoFactory.swift
//  PECS Maker
//
//  Created by Andy on 14/10/2022.
//

import Combine
import PersistenceFramework

class PECSRepoFactory : RepoFactory<PECSRepo>, ObservableObject {
    
    static var shared = PECSRepoFactory()
    
    @Published var publishedTopics: [PECSRepo] = []
    
    @Published var publishedCurrentTopic: PECSRepo? {
        didSet {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.publishedCurrentTopic = self.currentTopic
        }
    }
    
    private override init() {
        super.init()
        
        //TODO: Leverage the application setting of current topic that's used in My Family
        currentTopic = availableTopics.first
        //publishedCurrentTopic = availableTopics.first
    }

}
