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

    @State var newTopic: PageLayoutState?
    @State var selectedTopic: PECSRepo?
    @State var showDeleteTopicPrompt: Bool = false

    //let gridItem = GridItem(.fixed(50))
    let gridItem = GridItem(.flexible())
    
//    var columns: [GridItem] {
//        let layoutCounts = pageLayoutState.availableLayouts.count
//        let colCount = min(layoutCounts, pageLayoutState.orientation == .portrait ? 6 : 5)
//        return Array(repeating: gridItem, count: colCount)
//    }
    
    private var columns: [GridItem] { Array(repeating: gridItem, count: 2) }

    init() {
        
    }
    
    @MainActor
    func createTopic() {
        withAnimation {
            self.selectedTopic = nil
            self.newTopic = PageLayoutState(topic: nil)
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
//            Text(L10n.TopicSelectionView.title)
//                .padding(.bottom, 8)
            
            LazyVGrid(columns: self.columns) {
                //HStack{
                
                //ForEach((0..<pageLayoutState.availableLayouts.count), id: \.self) { i in
                //ForEach((0...5), id: \.self) { i in
                ForEach(repoFactory.publishedTopics) { topic in
                    
                    let pageLayoutState = PageLayoutState(topic: topic)
                    
                    let topicView = MainMenuView(pageLayoutState: pageLayoutState)
                        .padding()
                        .background(Color(currentTheme.backgroundColor))
                        .ignoresSafeArea()
                    
                    NavigationLink(
                        destination: LazyView(topicView),
                        tag: topic,
                        selection: $selectedTopic)
                    {
                        TopicCell(topic: topic, onDelete: { topic in self.deleteTopic(topic) } )
                            .padding(20)
                        
                        
                    }
                    //.accessibility(identifier: AccessibilityIdentifiers.LayoutScreen.layoutButton(for: layoutSize))
                    //                .if(isSelected) { view in
                    //                    view.accessibility(addTraits: [.isSelected])
                    //                }
                    
                }
                
//                .emptyListPlaceholder(pageLayoutState.photos) {
//                    TipView(tipText: L10n.TitlesScreen.noPhotosMessage, canHide: false)
//                    //.padding(8)
//                        .listRowBackground(Color(currentTheme.backgroundColor))
//                }
            }

            if let newTopic = self.newTopic {
                
                let topicView = MainMenuView(pageLayoutState: newTopic)
                    .padding()
                    .background(Color(currentTheme.backgroundColor))
                    .ignoresSafeArea()

                NavigationLink(destination: LazyView(topicView), tag: newTopic, selection: $newTopic) { EmptyView() }
            }
            
            
            StandardButton(action: {
                createTopic()
                
            }, /*systemIconName: "checkmark",*/ text: "New Design", isHorizontal: true)
                .padding()
                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.doneButton)


        }
        .navigationBarTitle(Text(L10n.TopicSelectionView.title), displayMode: .inline)
        .toolbar(content: {
            Button(action: { createTopic() }) {
                Image(systemName: "doc.badge.plus")
                    .foregroundColor(.mfBrightBlue)
            }
        })
        
        .frame(maxWidth: AppSettings.maxViewWidth)
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
