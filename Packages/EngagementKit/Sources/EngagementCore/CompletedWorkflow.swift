/// Emit only after successful completion, never on navigation or opening system UI.
public enum CompletedWorkflow: String, Codable, Sendable {
    case printBoard, exportBoard, shareBoard, saveBoard
    public var isRatingWorthy: Bool { self != .saveBoard }
}
