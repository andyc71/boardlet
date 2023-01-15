//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine
import SharedSwiftUI

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
    @Environment(\.scenePhase)var scenePhase: ScenePhase
    static let productUserActivityType = "com.brightblue.EasyPECS.PageLayoutState"
    
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    @StateObject var errorHandler = ErrorHandler.shared
    
    @Binding var topicToEdit: PECSRepo?
    @State var mainMenuAction: MainMenuAction?
    
    //@SceneStorage("ContentView.currentTopic") private var currentTopic: String?
    
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
        
        /*
         //MARK: App Restoration
         .onContinueUserActivity(ContentView.productUserActivityType) { userActivity in
         //if let pageLayoutState = try? userActivity.typedPayload(PageLayoutState.self) {
         if let pageLayoutState = try? userActivity.typedPayload(PageLayoutState.self) {
         self.pageLayoutState = pageLayoutState
         }
         }
         */
        //        .onChange(of: scenePhase) { newScenePhase in
        //            if newScenePhase == .background {
        //                // Make sure to save any unsaved changes to the products model.
        //                pageLayoutState.save()
        //            }
        //        }
        
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
