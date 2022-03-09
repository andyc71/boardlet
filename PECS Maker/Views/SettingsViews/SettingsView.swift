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

struct SettingsView: View {
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var closeAction: (() -> Void)?
    
    init(settingsViewModel: SettingsViewModel, closeAction: (() -> Void)? = nil) {
        self.settingsViewModel = settingsViewModel
        self.closeAction = closeAction
        MFAnalytics.logScreenView(screenName: "Settings")
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
            
            AboutCard(copyrightNotice: settingsViewModel.copyrightNotice, creditsView: AnyView(CreditsView().ignoresSafeArea()))
                .padding()
            
            RateReportRequestCard(settingsViewModel: self.settingsViewModel)
                .padding()


             SimpleCard {
                 SettingsRow2(imageName: "waveform.path.ecg", title: "Diagnostics", destination: {
                     DiagnosticSettingsView(settingsViewModel: self.settingsViewModel)
                         .background(Theme.backgroundColor)
                         .ignoresSafeArea()
                 })
             }
             .padding()

            Spacer()

        }
        .navigationBarTitle("Settings", displayMode: .inline)
        
        
        .navigationBarItems(leading: closeButtonIfNeeded)
        //trailing: HeaderCloseButton( closeAction: self.closeAction )
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))
        //}
        //.navigationViewStyle(StackNavigationViewStyle())
    }

}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings()))
    }
}
