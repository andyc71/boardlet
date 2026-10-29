import EngagementContent
//
//  FeatureSettings.swift
//
//
//  Created by Andy on 27/05/2024.
//

import Foundation

public protocol FeatureSettings {
    var featureRequestEmailAddress: String { get }
    var featureRequestEmailSubject: String { get }
    var featureRequestEmailBody: String { get }
    var featureRequestLocale: String { get }
    var featureVotingService: FeatureVotingService? { get }
}
