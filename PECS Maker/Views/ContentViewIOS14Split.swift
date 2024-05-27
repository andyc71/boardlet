//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine
import SharedSwiftUI

var topicSelected: Bool = false

struct ContentViewIOS14Split: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    @StateObject var errorHandler = ErrorHandler.shared
    
    @Binding var topicToEdit: PECSRepo?
    @Binding var appMode: PECSAppMode
    @State var mainMenuAction: MainMenuAction?
    
    var isSplitView: Bool
    
    var body: some View {
        
        Group {
            if isSplitView {
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
            else {
                compactBody
            }
        }
        .onChange(of: topicToEdit) { newValue in
            topicSelected = newValue != nil
        }
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
    }
    
    var compactBodyIOS14 : some View {
        NavigationView {
            navigationBody
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.mfVeryBrightBlue)
    }
    
    @ViewBuilder
    var ios14content: some View {
        if let topic = topicToEdit {
            MainMenuViewOrChoiceBoardView(topic: topic, appMode: $appMode, action: $mainMenuAction, isForSplitView: isSplitView)
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
    }
    
    var navigationBody : some View {
        ScrollView {
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
            
        }
        
        .frame(maxWidth: .infinity)
        .scrollContentHideBackground()
        
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
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
