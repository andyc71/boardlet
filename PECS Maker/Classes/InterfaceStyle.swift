import Foundation

/// App-wide presentation preference. Board data and rendering are shared by both interfaces.
enum InterfaceStyle: String, CaseIterable {
    case modern
    case classic

    static let storageKey = "pecsInterfaceStyle"
    #if EasyPECSPlus
    static let canChange = true
    static let defaultValue: InterfaceStyle = .modern
    #else
    static let canChange = false
    static let defaultValue: InterfaceStyle = .classic
    #endif
}
