//
//  Settings.swift
//  SwiftUI Settings Screen
//
//  Created by Rudrank Riyam on 18/04/20.
//  Copyright © 2020 Rudrank Riyam. All rights reserved.
//

import Foundation
import LogFramework
import UIKit
import SwiftUI
import SharedSwiftUI

struct AppSettings : SettingsConfigProtocol, FeedbackSettings {

    private init() {}
    
    static var shared = AppSettings()
    
    //https://apps.apple.com/gb/app/easy-pecs-photo-layout/id1588581011
    var appURL = URL(string: "https://apps.apple.com/app/1588581011")!
    var appID =  "1588581011"
    
    //If you have your App Id then you can get your developer id like,
    //https://itunes.apple.com/lookup?id=YourAnyAppID
    //See: https://stackoverflow.com/questions/29696907/link-to-list-all-apps-by-a-developer-in-iphones-app-store
    var developerID = "1361494593" //Andrew Clynes developer


    //static var personalTwitterApp = "twitter://user?screen_name=rudrankriyam"
    //static var personalTwitterWeb = "https://www.twitter.com/rudrankriyam"
    //static var gameTwitterApp = "twitter://user?screen_name=gradientsgame"
    //static var gameTwitterWeb = "https://www.twitter.com/gradientsgame"
    let feedbackEmailAddress = "pecs.app@outlook.com"
    
    var featureRequestEmailSubject: String {
        get {
            let appName = AppInformation.appName
            let appVersion = AppInformation.appVersion ?? ""
            return "Feature request for \(appName) version \(appVersion)"
        }
    }
    
    var featureRequestEmailBody = "Got an idea to improve the app? - Please type it below...\n\n\n\n"

    var bugReportEmailSubject: String {
        get {
            let appName = AppInformation.appName
            let appVersion = AppInformation.appVersion ?? ""
            return "Bug report for \(appName) version \(appVersion)"
        }
    }
    
    var bugReportEmailBody: String {
        get {
            let systemInfo = AppInformation.deviceInfo
             return "Found a problem with the app? - Please describe it...\n\n\n\n\n\n\n\n\(systemInfo)"
        }
    }

    var sendLogsEmailSubject: String {
        get {
            let appName = AppInformation.appName
            let appVersion = AppInformation.appVersion ?? ""
            return "Log info for \(appName) version \(appVersion)"
        }
    }
    
    var sendLogsEmailBody: String {
        get {
            let messageBody = "Thank you for taking the time to provide feedback.\n\nThe content below is diagnostic information that will help with troubleshooting and improving the \(AppInformation.appName) app. No personal data will be sent.\n\n"
                
            var logInfo: String!
            logInfo = logger.getLatestLogs(maxSize: 1000000, reversed: true)
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
    
    var feedbackMessageNoEmail: String {
        "We welcome your feedback and bug reports. Please email them to:\n\(feedbackEmailAddress)"
    }

    
    static let maxViewWidth: CGFloat = 600
    static let maxButtonWidth: CGFloat = 300
    
    static let labelRowHeight: CGFloat = 50
    
    ///If a label is specified for the PECS card, this value determines how much of the card height it takes up.
    static let labelHeightPercent: CGFloat = 0.15
    
    static let pageColor = Color.white
    
    static let maxSelectionsInPhotoPicker = 150
    
    static var keepPDFs = false
    
    static var forceDarkMode = false
    static var forceLightMode = false

    static var autoFill = false
    static var autoFillSingle = false
    
    static var showTopicDebugInfo = false
    
    static var gridAddItemCellImageWidth: CGFloat {
        UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? 75 : 50
    }
    
    //When using a picker alone, we need to remember selections, but in
    //version where the picker hangs off a selections screen we want to
    //start out fresh each time.
    static var preselectPhotosInPicker: Bool = true
    
}
