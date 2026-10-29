import Foundation

struct LibraryRecord: Codable, Sendable {
    let current: LibraryRevision
    let previous: LibraryRevision?
}
