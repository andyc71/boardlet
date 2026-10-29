import Foundation

enum AuthoringError: LocalizedError {
    case missingPage, invalidGrid, invalidName, occupiedCell, protectedHome, missingDestination, invalidImage
    var errorDescription: String? {
        switch self {
        case .missingPage: "This page or layout is no longer available."
        case .invalidGrid: "Choose a valid grid and button position. Buttons must stay within 256 rows and columns."
        case .invalidName: "Enter a name before saving."
        case .occupiedCell: "Another button occupies that position. Choose a free position, including space for the whole button."
        case .protectedHome: "Choose another home page before deleting this page. A board must keep at least one page."
        case .missingDestination: "Choose an available page for this button to open."
        case .invalidImage: "This picture could not be used. Choose a different image."
        }
    }
}
