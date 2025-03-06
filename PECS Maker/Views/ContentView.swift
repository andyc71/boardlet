//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine
import SharedSwiftUI
import LogFramework
import MediaFramework

struct ContentView: View {
    
    @EnvironmentObject var currentTheme: SharedUITheme

    @StateObject var repoFactory = PECSRepoFactory.shared
    @StateObject var errorHandler = ErrorHandler.shared
    
    @Binding var topicToEdit: PECSRepo?
    
    @AppStorage("appMode")
    var appMode: PECSAppMode = .pecsMaker
    
    //AppStorage with optionals isn't supported on IOS14 and the
    //backport doesn't work for some reason, so we just go with
    //a @State variable for now. We have also experimented with
    //storing the mainMenuAction within a specific page set, but
    //not sure why we need this individual behaviour.
    @State
    //@AppStorage("mainMenuAction")
    var mainMenuAction: MainMenuAction?
    
    @State var selectedItems: [PhotoItem] = []
    
    //@State var navigationModel = NavigationModel()
    @StateObject private var navigationModel = NavigationModel()
    
    //@Environment(\.horizontalSizeClass) var horizontalSizeClass
    //@Environment(\.screen) var screen
    
    var body: some View {
        
        GeometryReader { geometry in
            
            let isSplitView = geometry.size.width > 1024 && topicToEdit != nil
            
            if isSplitView {
                ContentViewIOS16Split(topicToEdit: $topicToEdit, appMode: $appMode, mainMenuAction: $mainMenuAction, selectedItems: $selectedItems, isSplitView: isSplitView)
            }
            else {
                makeCompactBody(isSplitView: false)
            }
        }
        .if(appMode == .choiceBoard) { view in
            view.mutePrompt(foregroundColor: Color.mfVeryBrightBlue, backgroundColor: Color.mfLightYellow)
        }
    }
    
    @ViewBuilder
    func makeCompactBody(isSplitView: Bool) -> some View {
        
        makeCompactBodyIOS16(isSplitView: isSplitView)
        //makeCompactBodyIOS16 doesn't work (navigation from topic is broken)
        //makeCompactBodyIOS16(isSplitView: isSplitView)
        //makeCompactBodyIOS14(isSplitView: isSplitView)
    }
    
    func makeCompactBodyIOS14(isSplitView: Bool) -> some View {
        NavigationView {
            makeNavigationBody(isSplitView: isSplitView)
        }
        .navigationViewStyle(.stack)
        .accentColor(.mfVeryBrightBlue)
        .environmentObject(currentTheme)
    }
    
    func makeCompactBodyIOS16(isSplitView: Bool) -> some View {
        NavigationStack(path: $navigationModel.path) {
            makeNavigationBody(isSplitView: isSplitView)
                .navigationDestination(for: PECSRepo.self) { topic in
                    MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode, action: $mainMenuAction, selectedItems: $selectedItems, isForSplitView: isSplitView)
                }
                .navigationDestination(for: MainMenuAction.self) { action in
                    navigationModel.makeDetailView(for: action, isForSplitView: isSplitView, appMode: $appMode)
                }
                //When the initial topic is loaded (from previous time in the app)
                //push it onto the navigation stack so we can go straight into editing.
                .onChange(of: topicToEdit) { newValue in
                    if let topic = newValue {
                        navigationModel.setTopic(topic)
                    }
                }
            
            
        }
        //.navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.mfVeryBrightBlue)
        .environmentObject(navigationModel)
    }
    
    func makeNavigationBody(isSplitView: Bool) -> some View {
        VStack(spacing: 0) {
            
            if errorHandler.lastError != nil {
                ErrorView(message: errorHandler.lastError!.localizedDescription, closeAction: {
                    withAnimation {
                        errorHandler.setLastError(nil) }
                })
            }
            
            TopicSelectionView(appMode: $appMode, mainMenuAction: $mainMenuAction, topicToEdit: $topicToEdit, selectedItems: $selectedItems, isForSplitView: isSplitView)
            //.frame(minWidth: 0, maxWidth: AppSettings.maxViewWidth)
                .environmentObject(repoFactory)
            
            /*
             MainMenuViewOrChoiceBoardView(topic: topic)
             //Maxwidth of 400 ensures that iPhone portrait button can be full width, which looks fine,
             //but it doesn't take up the full width on wider devices like iPad because that looks odd.
             .frame(minWidth: 0, maxWidth: AppSettings.maxViewWidth)
             */
        }
        
        .frame(maxWidth: .infinity)
        //.scrollContentHideBackground()
        
        //.background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
    }
    
    
}

//struct ContentView_Previews: PreviewProvider {
//
//    @State static var showRatingPrompt: Bool = false
//
//    static var previews: some View {
//        ContentView(showRatingPrompt: showRatingPrompt)
//        //ContentView(showRatingPrompt: .constant(false))
//    }
//}
//
//

