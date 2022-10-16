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
    
    override public func availableTopicsDidChange() {
        DispatchQueue.main.async {
            self.publishedTopics.removeAll()
            self.publishedTopics.append(contentsOf: self.availableTopics)
        }
    }
    
    private override init() {
    }

}
