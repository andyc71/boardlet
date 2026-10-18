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
    
    
    var body: some View { stack }

    var stack: some View {
        Form {
            //AboutView(title: "💜 the game? share!", accessibilityTitle: "Love the game? share!")
            
            ///Section that shows copyright info and acknowledgements.
            Section {
                VStack {
                    AppNameRow(appName: settingsViewModel.appName)
                    CopyrightRow(text: settingsViewModel.copyrightNotice)
                }
                AppVersionRow(imageName: "info.circle", title: L10nSSUI.AboutCard.versionLabel,
                              version: settingsViewModel.appVersion)
                    .accessibilityIdentifier("Settings.AboutCard.appVersion")
                NavigationLink(value: AppRoute.credits) {
                    Label(L10nSSUI.AboutCard.acknowledgementsButton, systemImage: "hands.clap")
                }
                .accessibilityIdentifier("Settings.AboutCard.creditsButton")
            }
            
            ///Section that allows the user to switch between the old UI and the new one.
            InterfaceStyleSection()
        
            ///Section that shows options to rate the app, write a review and send a feature request and report a bug.
            RateReportRequestCard(settingsViewModel: RatingViewModel(config: AppSettings.shared))
    
            ///Diagnostics view
            Section {
                NavigationLink(value: AppRoute.diagnostics) {
                    Label(L10n.SettingsView.diagnosticsButton, systemImage: "waveform.path.ecg")
                }
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
