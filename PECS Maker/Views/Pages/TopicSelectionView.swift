//
//  TopicSelectionView.swift
//  PECS Maker
//
//  Created by Andy on 13/10/2022.
//

import SwiftUI
import LogFramework
import SharedSwiftUI
import LazyViewSwiftUI

struct TopicSelectionView: View {
    @EnvironmentObject var repoFactory: PECSRepoFactory
    
    @State var newTopic: PECSRepo?
    @State var selectedTopic: PECSRepo?
    @State var isEditMode: Bool = false
    
    @State var largeTopic: PECSRepo?
    
    //let gridItem = GridItem(.fixed(50))
    let gridItem = GridItem(.flexible())
    
    //    var columns: [GridItem] {
    //        let layoutCounts = pageLayoutState.availableLayouts.count
    //        let colCount = min(layoutCounts, pageLayoutState.orientation == .portrait ? 6 : 5)
    //        return Array(repeating: gridItem, count: colCount)
    //    }
    
    //private var columns: [GridItem] { Array(repeating: gridItem, count: 2) }
    
    //private let size: CGFloat = 50
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    init() {
        
    }
    
    @MainActor
    func createTopic() {
        withAnimation {
            self.selectedTopic = nil
            let pls = PageLayoutState(topic: nil)
            self.newTopic = pls.topic
        }
    }
    
    @MainActor
    func deleteTopic(_ topic: PECSRepo) {
        withAnimation {
            repoFactory.deleteTopic(topic)
        }
    }
    
    var body: some View {
        
        VStack {

            if let largeTopic = largeTopic {
                Button( action: { withAnimation { self.largeTopic = nil } }, label: {
                        Image(uiImage: largeTopic.topicImage)
                            .resizable()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .aspectRatio(contentMode: .fit)
                        })
            }
            else {
                
                LazyVGrid(columns: self.columns, spacing: 0) {
                    //HStack{
                    
                    //ForEach((0..<pageLayoutState.availableLayouts.count), id: \.self) { i in
                    //ForEach((0...5), id: \.self) { i in
                    ForEach(repoFactory.publishedTopics) { topic in
                        
                        //let pageLayoutState = PageLayoutState(topic: topic)
                        
                        //let topicView = MainMenuView(pageLayoutState: pageLayoutState)
                        let topicView = MainMenuView(topic: topic)
                            .padding()
                            .background(Color(currentTheme.backgroundColor))
                            .ignoresSafeArea()
                        
                        NavigationLink(
                            destination: LazyView(topicView),
                            tag: topic,
                            selection: $selectedTopic)
                        {
                            TopicCell(topic: topic, showDeleteButton: isEditMode, onDelete: { topic in self.deleteTopic(topic) } )
                                .padding(12)
                                .topicCellContextMenu(for: topic)
                                .onTapGesture {
                                    selectedTopic = topic
                                }
                                .onLongPressGesture {
                                    withAnimation {
                                        largeTopic = topic
                                    }
                                }
                        }
                        .accessibility(identifier: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: topic.id))

                    }
                    
                }
            }
            
            //            .emptyListPlaceholder(repoFactory.publishedTopics) {
            //                TipView(tipText: L10n.TopicSelectionView.noTopicsMessage, canHide: false)
            //                //.padding(8)
            //                    .listRowBackground(Color(currentTheme.backgroundColor))
            //            }
            
            if repoFactory.publishedTopics.count == 0 {
                TipView(tipText: L10n.TopicSelectionView.noTopicsMessage, canHide: false)
                //.padding(8)
                //.listRowBackground(Color(currentTheme.backgroundColor))
            }
            
            StandardButton(action: {
                createTopic()
                
            }, /*systemIconName: "checkmark",*/ text: L10n.TopicSelectionView.createDesignButton, purpose: .primary
            )
            //.padding()
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.createDesignButton)
            
            
            if let newTopic = self.newTopic {
                
                let topicView = MainMenuView(topic: newTopic)
                    .padding()
                    .background(Color(currentTheme.backgroundColor))
                    .ignoresSafeArea()
                
                NavigationLink(destination: LazyView(topicView), tag: newTopic, selection: $newTopic) { EmptyView() }
            }
            
            
            
        }
        .navigationBarTitle(Text(L10n.TopicSelectionView.title), displayMode: .inline)
        .toolbar(content: {
            Button(action: { isEditMode.toggle() } ) {
                //Image(systemName: "doc.badge.plus")
                //.foregroundColor(.mfBrightBlue)
                Text(isEditMode ? L10n.TopicSelectionView.doneButton : L10n.TopicSelectionView.editButton )
                    .foregroundColor(Color( currentTheme.headerStyle.textColor))
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.TopicSelectionView.editButton)
        })
        
        .padding()
        .frame(maxWidth: .infinity)
        .scrollContentHideBackground()
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
        .onAppear {
            MFAnalytics.logScreenView(screenName: "Topic Selection")
        }
        
    }}

struct TopicSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        //TopicSelectionView()
        Text("TO DO")
    }
}

extension View {
    
    func topicCellContextMenu(for topic: PECSRepo) -> some View  {
        /*
        if #available(iOS 16.0, *) {
            return contextMenu {
                Text("Hello")
            } preview: {
                Image(uiImage: topic.topicImage)
            }
        } else {
            return contextMenu {
                Text("Hello")
            }
        }*/
        return self

    }

}
