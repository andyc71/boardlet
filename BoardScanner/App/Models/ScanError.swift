import Foundation

enum ScanError: LocalizedError {
    case invalidImage, noGrid, invalidBoard, oversizedFile, invalidPageSet

    var errorDescription: String? {
        switch self {
        case .invalidPageSet: "This TD Snap page set is damaged or uses an unsupported structure."
        case .invalidImage: "This image could not be decoded. Choose a PNG, JPEG or HEIC screenshot."
        case .noGrid: "No reliable grid was found. Use Adjust grid to set the board area, rows and columns."
        case .invalidBoard: "This board file is damaged or uses an unsupported version."
        case .oversizedFile: "This file is too large. Choose a file smaller than 80 MB."
        }
    }
}
