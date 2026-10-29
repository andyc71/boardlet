//
//  FeaturesViewModel.swift
//  FeaturePickerTest
//
//  Created by Andy on 23/05/2024.
//

import Foundation
import Combine
import EngagementCore
import EngagementContent
import MessageUI
import MailFramework

@MainActor
public class FeaturesViewModel: FeaturesViewModelProtocol {
    @Published public var title: String = ""
    @Published public var header: String?
    @Published public var footer: String?
    @Published public var buttonTitle: String = ""
    @Published public var iconPosition: FeatureIconPosition = .trailing
    @Published public var canVote: Bool = true
    @Published public var features: [Feature] = []
    @Published public var lastModified: Date?
    
    @Published public var showVotingPrompt: Bool = false
    @Published public var votingPromptError: Error?
    @Published public var showFeaturesView: Bool = false
    //@Published public var showSendMailAlert: Bool = false
    //@Published public var showSendMailAlertData: Mail?
    
    public let coordinator: EngagementCoordinator
    public private(set) var campaignID: String?
    public func considerInvitation(opportunity: UUID, context: EngagementContext, requestReview: () -> Void) {
        switch coordinator.solicit(at: opportunity, context: context, campaignID: campaignID) {
        case .voting: showVotingPrompt = true
        case .review:
            requestReview()
            coordinator.finish(.review)
        default: break
        }
    }
    public func openVoting() {
        coordinator.recordUserInitiatedInteraction()
        votingPresentationID = UUID()
        showFeaturesView = true
    }
    
    public lazy var showSendMailViewModel: EmailComposerViewModel = {
        EmailComposerViewModel(emailData: nil, shouldShowAlerts: false, onDismiss: { [weak self] result in
            guard let self else { return }
            self.handleSendMailEvent(result: result)
        })
    }()
    
    @Published public var showThankYouAlert: Bool = false
    
    private var selectedFeature: Feature?
    private var votingPresentationID: UUID?
    
    private var featureSettings: FeatureSettings
    
    public init(featureSettings: FeatureSettings, coordinator: EngagementCoordinator) {
        self.featureSettings = featureSettings
        self.coordinator = coordinator
        loadFeatures(for: featureSettings.featureRequestLocale)
    }
    
    public func loadFeatures(for locale: String) {
        loadFeatures(for: locale, in: Bundle.main)
    }

    public func loadFeatures(for locale: String, in bundle: Bundle, subdirectory: String? = nil) {
    
        do {
            let decodedResponse = try FeaturesResponse.load(for: locale, in: bundle, subdirectory: subdirectory)
            self.title = decodedResponse.title
            self.header = decodedResponse.header
            self.footer = decodedResponse.footer
            self.buttonTitle = decodedResponse.buttonTitle
            self.features = decodedResponse.features
            self.lastModified = decodedResponse.lastModified
            self.votingPromptError = nil
            
            // No lastModified fallback: campaigns must have stable, explicit identity.
            campaignID = decodedResponse.campaignID
            if let campaignID { coordinator.registerCampaign(campaignID) }

        }
        catch {
            self.votingPromptError = error
            self.campaignID = nil
            self.features = []
            self.showVotingPrompt = false
        }
        
    }
    
    public func dismissPrompt() {
        showVotingPrompt = false
        if let campaignID { coordinator.dismissCampaign(campaignID) }
        featureSettings.featureVotingService?.dismissVotingPrompt()
    }

    public func handleVote(for feature: Feature) {
        if feature.sendMail == true {
            handleSendMailVote(for: feature)
        }
        else {
            handleStandardVote(for: feature)
        }
        
    }
    
    func handleStandardVote(for feature: Feature) {
        if let campaignID { coordinator.recordVote(campaignID: campaignID) }
        featureSettings.featureVotingService?.voteForFeature(feature: feature)
        showThankYouAlert = true
    }

    func handleSendMailVote(for feature: Feature) {
        selectedFeature = feature
        dismissFeaturesView()
    }
    
    func handleSendMailEvent(result: MFMailComposeResult?) {
        if result == .sent {
            self.showSendMailViewModel.clearData()
            if let feature = selectedFeature {
                self.selectedFeature = nil
                self.handleStandardVote(for: feature)
                return
            }
            else {
                dismissThankYouAlert()
            }
        }
        else {
            self.selectedFeature = nil
            self.showSendMailViewModel.clearData()
        }
    }

    public func dismissFeaturesView() { showFeaturesView = false }

    /// Called by the single scene sheet host after its dismissal animation completes.
    public func featuresViewDidDismiss() {
        guard votingPresentationID != nil else { return }
        votingPresentationID = nil
        showVotingPrompt = false
        if let campaignID { coordinator.dismissCampaign(campaignID) }
        featureSettings.featureVotingService?.dismissFeatureList()
        // Mail follows actual sheet dismissal, rather than racing it on the next runloop.
        if selectedFeature != nil { showSendMailViewModel.setData(makeMailData()) }
    }
        
    public func dismissThankYouAlert() {
        self.showThankYouAlert = false
        self.showFeaturesView = false
        self.showVotingPrompt = false
    }
    
    private func makeMailData() -> Mail {
        var emailData = Mail()
        emailData.to = [Mail.Address(email: featureSettings.featureRequestEmailAddress)]
        emailData.subject = featureSettings.featureRequestEmailSubject
        emailData.message = .plainText(featureSettings.featureRequestEmailBody)
        return emailData
    }
    
    public func isLastFeature(_ feature: Feature) -> Bool {
        return features.last?.id == feature.id
    }
    
}
