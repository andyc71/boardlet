//
//  DiagnosticSettingsView.swift
//  MyMusic
//
//  Created by Andy on 12/12/2020.
//  Copyright © 2020 Andrew Clynes. All rights reserved.
//

import SwiftUI
import MessageUI

struct DiagnosticSettingsView: View {
    
    @StateObject var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        
        VStack {
            
            SimpleCard {
                // MARK: - SEND LOGS
                SettingsRow(imageName: "doc.text", title: "Send diagnostic logs") {
                    if MFMailComposeViewController.canSendMail() {
                        self.settingsViewModel.showingLogEmail.toggle()
                    } else if let emailUrl = self.settingsViewModel.createEmailUrl(to: AppSettings.emailAddress, subject: AppSettings.sendLogsEmailSubject, body: AppSettings.sendLogsEmailBody) {
                        UIApplication.shared.open(emailUrl)
                    } else {
                        self.settingsViewModel.showMailLogAlert = true
                    }
                }
                .alert(isPresented: self.$settingsViewModel.showMailLogAlert) {
                    Alert(title: Text("No Mail Accounts"), message: Text("Please set up a Mail account in order to send email"), dismissButton: .default(Text("OK")))
                }
                .sheet(isPresented: $settingsViewModel.showingLogEmail) {
                    MailView(isShowing: self.$settingsViewModel.showingLogEmail, result: self.$settingsViewModel.logResult, subject: AppSettings.sendLogsEmailSubject, message: AppSettings.sendLogsEmailBody, recipientEmail: AppSettings.emailAddress)
                }
            
                // MARK: - DELETE LOGS
                SettingsRow(imageName: "rectangle.stack.badge.minus", title: "Delete Logs", hasChevron: false) {
                    self.settingsViewModel.showAlertForDeleteDiagnosticLogs = true
                    self.settingsViewModel.alertTypeForDeleteDiagnosticsLogs = .confirm
                }
                .alert(isPresented: self.$settingsViewModel.showAlertForDeleteDiagnosticLogs) {
                    
                    if self.settingsViewModel.alertTypeForDeleteDiagnosticsLogs == .confirm {
                        
                        return Alert(title: Text("Delete Diagnostic Logs"), message: Text("Are you sure you want to delete the diagnostic logs?"), primaryButton: .destructive(Text("Delete")) {
                            self.settingsViewModel.deleteDiagnosticLogs()
                            DispatchQueue.main.async {
                                self.settingsViewModel.showAlertForDeleteDiagnosticLogs = true
                                self.settingsViewModel.alertTypeForDeleteDiagnosticsLogs = .complete
                            }
                        }, secondaryButton: .cancel() {
                            self.settingsViewModel.showAlertForDeleteDiagnosticLogs = false
                            self.settingsViewModel.alertTypeForDeleteDiagnosticsLogs = .none
                        })
                    }
                    else {
                        return Alert(title: Text("Logs Deleted"), message: Text("Diagnostic logs successfully deleted"), dismissButton: .default(Text("OK")) {
                            self.settingsViewModel.showAlertForDeleteDiagnosticLogs = false
                            self.settingsViewModel.alertTypeForDeleteDiagnosticsLogs = .none
                        })
                    }
                }
            }
            .padding()
            
            Spacer()
            
        }
        .navigationBarTitle(Text("Diagnostic Settings"), displayMode: .inline)
        .padding()
        .background {
            Theme.backgroundColor
            
            
        }
        
    }
}
    
