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
    var isForSplitView: Bool
    var closeAction: (() -> Void)?
    
    init(settingsViewModel: SettingsViewModel, isForSplitView: Bool = false, closeAction: (() -> Void)? = nil) {
        self.settingsViewModel = settingsViewModel
        self.isForSplitView = isForSplitView
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
        VStack {
            //AboutView(title: "💜 the game? share!", accessibilityTitle: "Love the game? share!")
            
            AboutCard(copyrightNotice: settingsViewModel.copyrightNotice, creditsView: AnyView(CreditsView().ignoresSafeArea()))
                .padding()
            
            RateReportRequestCard(settingsViewModel: self.settingsViewModel)
                .padding()
            
            
            /*
            SimpleCard {
                SettingsRow2(imageName: "gearshape.2", title: "Advanced Settings", destination: {
                        AdvancedSettingsView()
                })
                //.accessibilityIdentifier(A12SSUI.SettingsScreen.AboutCard.creditsButton)

            }
            .padding()
             */
            
            SimpleCard {
                SettingsRow2(imageName: "waveform.path.ecg", title: L10n.SettingsView.diagnosticsButton, destination: {
                    DiagnosticSettingsView(settingsViewModel: self.settingsViewModel)
                        .maxWidth(AppSettings.maxViewWidth)
                        .padding()
                        .maxWidth(.infinity)
                        .background(Color(currentTheme.backgroundColor))
                        .ignoresSafeArea()
                })
            }
            .padding()
            
            Spacer()
            
        }
        .navigationBarTitle(L10n.SettingsPage.title, displayMode: .inline)
        
        
        .navigationBarItems(leading: closeButtonIfNeeded)
        //trailing: HeaderCloseButton( closeAction: self.closeAction )
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        
        
        //.navigationViewStyle(StackNavigationViewStyle())
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settingsViewModel: SettingsViewModel(config: AppSettings.shared))
    }
}
