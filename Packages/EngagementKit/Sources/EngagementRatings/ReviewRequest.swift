import Foundation
import EngagementCore

/// StoreKit's scene-local SwiftUI requestReview action is injected by the host view.
/// The closure is invoked only after an attempt has been durably recorded.
@MainActor
public enum ReviewRequest {
    @discardableResult
    public static func attempt(coordinator: EngagementCoordinator, opportunity: UUID,
                               context: EngagementContext, request: () -> Void) -> Bool {
        guard coordinator.solicit(at: opportunity, context: context) == .review else { return false }
        request()
        coordinator.finish(.review)
        return true
    }

    /// User-initiated reviews open the App Store; they do not depend on StoreKit showing a prompt.
    public static func writeReviewURL(appURL: URL) -> URL? {
        var components = URLComponents(url: appURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "action", value: "write-review")]
        return components?.url
    }
}
