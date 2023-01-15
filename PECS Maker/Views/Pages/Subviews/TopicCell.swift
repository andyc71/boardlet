//
//  TopicCell.swift
//  PECS Maker
//
//  Created by Andy on 16/10/2022.
//

import SwiftUI
import PersistenceFramework
import ThemeFramework
import SharedSwiftUI

protocol ObservableTopic: TopicProtocol, ObservableObject {
    var topicName: String { get set }
}

struct TopicCell<TopicType: ObservableTopic>: View {
    
    @ObservedObject var topic: TopicType
    var showDeleteButton: Bool
    var internalPadding: CGFloat = 8
    var index: Int?
    
    @State private var showDeleteTopicPrompt: Bool = false
    @State private var showRenameAlert: Bool = false
    
    @State private var topicAction: TopicAction?
    
    init(topic: TopicType, showDeleteButton: Bool, internalPadding: CGFloat = 8, index: Int? = nil) {
        self.topic = topic
        self.showDeleteButton = showDeleteButton
        self.internalPadding = internalPadding
        self.index = index
        self.showDeleteTopicPrompt = showDeleteTopicPrompt
        self.showRenameAlert = showRenameAlert
        self.topicAction = topicAction
        //print("***topicName: \(topic.topicName) - \(topic.id.uuidString)")
//        if let topic = self.topic as? PECSRepo {
//            print("***topicName: \(topic.topicName) - \(topic.id.uuidString)")
//        }
    }
    
    var body: some View {
        VStack {
            Image(uiImage: topic.topicImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(8)
                .shadow(radius: 8)
            
                .if(showDeleteButton) { view in
                    view.overlay(
                        Button(action: { showDeleteTopicPrompt = true } ) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.systemRed)
                                .font(.title2)
                        }
                        .frame(width:44, height: 44)
                        .offset(x: -22, y: -22)
                        .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicDeleteButton(for: index ?? 0))
                        //TODO: Localize
                        .accessibilityLabel("Delete topic \(index ?? 0)")
                        ,alignment: .topLeading
                    )
                }
            
            Text(topic.topicName)
                .font(.caption)
                .foregroundColor(Color(currentTheme.linkTextColor))
            Spacer()
        }

        .askQuestionYesNo(isPresented: $showDeleteTopicPrompt, title: L10n.TopicSelectionView.DeleteTopicAlert.title, message: L10n.TopicSelectionView.DeleteTopicAlert.message(topic.topicName), isDestructive: true, yesAction: {
            PECSRepoFactory.shared.deleteTopic(topic as! PECSRepo)
        }, noAction: { } )
        
        .renameItemAlert(isPresented: $showRenameAlert, itemName: $topic.topicName, placeholder: L10n.RenameTopicAlert.placeholder, title: L10n.RenameTopicAlert.title, message: nil, saveAction: {})
        /*
        .topicCellContextMenu(for: topic as! PECSRepo, topicAction: $topicAction)
        
        .onChange(of: topicAction) { newValue in
            topicAction = .none
            switch newValue {
            case .none:
                return
            case .view:
                return
            case .duplicate:
                try? PECSRepoFactory.shared.duplicateTopic(repo: topic as! PECSRepo)
                return
            case .rename:
                showRenameAlert = true
            case .delete:
                showDeleteTopicPrompt = true
            }
        }
*/
    }
}

struct TopicCell_Previews: PreviewProvider {
    
    class TestTopic: ObservableTopic {
        var topicName: String = "My Topic"
        var topicCategory: ThemeFramework.TopicCategory = .other
        var topicDirectoryName: String?
        var hasSkin: Bool?
        var hasSoundTheme: Bool?
        var topicImage: UIImage = UIImage(systemName: "squareshape.split.3x3")!
    }
        
    static var previews: some View {
        TopicCell<TestTopic>(topic: TestTopic(), showDeleteButton: true)
            .frame(maxWidth: 100, maxHeight: 100)
    }
    
    
}
