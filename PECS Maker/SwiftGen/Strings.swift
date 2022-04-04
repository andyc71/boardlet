// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {

  internal enum LayoutScreen {
    /// Done
    internal static let doneButton = L10n.tr("Localizable", "LayoutScreen.doneButton")
    /// Layout
    internal static let title = L10n.tr("Localizable", "LayoutScreen.title")
  }

  internal enum MainMenu {
    /// Add Titles
    internal static let addTitlesButton = L10n.tr("Localizable", "MainMenu.addTitlesButton")
    /// More Apps
    internal static let moreAppsButton = L10n.tr("Localizable", "MainMenu.moreAppsButton")
    /// Preview and Print
    internal static let printButton = L10n.tr("Localizable", "MainMenu.printButton")
    /// Select Layout
    internal static let selectLayoutButton = L10n.tr("Localizable", "MainMenu.selectLayoutButton")
    /// Select Photos
    internal static let selectPhotosButton = L10n.tr("Localizable", "MainMenu.selectPhotosButton")
    /// Settings
    internal static let settingsButton = L10n.tr("Localizable", "MainMenu.settingsButton")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
