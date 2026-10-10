import Foundation

/// App-wide presentation preference. Board data and rendering are shared by both interfaces.
enum InterfaceStyle: String, CaseIterable {
    case modern
    case classic

    static let storageKey = "pecsInterfaceStyle"
    static let defaultValue: InterfaceStyle = .modern
}
