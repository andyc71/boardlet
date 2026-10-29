/// Apps describe the current scene, never decide engagement eligibility themselves.
public struct EngagementContext: Equatable {
    public var isActive: Bool
    public var isLibrary: Bool
    public var isEditing: Bool
    public var hasModalOrSystemActivity: Bool
    public var welcomePending: Bool
    public var whatsNewPending: Bool

    public init(isActive: Bool = false, isLibrary: Bool = false, isEditing: Bool = false,
                hasModalOrSystemActivity: Bool = false, welcomePending: Bool = false,
                whatsNewPending: Bool = false) {
        self.isActive = isActive
        self.isLibrary = isLibrary
        self.isEditing = isEditing
        self.hasModalOrSystemActivity = hasModalOrSystemActivity
        self.welcomePending = welcomePending
        self.whatsNewPending = whatsNewPending
    }

    public var permitsPresentation: Bool {
        isActive && !isEditing && !hasModalOrSystemActivity && !welcomePending
    }
    public var permitsSolicitation: Bool { permitsPresentation && isLibrary && !whatsNewPending }
}
