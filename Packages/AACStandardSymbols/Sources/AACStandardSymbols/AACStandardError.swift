import Foundation

public enum AACStandardError: Error, LocalizedError, Equatable, Sendable {
    case invalidPagination
    case invalidResponse
    case serviceFailure
    case httpStatus(Int)
    case throttled(retryAfter: String?)
    case invalidImageURL
    case invalidImage

    public var errorDescription: String? {
        switch self {
        case .invalidPagination:
            return String(localized: "Use a page size from 1 to 100 and a nonnegative offset.", bundle: .module)
        case .invalidResponse, .serviceFailure:
            return String(localized: "AAC Standard returned an invalid response.", bundle: .module)
        case .httpStatus(let status):
            return String(localized: "AAC Standard returned HTTP \(status).", bundle: .module)
        case .throttled:
            return String(localized: "AAC Standard is limiting requests. Please try again later.", bundle: .module)
        case .invalidImageURL, .invalidImage:
            return String(localized: "AAC Standard returned an invalid image.", bundle: .module)
        }
    }
}
