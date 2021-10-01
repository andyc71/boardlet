//
//  Settings.swift
//  SwiftUI Settings Screen
//
//  Created by Rudrank Riyam on 18/04/20.
//  Copyright © 2020 Rudrank Riyam. All rights reserved.
//

import Foundation
import LogFramework

struct Settings {
    static var appURL = URL(string: "https://apps.apple.com/app/1531165063")!
    static var appID =  "1531165063"

    //static var personalTwitterApp = "twitter://user?screen_name=rudrankriyam"
    //static var personalTwitterWeb = "https://www.twitter.com/rudrankriyam"
    //static var gameTwitterApp = "twitter://user?screen_name=gradientsgame"
    //static var gameTwitterWeb = "https://www.twitter.com/gradientsgame"
    static let email = "music.wizard@outlook.com"
    
    static var featureRequestEmailSubject: String {
        get {
            let appName = AppInformation.appName ?? ""
            let appVersion = AppInformation.appVersion ?? ""
            return "Feature request for \(appName) version \(appVersion)"
        }
    }
    
    static var featureRequestEmailBody = "Got an idea to improve the app? - Please type it below...\n\n\n\n"

    static var bugReportEmailSubject: String {
        get {
            let appName = AppInformation.appName ?? ""
            let appVersion = AppInformation.appVersion ?? ""
            return "Bug report for \(appName) version \(appVersion)"
        }
    }
    
    static var bugReportEmailBody: String {
        get {
            let systemInfo = AppInformation.deviceInfo
             return "Found a problem with the app? - Please describe it...\n\n\n\n\n\n\n\n\(systemInfo)"
        }
    }

    static var sendLogsEmailSubject: String {
        get {
            let appName = AppInformation.appName ?? ""
            let appVersion = AppInformation.appVersion ?? ""
            return "Log info for \(appName) version \(appVersion)"
        }
    }
    
    static var sendLogsEmailBody: String {
        get {
            let messageBody = "Thank you for taking the time to provide feedback.\n\nThe content below is diagnostic information that will help with troubleshooting and improving the \(AppInformation.appName ?? "") app. No personal data will be sent.\n\n"
                
            var logInfo: String!
            logInfo = logger.getLatestLogs(maxSize: 1000000)
            if logInfo == nil {
                if logger.isDetailedLoggingEnabled {
                    logInfo = "Detailed logging is on, but no log information is available."
                }
                else {
                    logInfo = "Detailed logging is off, and no log information is available."
                }
            }
            
            let deviceInfo = AppInformation.deviceInfo
            
            let fullMessageBody = messageBody +
                "Device Info:\n" + deviceInfo + "\n" +
                "Log Info: \n" + logInfo
            
            return fullMessageBody
        }
    }


}
