import Foundation

/// Conservative translation of single commands observed in schema 4.20.
/// Unknown and compound command sequences remain inspectable, never executed.
enum SnapCommunicationBehavior: Equatable {
    case action(CommunicationAction)
    case destinations
    case unsupported

    static func resolve(_ button: SnapButton) -> Self {
        if button.communicationAction == .openPage { return .destinations }
        if let action = button.communicationAction, action != .automatic { return .action(action) }
        let command = resolveCommands(button.serializedCommands)
        // TD Snap retains page references alongside its Home and Keyboard commands.
        // Those commands select a role, not the historical referenced page ID.
        if command == .action(.home) || command == .action(.keyboard) { return command }
        if !button.destinationIDs.isEmpty { return .destinations }
        return command
    }

    private static func resolveCommands(_ serializedCommands: String) -> Self {
        guard !serializedCommands.isEmpty else { return .action(.addMessage) }
        guard let data = serializedCommands.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let commands = object["$values"] as? [[String: Any]] else { return .unsupported }
        guard !commands.isEmpty else { return .action(.addMessage) }
        guard commands.count == 1, let command = commands.first,
              let type = command["$type"] as? String else { return .unsupported }
        switch type {
        case "3":
            switch command["MessageAction"] as? Int {
            case 0: return .action(.addMessage)
            case 1: return .action(.speakImmediately)
            default: return .unsupported
            }
        case "4": return .action(.back)
        case "5": return .action(.home)
        case "8": return .action(.speakMessage)
        case "9": return .action(.clearMessage)
        case "10": return .action(.undo)
        case "17": return .action(.keyboard)
        case "75": return .action(.stop)
        default: return .unsupported
        }
    }
}
