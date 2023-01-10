//
//  TopicContextMenu.swift
//  PECS Maker
//
//  Created by Andy on 15/12/2022.
//

import SwiftUI
import LogFramework
import SharedSwiftUI
import LazyViewSwiftUI
import SwiftUIX

struct TopicAction : Equatable {
    enum Action : Equatable { case view, rename, duplicate, delete }
    var action: Action
    var topic: PECSRepo
    init(_ topic: PECSRepo, _ action: Action) {
        self.topic = topic
        self.action = action
    }
    
}

extension View {
    
    @ViewBuilder
    func topicConextMenuItems(for topic: PECSRepo, selectedTopic: Binding<PECSRepo?>) -> some View {
        Button(L10n.TopicContextMenu.editButton, systemImage: SFSymbolName.eye) {
            selectedTopic.wrappedValue = topic
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.editButton)
        
        Button(L10n.TopicContextMenu.renameButton, systemImage: SFSymbolName.pencil) {
            selectedTopic.wrappedValue = topic
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.renameButton)
        
        Button(L10n.TopicContextMenu.duplicate, systemImage: SFSymbolName.plusSquareOnSquare) {
            selectedTopic.wrappedValue = topic
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.duplicateButton)
        
        DestructiveButton(L10n.TopicContextMenu.deleteButton, systemImage: SFSymbolName.trash) {
            selectedTopic.wrappedValue = topic
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.deleteButton)
    }
    
    @ViewBuilder
    func topicCellContextMenu(for topic: PECSRepo, selectedTopic: Binding<PECSRepo?>) -> some View {
        if #available(iOS 16.0, *) {
            contextMenu {
                
                topicConextMenuItems(for: topic, selectedTopic: selectedTopic)
                
            } preview: {
                Image(uiImage: topic.topicImage)
                    .resizable()
                //.frame(minWidth: 300, maxWidth: 500, maxHeight: 500)
                    .aspectRatio(contentMode: .fit)
            }
        } else {
            contextMenu {
                topicConextMenuItems(for: topic, selectedTopic: selectedTopic)
            }
        }
    }
    
    
    @ViewBuilder
    func topicConextMenuItems(for topic: PECSRepo, topicAction: Binding<TopicAction?>) -> some View {
        
        //Prior to IOS 16 we have 2 problems with ContextMenu:
        //1. AccessibilityIdentifier is completely lost
        //2. The first items shows up as "disabled" in Accessibility Instpector. To workaround this
        //we put the topic name as a label as the first item because it doesn't matter that this is
        //disabled.
        if #unavailable(iOS 16.0) {
            Text(topic.topicName)
        }
        
        Button(L10n.TopicContextMenu.editButton, systemImage: SFSymbolName.eye) {
            topicAction.wrappedValue = TopicAction(topic, .view)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.editButton)
        
        Button(L10n.TopicContextMenu.renameButton, systemImage: SFSymbolName.pencil) {
            topicAction.wrappedValue = TopicAction(topic, .rename)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.renameButton)
        
        Button(L10n.TopicContextMenu.duplicate, systemImage: SFSymbolName.plusSquareOnSquare) {
            topicAction.wrappedValue = TopicAction(topic, .duplicate)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.duplicateButton)
                
        DestructiveButton(L10n.TopicContextMenu.deleteButton, systemImage: SFSymbolName.trash) {
            topicAction.wrappedValue = TopicAction(topic, .delete)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.TopicContextMenu.deleteButton)
    }
    
    @ViewBuilder
    func topicCellContextMenu(for topic: PECSRepo, topicAction: Binding<TopicAction?>) -> some View {
        if #available(iOS 16.0, *) {
            contextMenu {
                topicConextMenuItems(for: topic, topicAction: topicAction)
            } preview: {
                Image(uiImage: topic.topicImage)
                    .resizable()
                //.frame(minWidth: 300, maxWidth: 500, maxHeight: 500)
                    .aspectRatio(contentMode: .fit)
            }
        } else {
            contextMenu {
                topicConextMenuItems(for: topic, topicAction: topicAction)
            }
        }
    }
    
    
}
