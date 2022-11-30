//
//  StoreKitHelper.swift
//  SharedUI
//
//  Created by Andy on 10/09/2020.
//  Copyright © 2020 Andrew Clynes. All rights reserved.
//

import StoreKit
import LogFramework

public enum RatingResponse {
    case rate, later, no
}

public struct RatingStatus {
    var lastReviewedVersion: String?
    var significantEventCount: Int
    var lastPromptDate: Date?
    var currentAppVersion: String
}

public class RatingHelper {
    
    public typealias PromptForRatingCallbackType = (RatingStatus)->Void
    public typealias AppVersionGetterCallbackType = ()->String?

    public static var minimumReviewWorthyActionCount = 3

    public static var minimumTimeBetweenPrompts: TimeInterval = 2 * 24 * 60 * 60 //2 Days
    //public static let minimumTimeBetweenPrompts: TimeInterval = 30 //30 seconds

    public static var promptForRatingCallback: PromptForRatingCallbackType = askUserToRate
    
    public static var appVersionGetter: AppVersionGetterCallbackType = {
        let bundle = Bundle.main
        let bundleVersionKey = kCFBundleVersionKey as String
        let currentVersion = bundle.object(forInfoDictionaryKey: bundleVersionKey) as? String
        return currentVersion
    }
    
    public static var allowRatings: Bool = false
    
