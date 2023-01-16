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

@MainActor
class ErrorHandler: ObservableObject {
    @Published private(set) var lastError: Error?
    
    static var shared = ErrorHandler()
    
    @MainActor
    func setLastError(_ error: Error?) {
        //DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        DispatchQueue.main.async {
            self.lastError = error
        }
    }
    
    private init() {
        
    }
}

struct ContentView: View {
    
    //MARK: App Restoration
    //All of this is now handled by the topic which has a menuMenu field to determine
    //which page should be displayed.
    //@Environment(\.scenePhase)var scenePhase: ScenePhase
    //static let productUserActivityType = "com.brightblue.EasyPECS.PageLayoutState"
    //Don't want to persist mainMenuAction as SceneStorage because it will get
    //restored automatically, and we only want to restore it if the topic hasn't
    //changed (otherwise we should go to the default screen.
    //@SceneStorage(PECSStateRestoration.activityKey) private var sceneState = PECSStateRestoration()
    
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    @StateObject var errorHandler = ErrorHandler.shared
    
    @Binding var topicToEdit: PECSRepo?
    @State var mainMenuAction: MainMenuAction?
    

    //@State var ratingState = RatingState.hidden
    //@StateObject var ratingStateMachine: RatingStateMachine2 = RatingStateMachine2()
    //@EnvironmentObject var ratingStateMachine: RatingStateMachine2
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.screen) var screen
    
    var isIOS16 : Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        else {
            return false
        }
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            
            let isSplitView = isIOS16 && geometry.size.width > 1024 && topicToEdit != nil
            
            if isSplitView {
                if #available(iOS 16.0, *) {
                    ContentViewIOS16Split(topicToEdit: $topicToEdit, isSplitView: isSplitView)
                }
                else {
                    //Removing Split view support for IOS14 because it
                    //behaves differently than on IOS16 (e.g. has a back
                    //button instead of a Show/Hide navigation panel)
                    //and it gives us a whole different code path to test
                    //and a lot of different tests to run/maintain on
                    //another IOS version.
                    
                    /*
                     ContentViewIOS14Split(topicToEdit: $topicToEdit, isSplitView: isSplitView))
                     }*/

                    makeCompactBody(isSplitView: false)

                }
            }
            else {
                makeCompactBody(isSplitView: false)
            }
        }
        /*
        //MARK: App Restoration
        .onContinueUserActivity(PECSStateRestoration.activityKey) { userActivity in

            do {
                let state = try userActivity.typedPayload(PECSStateRestoration.self)
                guard self.topicToEdit?.topicName == state.topicName else { return }
                mainMenuAction = state.mainMenuAction
            }
            catch {
                logger.logError(.background, "Unable to restore application state", error)
                return
            }
        }
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .background {
                //guard let sceneState = self.sceneState else { return }
                self.sceneState = PECSStateRestoration(topicName: topicToEdit?.topicName, mainMenuAction: mainMenuAction)
            }
            else if newScenePhase == .active {
                //guard let sceneState = self.sceneState else { return }
                guard self.topicToEdit?.topicName == sceneState.topicName else { return }
                self.mainMenuAction = sceneState.mainMenuAction
            }
        }
         */
    }
    
    @ViewBuilder
    func makeCompactBody(isSplitView: Bool) -> some View {
        
        if #available(iOS 16.0, *) {
            //compactBodyIOS16
            makeCompactBodyIOS14(isSplitView: isSplitView)
        }
        else {
            makeCompactBodyIOS14(isSplitView: isSplitView)
        }
    }
    
    func makeCompactBodyIOS14(isSplitView: Bool) -> some View {
        NavigationView {
            makeNavigationBody(isSplitView: isSplitView)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.mfVeryBrightBlue)
    }
    
    func makeNavigationBody(isSplitView: Bool) -> some View {
        VStack(spacing: 0) {
            
            if errorHandler.lastError != nil {
                ErrorView(message: errorHandler.lastError!.localizedDescription, closeAction: {
                    withAnimation {
                        errorHandler.setLastError(nil) }
                })
            }
            
            TopicSelectionView(mainMenuAction: $mainMenuAction, topicToEdit: $topicToEdit, isForSplitView: isSplitView)
            //.frame(minWidth: 0, maxWidth: AppSettings.maxViewWidth)
                .environmentObject(repoFactory)
            
            /*
             MainMenuView(topic: topic)
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


//If no topic is selected, we need to force the topic selection pane
//to be displayed. Otherwise, we can let UIKit to automatically figure
//out whether to display it.
extension UISplitViewController {
    /*
    open override func viewWillLayoutSubviews() {

        var displayMode = UISplitViewController.DisplayMode.automatic
//        if topicSelected {
//            displayMode = .secondaryOnly
//        }
//        else {
//            displayMode = .twoBesideSecondary
//        }
//        displayMode = .secondaryOnly
        
        let displayMode =  UISplitViewController.DisplayMode.oneBesideSecondary
        //let displayMode =  UISplitViewController.DisplayMode.oneOverSecondary
        
        if preferredDisplayMode != displayMode {
            DispatchQueue.main.async {
                self.preferredDisplayMode = displayMode
            }
        }

    }
     */
        
}
