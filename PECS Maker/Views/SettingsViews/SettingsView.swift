//
//  SettingsView.swift
//  SwiftUI Settings Screen
//
//  Created by Rudrank Riyam on 18/04/20.
//  Copyright © 2020 Rudrank Riyam. All rights reserved.
//

import SwiftUI
import MessageUI
import LogFramework
import SharedSwiftUI
import SettingsFramework
import SettingsFrameworkWithRatings
import FeatureFramework
import RatingFramework

struct SettingsView: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    var isForSplitView: Bool
    var closeAction: (() -> Void)?
    
    init(settingsViewModel: SettingsViewModel, isForSplitView: Bool = false, closeAction: (() -> Void)? = nil) {
        self.settingsViewModel = settingsViewModel
        self.isForSplitView = isForSplitView
        self.closeAction = closeAction
    }
    
    var closeButtonIfNeeded: HeaderButton? {
        get {
            if closeAction != nil {
                
                return HeaderButton.closeButton(isForNativeToolbar: true, animateToMenuIcon: true, closeAction: {
                    self.closeAction?()
                })
            }
            else {
                return nil
            }
        }
    }
    
    
    var body: some View {
        if #available(iOS 16.0, *), isForSplitView {
            //In split view we need to embed in a NavigationStack, otherwise when we navigate to
            //the Credits view or Diagnostics view then we don't get a Back button.
            NavigationStack {
                stack
            }
        }
        else {
            stack
        }
        
    }
    
    var stack: some View {
        Form {
            //AboutView(title: "💜 the game? share!", accessibilityTitle: "Love the game? share!")
            
            ///Section that shows copyright info and acknowledgements.
            AboutCard(appName: settingsViewModel.appName, copyrightNotice: settingsViewModel.copyrightNotice, creditsView: AnyView(CreditsView().ignoresSafeArea()))
        
            ///Section that shows options to rate the app, write a review and send a feature request and report a bug.
            RateReportRequestCard(settingsViewModel: RatingViewModel(config: AppSettings.shared))
    
            ///Diagnostics view
            Section {
                SettingsRow2(imageName: "waveform.path.ecg", title: L10n.SettingsView.diagnosticsButton, hasChevron: false, destination: {
                    DiagnosticSettingsView(settingsViewModel: self.settingsViewModel, largeTitle: false)
                })
            }
            
            #if DEBUG
            ///Resets Feature voting so the user is prompted to vote again.
            if !featuresViewModel.showVotingPrompt {
                SettingsRow(imageName: "clear", title: L10n.SettingsView.resetVotingButton, hasChevron: false, action: {
                    featuresViewModel.resetVoting()
                })
            }
            #endif
            
        }
        .navigationBarTitle(L10n.SettingsPage.title, displayMode: .inline)
        .navigationBarItems(leading: closeButtonIfNeeded)
        //trailing: HeaderCloseButton( closeAction: self.closeAction )
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        //.scrollIndicators(.hidden)
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings.shared))
    }
}