    public static var lastUsedVersion: String? {
        get {
            let defaults = UserDefaults.standard
            let version = defaults.string(forKey: .lastUsedVersion)
            return version
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: .lastUsedVersion)
        }
    }

    public static var significantEventCount: Int {
        get {
            let defaults = UserDefaults.standard
            let actionCount = defaults.integer(forKey: .reviewWorthyActionCount)
            return actionCount
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: .reviewWorthyActionCount)
        }
    }

    public static var dontReviewCurrentVersion: Bool {
        get {
            let defaults = UserDefaults.standard
            let dontReview = defaults.bool(forKey: .dontReview)
            return dontReview
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: .dontReview)
        }
    }
    
    public static var lastUsedVersionIsRated: Bool {
        get {
            let defaults = UserDefaults.standard
            let dontReview = defaults.bool(forKey: .lastUsedVersionIsRated)
            return dontReview
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: .lastUsedVersionIsRated)
        }
    }

    public static var lastPromptDate: Date? {
        get {
            let defaults = UserDefaults.standard
            let date = defaults.date(forKey: .lastPromptDate)
            return date
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: .lastPromptDate)
        }
    }
    
    public static func shouldPromptForReview() -> Bool {
        
        //Check the current version. If it's different from the
        //last version, we can reset the "Don't review this version"
        //flag.
        guard let currentVersion = appVersionGetter() else {
            logger.logError(.appRating, "Could not get current app version")
            return false
        }
        
        if currentVersion == lastUsedVersion {
            if lastUsedVersionIsRated {
                logger.logDebug(.appRating, "Version \(currentVersion) has already been reviewed")
                return false
            }
        }
        else {
            //New version has been installed
            logger.logDebug(.appRating, "New version detected. Resetting counts.")
            significantEventCount = 0
            dontReviewCurrentVersion = false
            lastUsedVersionIsRated = false
            lastUsedVersion = currentVersion
        }
        
        /*
        //Increase the action count, and check if it exceeds the
        //minimum number required to cause a rating prompt.
        let actionCount = significantEventCount + 1
        significantEventCount = actionCount
        logger.logDebug(.appRating, "significantEventCount = \(significantEventCount)")
         
         */
        
        let actionCount = significantEventCount
        if actionCount < minimumReviewWorthyActionCount {
            logger.logDebug(.appRating, "significantEventCount = \(significantEventCount) is less than minimumReviewWorthyActionCount=\(minimumReviewWorthyActionCount)")
            return false
        }

        /*
         //Check if we're allowed to show the prompt
        if canPromptForReview == false {
            logger.logDebug(.appRating, "canPromptForReview is false")
            return
        }
        */
        
        if dontReviewCurrentVersion {
            logger.logDebug(.appRating, "dontReviewCurrentVersion is true")
            return false
        }
        
        if let lastDate = lastPromptDate {
            let nextPromptDate = lastDate.addingTimeInterval( minimumTimeBetweenPrompts)
            if Date() < nextPromptDate {
                logger.logDebug(.appRating, "Not prompting - too close to previous request")
                return false
            }
        }
        
        /*
        logger.logDebug(.appRating, "Requesting rating")
        let ratingStatus = RatingStatus(lastReviewedVersion: lastUsedVersion, significantEventCount: significantEventCount, lastPromptDate: lastPromptDate, currentAppVersion: currentVersion)
        DispatchQueue.main.async {
            promptForRatingCallback(ratingStatus)
        }
        */
        
        return true
        
    }

    
    public static func signifcantEventOccurred(canPromptForReview: Bool) {
        
        //Check the current version. If it's different from the
        //last version, we can reset the "Don't review this version"
        //flag.
        guard let currentVersion = appVersionGetter() else {
            logger.logError(.appRating, "Could not get current app version")
            return
        }
        
        if currentVersion == lastUsedVersion {
            if lastUsedVersionIsRated {
                logger.logDebug(.appRating, "Version \(currentVersion) has already been reviewed")
                return
            }
        }
        else {
            //New version has been installed
            logger.logDebug(.appRating, "New version detected. Resetting counts.")
            significantEventCount = 0
            dontReviewCurrentVersion = false
            lastUsedVersionIsRated = false
            lastUsedVersion = currentVersion
        }
        
        //Increase the action count, and check if it exceeds the
        //minimum number required to cause a rating prompt.
        let actionCount = significantEventCount + 1
        significantEventCount = actionCount
        logger.logDebug(.appRating, "significantEventCount = \(significantEventCount)")
        
        if actionCount < minimumReviewWorthyActionCount {
            logger.logDebug(.appRating, "significantEventCount = \(significantEventCount) is less than minimumReviewWorthyActionCount=\(minimumReviewWorthyActionCount)")
            return
        }

        //Check if we're allowed to show the prompt
        if canPromptForReview == false {
            logger.logDebug(.appRating, "canPromptForReview is false")
            return
        }

        if dontReviewCurrentVersion {
            logger.logDebug(.appRating, "dontReviewCurrentVersion is true")
            return
        }

        if let lastDate = lastPromptDate {
            let nextPromptDate = lastDate.addingTimeInterval( minimumTimeBetweenPrompts)
            if Date() < nextPromptDate {
                logger.logDebug(.appRating, "Not prompting - too close to previous request")
                return
            }
        }
        
        logger.logDebug(.appRating, "Requesting rating")
        let ratingStatus = RatingStatus(lastReviewedVersion: lastUsedVersion, significantEventCount: significantEventCount, lastPromptDate: lastPromptDate, currentAppVersion: currentVersion)
        DispatchQueue.main.async {
            promptForRatingCallback(ratingStatus)
        }
    }    

    
    public static func askUserToRate(_: RatingStatus) {
        /*
        if allowRatings == false {
            return
        }
        
        guard let parentViewController = RatingHelper.getTopViewController() else {
            return
        }
        
        let vc = RatingPromptViewController()
        
        // Create the dialog
        let popup = PopupDialog(viewController: vc,
                                buttonAlignment: .horizontal,
                                transitionStyle: .fadeIn,
                                tapGestureDismissal: false,
                                panGestureDismissal: false
        )
        
        let okButton = DefaultButton(title: "Rate") {
            
            self.showLockScreenAndThenRate(parentViewController: parentViewController)
            RatingHelper.setRatingResponse(RatingResponse.rate)
        }
        okButton.setLocalizedTitleWithAccessibility(SharedUILocalizableIDs.RatingHelper.rateButton.rawValue)

        
        let noButton = PopupDialogButton(title: "No Thanks") {
            RatingHelper.setRatingResponse(RatingResponse.no)
        }
        noButton.setLocalizedTitleWithAccessibility(SharedUILocalizableIDs.RatingHelper.noButton.rawValue)

        
        let laterButton = CancelButton(title: "Maybe Later") {
            RatingHelper.setRatingResponse(RatingResponse.later)
        }
        laterButton.setLocalizedTitleWithAccessibility(SharedUILocalizableIDs.RatingHelper.laterButton.rawValue)

        
        // Add buttons to dialog
        popup.addButtons([okButton, noButton, laterButton])
        
        // Present dialog
        parentViewController.present(popup, animated: true, completion: nil)*/
    }
    
    
    
    public static func setup() {
        self.allowRatings = true
    }

    public static func reset() {
        RatingHelper.lastUsedVersion = nil
        RatingHelper.significantEventCount = 0
        RatingHelper.dontReviewCurrentVersion = false
        RatingHelper.lastUsedVersionIsRated = false
        RatingHelper.lastPromptDate = nil
    }

    public static func setRatingResponse(_ response: RatingResponse) {
        RatingHelper.lastPromptDate = Date()
        switch response {
        case .later:
            MFAnalytics.logRatingResponse(.maybeLater)
            return
        case .no:
            RatingHelper.dontReviewCurrentVersion = true
            MFAnalytics.logRatingResponse(.no)
        case .rate:
            //lastUsedVersion = RatingHelper.appVersionGetter()
            RatingHelper.lastUsedVersionIsRated = true
            MFAnalytics.logRatingResponse(.yes)
        }
    }
    
}
