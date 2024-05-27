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
    
    @EnvironmentObject var currentTheme: SharedUITheme

    @StateObject var repoFactory = PECSRepoFactory.shared
    @StateObject var errorHandler = ErrorHandler.shared
    
    @Binding var topicToEdit: PECSRepo?
    
    @AppStorage("appMode2")
    var appMode: PECSAppMode = .pecsMaker
    
    @State var mainMenuAction: MainMenuAction?
    
    
    //@Environment(\.horizontalSizeClass) var horizontalSizeClass
    //@Environment(\.screen) var screen
    
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
                    ContentViewIOS16Split(topicToEdit: $topicToEdit, appMode: $appMode, isSplitView: isSplitView)
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
            //makeCompactBodyIOS16 doesn't work (navigation from topic is broken)
            //makeCompactBodyIOS16(isSplitView: isSplitView)
        }
        else {
            makeCompactBodyIOS14(isSplitView: isSplitView)
        }
    }
    
    func makeCompactBodyIOS14(isSplitView: Bool) -> some View {
        NavigationView {
            makeNavigationBody(isSplitView: isSplitView)
        }
        .navigationViewStyle(.stack)
        .accentColor(.mfVeryBrightBlue)
        .environmentObject(currentTheme)
    }
    
    @available(iOS 16.0, *)
    func makeCompactBodyIOS16(isSplitView: Bool) -> some View {
        NavigationStack {
            makeNavigationBody(isSplitView: isSplitView)
        }
        //.navigationViewStyle(StackNavigationViewStyle())
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
            
            TopicSelectionView(appMode: $appMode, mainMenuAction: $mainMenuAction, topicToEdit: $topicToEdit, isForSplitView: isSplitView)
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

