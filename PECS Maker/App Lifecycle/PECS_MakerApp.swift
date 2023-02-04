//
//  PECS_MakerApp.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
//import SharedUI
import Firebase
import FirebaseAnalytics
import LogFramework
import Combine
import SharedSwiftUI

@main
struct PECS_MakerApp: App {
    
    @State private var showRatingPrompt: Bool = false
    
    private var cancellable: AnyCancellable?
    
    init() {
        
        setupAnalytics()
        
        setupRatingHelper()
        
        processArguments()
        
        //Set up the default nav bar which will be used by all the child pages.
        //For the main page page, we will hide the default nav bar and display our own title.
        NavigationBar.configure()
        //UINavigationBar.mfSetup(outlineText: true)
        setupTheme()
        
        logger.isDetailedLoggingEnabled = UserDefaultsConfig.shared.isDebugLoggingEnabled
        
        cancellable = UserDefaultsConfig.shared.objectWillChange.sink {
            logger.isDetailedLoggingEnabled = UserDefaultsConfig.shared.isDebugLoggingEnabled
        }
        

    }
    

    @StateObject var ratingStateMachine: RatingStateMachine2 = RatingStateMachine2()

    @StateObject var repoFactory = PECSRepoFactory.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView(topicToEdit: $repoFactory.publishedCurrentTopic)
                .ratingAlert(state: $ratingStateMachine.ratingState, feedbackSettings: AppSettings.shared)
                .environmentObject(ratingStateMachine)
                .if(AppSettings.forceDarkMode) { view in
                        view.preferredColorScheme(.dark)
                }
                .if(AppSettings.forceLightMode) { view in
                        view.preferredColorScheme(.light)
                }
        }
        
    }
    
    func setupTheme() {
        currentTheme.headerStyle.fontName = Theme.headerFontName
    }
    
    func setupAnalytics() {
        
        if CommandLine.arguments.contains(LaunchArguments.noAnalytics) {
            return
        }
        
        MFAnalytics.setup()
    }
    
    func setupRatingHelper() {
        
        if CommandLine.arguments.contains(LaunchArguments.noRatings) {
            return
        }
        
        #if DEBUG
        RatingHelper.reset()
        #endif

        RatingHelper.setup()
        RatingHelper.minimumReviewWorthyActionCount = 1
    }
    
    func processArguments() {
        if CommandLine.arguments.contains(LaunchArguments.keepPDFs) {
            AppSettings.keepPDFs = true
        }
        if CommandLine.arguments.contains(LaunchArguments.darkMode) {
            AppSettings.forceDarkMode = true
        }
        if CommandLine.arguments.contains(LaunchArguments.lightMode) {
            AppSettings.forceLightMode = true
        }
        if CommandLine.arguments.contains(LaunchArguments.autoFill) {
            AppSettings.autoFill = true
        }
    }

    
    
}
