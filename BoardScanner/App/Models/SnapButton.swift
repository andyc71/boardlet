import Foundation

struct SnapButton: Codable, Identifiable, Sendable {
    var id: String
    var label: String
    var message: String
    var assetKey: String?
    var destinationIDs: [String]
    var communicationAction: CommunicationAction? = nil
    /// Source commands are retained as data, never evaluated or executed.
    var serializedCommands: String
    var backgroundARGB: UInt32? = nil
    var foregroundARGB: UInt32? = nil
    var borderARGB: UInt32? = nil
}
