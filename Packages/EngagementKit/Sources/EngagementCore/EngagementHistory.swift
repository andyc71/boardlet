import Foundation

public struct EngagementHistory: Codable, Equatable {
    public var firstUse: Date
    public var activeDays: Set<String> = []
    public var completedWorkflows = 0
    public var ratingWorkflows = 0
    public var completedWorkflowIDs: Set<String> = []
    public var invitedCampaignIDs: Set<String> = []
    public var dismissedCampaignIDs: Set<String> = []
    public var votedCampaignIDs: Set<String> = []
    public var lastVotingInvitation: Date?
    public var lastReviewAttempt: Date?
    public var attemptedVersions: Set<String> = []
    public var lastSolicitation: Date?
    public var migratedVoting = false
    public init(firstUse: Date) { self.firstUse = firstUse }
}
