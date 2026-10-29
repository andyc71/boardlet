//
//  FeatureStrings.swift
//
//
//  Created by Andy on 30/05/2024.
//

import Foundation

public struct LocalizedFeatureStrings {
    public static var dismissTitle: String { localizedString("Dismiss") }
    public static var invitationTitle: String { localizedString("Vote for New Features") }
    public static var thankYouTitle: String { localizedString("Thank you for voting") }
    public static var thankYouMessage: String { localizedString("We love hearing your ideas") }
    
    public static func featureListNotFoundErrorMessage(locale: String) -> String {
        localizedString("Feature List Not Found Error", locale)
    }
    
    public static func featureListDecodingErrorMessage(locale: String) -> String {
        localizedString("Feature List Decoding Error", locale)
    }
    
    public static func localizedString(_ key: String) -> String {
        return NSLocalizedString(key, bundle: .module, comment: key)
    }

    public static func localizedString(_ key: String, _ param1: String) -> String {
        return String.init(format: localizedString(key), param1)
    }
}
