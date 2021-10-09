//
//  PECS_MakerApp.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedUI
import Firebase
import FirebaseAnalytics
import LogFramework
import Combine

@main
struct PECS_MakerApp: App {
    
    @State private var showRatingPrompt: Bool = false
    
    private var cancellable: AnyCancellable?
    
    init() {
        setupAnalytics()
        
        //Set up the default nav bar which will be used by all the child pages.
        //For the main page page, we will hide the default nav bar and display our own title.
        NavigationBar.configure()
        
        logger.isDetailedLoggingEnabled = UserDefaultsConfig.shared.isDebugLoggingEnabled
        
        cancellable = UserDefaultsConfig.shared.objectWillChange.sink {
            logger.isDetailedLoggingEnabled = UserDefaultsConfig.shared.isDebugLoggingEnabled
        }
        

    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
    }
    
    func setupAnalytics() {
        
        if CommandLine.arguments.contains(LaunchArguments.noAnalytics) {
            return
        }
        
        MFAnalytics.setup()
    }
    
    
    
}
