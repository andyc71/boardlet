//
//  SettingsView.swift
//  SwiftUI Settings Screen
//
//  Created by Rudrank Riyam on 18/04/20.
//  Copyright © 2020 Rudrank Riyam. All rights reserved.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var closeAction: (() -> Void)?
    
    init(settingsViewModel: SettingsViewModel, closeAction: (() -> Void)? = nil) {
        self.settingsViewModel = settingsViewModel
        self.closeAction = closeAction
    }
    
    var closeButtonIfNeeded: HeaderButton? {
        get {
            if closeAction != nil {
                
                return HeaderButton.closeButton(animateToMenuIcon: true, closeAction: {
                    self.closeAction?()
                })
            }
            else {
                return nil
            }
        }
    }
    
    


    
    var body: some View {
        
        VStack {
            //AboutView(title: "💜 the game? share!", accessibilityTitle: "Love the game? share!")
            
            SimpleCard {
                CopyrightRow(text: settingsViewModel.copyrightNotice)
                
                // MARK: - APP VERSION
                AppVersionRow(imageName: "info.circle", title: "App version", version: AppInformation.appVersion ?? "")
                
                // MARK: - CREDITS
                SettingsRow2(imageName: "hand.thumbsup", title: "Acknowledgements", destination: {
                    CreditsView()
                })
                
            }
            //.cardStyle(MyRoundedRectangleCardStyle())
            .padding()

            SimpleCard {
                // MARK: - RATE APP
                SettingsRow(imageName: "star", title: "Rate this app") {
                    self.settingsViewModel.rateApp()
                }
                
                // MARK: - FEATURE REQUEST
                SettingsRow(imageName: "envelope", title: "Feature request") {
                    if MFMailComposeViewController.canSendMail() {
                        self.settingsViewModel.showingFeatureEmail.toggle()
                    } else if let emailUrl = self.settingsViewModel.createEmailUrl(to: Settings.email, subject: "Feature request!", body: "Hello, I have this idea ") {
                        UIApplication.shared.open(emailUrl)
                    } else {
                        self.settingsViewModel.showMailFeatureAlert = true
                    }
                }
                .alert(isPresented: $settingsViewModel.showMailFeatureAlert) {
                    Alert(title: Text("No Mail Accounts"), message: Text("Please set up a Mail account in order to send email"), dismissButton: .default(Text("OK")))
                }
                .sheet(isPresented: $settingsViewModel.showingFeatureEmail) {
                    MailView(isShowing: self.$settingsViewModel.showingFeatureEmail, result: self.$settingsViewModel.featureResult, subject: Settings.featureRequestEmailSubject, message: Settings.featureRequestEmailBody)
                }
                
                // MARK: - REPORT A BUG
                SettingsRow(imageName: "ant", title: "Report a problem") {
                    if MFMailComposeViewController.canSendMail() {
                        self.settingsViewModel.showingBugEmail.toggle()
                    } else if let emailUrl = self.settingsViewModel.createEmailUrl(to: Settings.email, subject: Settings.bugReportEmailSubject, body: Settings.bugReportEmailBody) {
                        UIApplication.shared.open(emailUrl)
                    } else {
                        self.settingsViewModel.showMailBugAlert = true
                    }
                }
                .alert(isPresented: self.$settingsViewModel.showMailBugAlert) {
                    Alert(title: Text("No Mail Accounts"), message: Text("Please set up a Mail account in order to send email"), dismissButton: .default(Text("OK")))
                }
                .sheet(isPresented: $settingsViewModel.showingBugEmail) {
                    MailView(isShowing: self.$settingsViewModel.showingBugEmail, result: self.$settingsViewModel.bugResult, subject: Settings.bugReportEmailSubject, message: Settings.bugReportEmailBody)
                }
            }
            //.background(SettingsTheme.groupBackground)
            .padding()
            
             SimpleCard {
                 
                 SettingsRow2(imageName: "waveform.path.ecg", title: "Diagnostics", destination: {
                     DiagnosticSettingsView()
                 })
                 
             }
             .padding()
             //.settingsBackground()
            
            //AboutView(title: "MADE WITH ❤️ BY RUDRANK RIYAM", accessibilityTitle: "MADE WITH LOVE BY RUDRANK RIYAM")
            
            Spacer()

        }
        .navigationBarTitle(Text(AppInformation.appName!), displayMode: .inline)
        
        
        .navigationBarItems(leading: closeButtonIfNeeded)
        //trailing: HeaderCloseButton( closeAction: self.closeAction )
        
        .padding()
        .background {
            Theme.backgroundColor
        }

        //}
        //.navigationViewStyle(StackNavigationViewStyle())
    }

}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settingsViewModel: SettingsViewModel())
    }
}
