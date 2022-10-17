//
//  TopicCell.swift
//  PECS Maker
//
//  Created by Andy on 16/10/2022.
//

import SwiftUI
import PersistenceFramework
import ThemeFramework

protocol ObservableTopic: TopicProtocol, ObservableObject {
    
}

struct TopicCell<TopicType: ObservableTopic>: View {
    
    @ObservedObject var topic: TopicType
    var onDelete: (TopicType)->()
    var internalPadding: CGFloat = 8
    
    @State private var showDeleteTopicPrompt: Bool = false
    
    var body: some View {
        VStack {
            Image(uiImage: topic.topicImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text(topic.topicName)
            //.width(.infinity)
                .font(.caption)
        }
        .padding(internalPadding)
        .roundedBackgroundStyle(backgroundColor: .clear, borderColor: .gray)
        .overlay(
            Button(action: { showDeleteTopicPrompt = true } ) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.systemRed)
                    .font(.title2)
                    //.frame(width:44,height: 44)
                    //.offset(x: 22, y: -22)
            }
                .frame(width:44,height: 44)
                .offset(x: 22, y: -22)

            ,alignment: .topTrailing
        )
        .askQuestionYesNo(isPresented: $showDeleteTopicPrompt, title: L10n.TopicSelectionView.DeleteTopicAlert.title, message: L10n.TopicSelectionView.DeleteTopicAlert.message(topic.topicName), yesAction: {
            onDelete(topic)
        }, noAction: {} )

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
        TopicCell<TestTopic>(topic: TestTopic(), onDelete: {_ in })
            .frame(maxWidth: 100, maxHeight: 100)
    }
    
    
}
