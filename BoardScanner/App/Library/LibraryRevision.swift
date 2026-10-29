import Foundation

struct LibraryRevision: Codable, Sendable {
    let id: UUID
    let title: String
    let updatedAt: Date
    let detail: String
}
