import Foundation

/// Conservative defaults. All intervals are elapsed seconds; active days are UTC calendar days.
public struct EngagementPolicy {
    public var minimumInstallAge: TimeInterval = 14 * 86_400
    public var minimumActiveDays = 3
    public var votingWorkflowCount = 2
    public var ratingWorkflowCount = 3
    public var votingCampaignInterval: TimeInterval = 90 * 86_400
    public var ratingAttemptInterval: TimeInterval = 120 * 86_400
    public var solicitationInterval: TimeInterval = 30 * 86_400
    public var ratingsEnabled = true
    public var votingEnabled = true
    public init() {}
}
