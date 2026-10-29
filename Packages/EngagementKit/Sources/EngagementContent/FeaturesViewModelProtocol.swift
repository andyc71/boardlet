import SwiftUI
public enum FeatureIconPosition { case leading, trailing }
@MainActor
public protocol FeaturesViewModelProtocol: ObservableObject {
    var title: String { get }
    var header: String? { get }
    var footer: String? { get }
    var buttonTitle: String { get }
    var iconPosition: FeatureIconPosition { get }
    var canVote: Bool { get }
    var features: [Feature] { get }
    func dismissFeaturesView()
    func handleVote(for feature: Feature)
    func isLastFeature(_ feature: Feature) -> Bool
}
