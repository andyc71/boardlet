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
import MailFramework
import EngagementKit

struct SettingsView: View {
    
    @EnvironmentObject private var engagement: EngagementCoordinator
    @Environment(\.openURL) private var openURL
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
            DefaultBoardsSection()
            Section {
                Button {
                    StartupExperience().requestWelcome()
                } label: {
                    Label(L10n.Welcome.showAgain, systemImage: "hand.wave")
                }
                .accessibilityIdentifier("Settings.showWelcome")
            }
        
            ///Section that shows options to rate the app, write a review and send a feature request and report a bug.
            Section {
                Button {
                    engagement.recordUserInitiatedInteraction()
                    if let url = ReviewRequest.writeReviewURL(appURL: AppSettings.shared.appURL) { openURL(url) }
                } label: {
                    Label(L10nSettings.RateReportRequestCard.writeReviewButton, systemImage: "star")
                }
                Button {
                    featuresViewModel.openVoting()
                } label: {
                    Label(LocalizedFeatureStrings.invitationTitle, systemImage: "hand.thumbsup")
                }
                .accessibilityIdentifier("Settings.voteForFeatures")
                if Mail.canSendMail {
                    Button(L10nSettings.RateReportRequestCard.featureRequestButton) {
                        engagement.recordUserInitiatedInteraction()
                        settingsViewModel.showingFeatureEmail = true
                    }
                    .emailComposer(emailData: $settingsViewModel.mailItemFeatureRequest, onDismiss: { _ in
                        settingsViewModel.showingFeatureEmail = false
                    })
                    Button(L10nSettings.RateReportRequestCard.reportProblemButton) {
                        engagement.recordUserInitiatedInteraction()
                        settingsViewModel.showingBugEmail = true
                    }
                    .emailComposer(emailData: $settingsViewModel.mailItemReportBug, onDismiss: { _ in
                        settingsViewModel.showingBugEmail = false
                    })
                } else {
                    SettingsRowMultiline(imageName: "envelope", title: settingsViewModel.feedbackMessageNoEmail)
                }
            }
    
            ///Diagnostics view
            Section {
                NavigationLink(value: AppRoute.diagnostics) {
                    Label(L10n.SettingsView.diagnosticsButton, systemImage: "waveform.path.ecg")
                }
            }
            

            
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
