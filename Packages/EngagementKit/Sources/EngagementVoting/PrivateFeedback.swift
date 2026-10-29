import Foundation
import EngagementCore

/// A private feedback destination, independent of reviews and voting eligibility.
/// Apps may use this URL with OpenURLAction, or provide their own email-composer/service UI.
public struct PrivateFeedback {
    public let emailAddress: String
    public let subject: String
    public let body: String

    public init(emailAddress: String, subject: String, body: String = "") {
        self.emailAddress = emailAddress
        self.subject = subject
        self.body = body
    }

    public var emailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = emailAddress
        components.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: body)]
        return components.url
    }
}
