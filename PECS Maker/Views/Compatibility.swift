//
//  Compatibility.swift
//  PECS Maker
//
//  Created by Andy on 26/01/2023.
//

import SwiftUI

typealias PECSRepo = PageLayoutState

extension PECSRepo {
    var topic: Topic { Topic() }
}

extension PageLayoutState : Equatable {
    static func == (lhs: PageLayoutState, rhs: PageLayoutState) -> Bool {
        return false
    }
}

class Topic {
    var topicName: String = "Easy PECS"
    var mainMenuAction: MainMenuAction?
}

class PECSRepoFactory : ObservableObject {
    static var shared = PECSRepoFactory()
    
    @Published var publishedCurrentTopic: PECSRepo? = PECSRepo()
    
    private init() {
    }
}

struct TopicSelectionView : View {
    
    @Binding var mainMenuAction: MainMenuAction?
    @Binding var topicToEdit: PECSRepo?
    var isForSplitView: Bool

    var body : some View {
        if let topicToEdit = self.topicToEdit {
            MainMenuView(topic: topicToEdit, action: $mainMenuAction, isForSplitView: isForSplitView)
        }
        else {
            Text("Error - topic should never be nil")
        }
    }
    
}


