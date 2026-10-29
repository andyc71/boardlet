import Foundation

/// Version 1 screenshot documents remain readable. Version 2 stores a whole page set.
struct ScannerArchive: Codable, Sendable {
    var version = 2
    var pageSet: SnapPageSet

    func validate() throws {
        guard version == 2 else { throw ScanError.invalidBoard }
        try pageSet.validate()
    }
}
