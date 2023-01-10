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

var topicSelected: Bool = false

struct ContentView: View {
    
    //MARK: App Restoration
    @Environment(\.scenePhase)var scenePhase: ScenePhase
    static let productUserActivityType = "com.brightblue.EasyPECS.PageLayoutState"
    
    
    //    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    //    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    //@StateObject var pageLayoutState = PageLayoutState()
    @StateObject var errorHandler = ErrorHandler.shared
    
    @Binding var topicToEdit: PECSRepo?
    @State var mainMenuAction: MainMenuAction?
    
    //@SceneStorage("ContentView.currentTopic") private var currentTopic: String?
    
    //@State var ratingState = RatingState.hidden
    //@StateObject var ratingStateMachine: RatingStateMachine2 = RatingStateMachine2()
    //@EnvironmentObject var ratingStateMachine: RatingStateMachine2
    
    //@Environment(\.ratingState) var ratingState: RatingStateMachine
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.screen) var screen
    
    var isSplitView: Bool {
        horizontalSizeClass != .compact && screen.width >= 1024
        
    }
        
    var body: some View {
        
        Group {
            if isSplitView {
                if #available(iOS 16.0, *) {
                    ContentViewIOS16(topicToEdit: $topicToEdit)
                }
                else {
                    compactBody

                    //Removing Split view support for IOS14 because it
                    //behaves differently than on IOS16 (e.g. has a back
                    //button instead of a Show/Hide navigation panel)
                    //and it gives us a whole different code path to test
                    //and a lot of different tests to run/maintain on
                    //another IOS version.
                    
                    /*
                    if topicToEdit == nil {
                        NavigationView {
                            navigationBody
                        }
                        .navigationViewStyle(.stack)
                    }
                    else {
                        splitViewBodyIOS14
                    }*/
                    
                }
            }
            else {
                compactBody
            }
        }
        .onChange(of: topicToEdit) { newValue in
            topicSelected = newValue != nil
        }
    }
    
    @State private var path: [PECSRepo] = []
    
    @available(iOS 16.0, *)
    var ios16body : some View {
        NavigationStack(path: $path){
            //Master view
            navigationBody
        }
    }
    
    @ViewBuilder
    var ios14content: some View {
        if let topic = topicToEdit {
            MainMenuView(topic: topic, action: $mainMenuAction, isForSplitView: isSplitView)
        }
        else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    var splitViewBodyIOS14 : some View {
        
        NavigationView {
            //Sidebar view
            navigationBody
            
            ios14content

            //Third column will get replaced by MainMenu view
            //pushing the destination of a NavigationLink
            EmptyView()
            
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .accentColor(.mfVeryBrightBlue)
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
    
    @available(iOS 16.0, *)
    var compactBodyIOS16 : some View {
        NavigationStack(path: $path) {
            navigationBody
        }
        .accentColor(.mfVeryBrightBlue)
    }
    
    var compactBodyIOS14 : some View {
        NavigationView {
            navigationBody
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.mfVeryBrightBlue)
    }

    
    @ViewBuilder
    var compactBody : some View {
        
        if #available(iOS 16.0, *) {
            //compactBodyIOS16
            compactBodyIOS14
        }
        else {
            compactBodyIOS14
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
    
    var navigationBody : some View {
        //ZStack {
            //Color(currentTheme.backgroundColor).ignoresSafeArea()
            
            //ConditionalStack(verticalAlignment: .top, /*isHorizonalStack: pageLayoutState.orientation == .landscape*/ isHorizonalStack: false) {
            ScrollView {
                VStack(spacing: 0) {
                    
                    //MessageView(heading: "Done", subheading: "Save/Print Complete", animation: MicroAnimations.tickAnimation)
                    
                    //Create our own psuedo nav bar header. We're doing this beacuse it's hard
                    //to get the right padding with the default nav bar.
                    //                        Text("Easy PECS")
                    //                        //.font(.largeTitle)
                    //                            .font(Theme.headerFontHomePage)
                    //                            .foregroundColor(Color(Theme.headerTextColor))
                    //.padding()
                    
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
                
            }
            
            //.padding()
            //.navigationBarHidden(true)
            .frame(maxWidth: .infinity)
            .scrollContentHideBackground()
            
            .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        //}
        
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
