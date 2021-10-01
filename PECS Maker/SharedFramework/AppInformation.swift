//
//  AppInformation.swift
//  SharedUI
//
//  Created by Andy on 10/09/2020.
//  Copyright © 2020 Andrew Clynes. All rights reserved.
//

import UIKit
import LogFramework

public class AppInformation {
    
    public static var appName: String? {
        get {
            guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
                logger.logError(.general, "Unable to retrieve App Name")
                return nil
            }
            return appName
        }
    }
    
    public static var appVersion: String? {
        get {
            guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                logger.logError(LogCategory.general, "Unable to get app version number")
                return nil
            }
            guard let buildNo = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
                logger.logError(LogCategory.general, "Unable to get build number")
                return nil
            }
            return "\(version) (Build: \(buildNo))"
        }
    }
    
    public static var deviceInfo: String {
        get {
            let sysVersion = UIDevice.current.systemVersion
            let model = UIDevice.modelName
            
            var deviceInfo =
                "System: " + UIDevice.current.systemName + "\n" +
                    "System version: " + sysVersion + "\n" +
                    "Device model: " + model + "\n"
            
            if let appVersion = appVersion {
                deviceInfo = deviceInfo + "App version: \(appVersion)\n"
            }
            
            if let reach = Reachability() {
                deviceInfo = deviceInfo + "Network status: \(reach.currentReachabilityString)\n"
            }
            
            logger.logDebug(LogCategory.general, "Device info:\n" + deviceInfo)
            
            return deviceInfo
        }
    }

    
    
}
