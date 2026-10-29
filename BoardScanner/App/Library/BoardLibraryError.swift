import Foundation

enum BoardLibraryError: LocalizedError {
    case unreadable
    var errorDescription: String? {
        "This board and its recovery copy could not be opened. Your saved files have been kept. You can open another board from the library or import a backup."
    }
}
