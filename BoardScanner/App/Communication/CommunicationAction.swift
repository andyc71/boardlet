import Foundation

/// Native actions are saved separately from the untouched source command payload.
enum CommunicationAction: String, Codable, CaseIterable, Identifiable {
    case automatic, openPage, addMessage, speakImmediately, speakMessage, clearMessage, undo, stop, home, back, keyboard, none
    var id: String { rawValue }
    var title: String {
        switch self {
        case .automatic: "Default behavior"
        case .openPage: "Open page"
        case .addMessage: "Add to message"
        case .speakImmediately: "Speak this button"
        case .speakMessage: "Speak message"
        case .clearMessage: "Clear message"
        case .undo: "Delete last selection"
        case .stop: "Stop speaking"
        case .home: "Go home"
        case .back: "Go back"
        case .keyboard: "Type a message"
        case .none: "No action"
        }
    }
}
