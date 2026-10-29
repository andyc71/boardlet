import Foundation

struct LibraryEntry: Identifiable, Sendable {
    let id: UUID
    let title: String
    let updatedAt: Date
    let detail: String
    var isDeleted = false
}

