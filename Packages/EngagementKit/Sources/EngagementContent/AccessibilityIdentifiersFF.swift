//
//  AccessibilityIdentifiers.swift
//  FeaturePickerTest
//
//  Created by Andy on 23/05/2024.
//

import Foundation

public struct AccessibilityIdentifiersFF {
    public static let votePromptView = "votePromptView"
    public static let votePromptVoteButton = "votePromptVoteButton"
    public static let votePromptDismissButton = "votePromptDismissButton"
    public static let localePicker = "localePicker"
    public static let thankYouAlert = "thankYouAlert"
    
    public struct FeaturesView {
        public static let title = "FeaturesView.title"
        public static let header = "FeaturesView.header"
        public static let footer = "FeaturesView.footer"
        public static let closeButton = "FeaturesView.closeButton"
        public static let featureCellPrefix = "FeaturesView.featureCell"
        public static let featureTitle = "FeaturesView.featureTitle"
        public static let featureDescription = "FeaturesView.featureDescription"
        
        public static func featureCell(id: String) -> String {
            return "\(featureCellPrefix)-\(id)"
        }
    }
}

