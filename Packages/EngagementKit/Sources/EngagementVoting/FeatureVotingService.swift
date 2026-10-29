import EngagementContent
//
//  FeatureVotingService.swift
//
//
//  Created by Andy on 27/05/2024.
//

import Foundation

public protocol FeatureVotingService {
    func voteForFeature(feature: Feature)
    func dismissVotingPrompt()
    func dismissFeatureList()
}
