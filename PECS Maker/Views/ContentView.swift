//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine
import SharedSwiftUI

struct ContentView: View {
    
    //MARK: App Restoration
    @Environment(\.scenePhase)var scenePhase: ScenePhase
    static let productUserActivityType = "com.brightblue.EasyPECS.PageLayoutState"


    //    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    //    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @StateObject var pageLayoutState = PageLayoutState()
    
    @SceneStorage("ContentView.currentTopic") private var currentTopic: String?
    
    var body: some View {
        NavigationView {
            //ConditionalStack(verticalAlignment: .top, /*isHorizonalStack: pageLayoutState.orientation == .landscape*/ isHorizonalStack: false) {
            ScrollView {
                VStack(spacing: 0) {
                    
                    //MessageView(heading: "Done", subheading: "Save/Print Complete", animation: MicroAnimations.tickAnimation)
                    
                    //Create our own psuedo nav bar header. We're doing this beacuse it's hard
                    //to get the right padding with the default nav bar.
                    Text("Easy PECS")
                    //.font(.largeTitle)
                        .font(Theme.headerFontHomePage)
                        .foregroundColor(Color(Theme.headerTextColor))
                    //.padding()
                    
                    if pageLayoutState.lastError != nil {
                        ErrorView(message: pageLayoutState.lastError!.localizedDescription, closeAction: {
                            withAnimation {
                                pageLayoutState.lastError = nil }
                        })
                    }
                    
                    MainMenuView(pageLayoutState: pageLayoutState)
                    //Maxwidth of 400 ensures that iPhone portrait button can be full width, which looks fine,
                    //but it doesn't take up the full width on wider devices like iPad because that looks odd.
                        .frame(minWidth: 0, maxWidth: AppSettings.maxViewWidth)
                }
                
            }
            .padding()
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity)
            .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))

        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        /*
        //MARK: App Restoration
        .onContinueUserActivity(ContentView.productUserActivityType) { userActivity in
            //if let pageLayoutState = try? userActivity.typedPayload(PageLayoutState.self) {
            if let pageLayoutState = try? userActivity.typedPayload(PageLayoutState.self) {
                self.pageLayoutState = pageLayoutState
            }
        }
         */
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .background {
                // Make sure to save any unsaved changes to the products model.
                pageLayoutState.save()
            }
        }
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
