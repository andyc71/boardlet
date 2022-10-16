//
//  PECSRepoFactory.swift
//  PECS Maker
//
//  Created by Andy on 14/10/2022.
//

import Combine
import PersistenceFramework

class PECSRepoFactory : RepoFactory<PECSRepo>, ObservableObject {
    
    @Published var publishedTopics: [PECSRepo] = []
    
    override public func availableTopicsDidChange() {
        self.publishedTopics.removeAll()
        self.publishedTopics.append(contentsOf: availableTopics)
    }
    
    override init() {
    }

}
