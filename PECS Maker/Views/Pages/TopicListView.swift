//
//  TopicListView.swift
//  PECS Maker
//
//  Created by Andy on 15/12/2022.
//

import SwiftUI
import LogFramework
import SharedSwiftUI
import LazyViewSwiftUI
import SwiftUIX

struct TopicAlertView: View {
    //@EnvironmentObject var repoFactory: PECSRepoFactory
    //@State var selectedTopic: PECSRepo?
    @Binding var isPresented: Bool
    var title: String
    var exclude: [PECSRepo] = []
    var onSelectTopic: (PECSRepo)->()
    
    
    private let gridItem = GridItem(.flexible())
    private let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        
        VStack(spacing: MFPopoverView.internalPaddingV) {
            
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: {self.isPresented = false }, label: {
                    Text(L10nSSUI.Alert.cancelButton)
                })
                .foregroundColor(.mfBrightBlue)
                .accessibilityIdentifier(AccessibilityIdentifiers.TopicListView.cancelButton)
            }
            ScrollView {
                LazyVGrid(columns: self.columns, spacing: 0) {
                    ForEach(PECSRepoFactory.shared.publishedTopics) { topic in
                        if !exclude.contains(topic) {
                            let index = PECSRepoFactory.shared.publishedTopics.firstIndex(of: topic)
                            Button(action: { onSelectTopic(topic) }, label: {
                                TopicCell(topic: topic, showDeleteButton: false )
                                    .padding(12)
                            })
                            .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index ?? 0))
                            .accessibility(label: Text(topic.topicName))
                        }
                    }
                }
            }
        }
        .padding()
        //.background( mfPopoverBackground )
    }
}

extension View {
    func topicSelectionAlert(isPresented: Binding<Bool>, title: String, exclude: PECSRepo? = nil, onSelectTopic: @escaping (PECSRepo)->()) -> some View {
        var excludeTopics = [PECSRepo]()
        if let exclude = exclude { excludeTopics.append(exclude)}
        return self.popover(present: isPresented, attributes: { configurePopover(&$0) }, view: {
            TopicAlertView(isPresented: isPresented, title: title, exclude: excludeTopics, onSelectTopic: onSelectTopic)
        }, background: { mfPopoverBackground})
    }}


struct TopicListView_Previews: PreviewProvider {
    static var previews: some View {
        //TopicSelectionView()
        Text("TO DO")
    }
}

