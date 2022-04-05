// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Done
  internal static let doneButton = L10n.tr("Localizable", "DoneButton")

  internal enum FormattingView {
    /// Grid colour
    internal static let gridlinesColour = L10n.tr("Localizable", "FormattingView.gridlinesColour")
    /// Gridlines
    internal static let gridlinesSectionTitle = L10n.tr("Localizable", "FormattingView.gridlinesSectionTitle")
    /// Thicker gridlines
    internal static let gridlinesThicker = L10n.tr("Localizable", "FormattingView.gridlinesThicker")
    /// Big
    internal static let marginsBig = L10n.tr("Localizable", "FormattingView.marginsBig")
    /// Margins
    internal static let marginsSectionTitle = L10n.tr("Localizable", "FormattingView.marginsSectionTitle")
    /// Small
    internal static let marginsSmall = L10n.tr("Localizable", "FormattingView.marginsSmall")
    /// Formatting
    internal static let title = L10n.tr("Localizable", "FormattingView.title")
    /// Bold font
    internal static let titlesBoldFontOption = L10n.tr("Localizable", "FormattingView.titlesBoldFontOption")
    /// Titles
    internal static let titlesSectionTitle = L10n.tr("Localizable", "FormattingView.titlesSectionTitle")
    /// Text colour
    internal static let titlesTextColor = L10n.tr("Localizable", "FormattingView.titlesTextColor")
  }

  internal enum LayoutScreen {
    /// Done
    internal static let doneButton = L10n.tr("Localizable", "LayoutScreen.doneButton")
    /// Layout
    internal static let title = L10n.tr("Localizable", "LayoutScreen.title")
  }

  internal enum LayoutSelectionView {
    /// Layout
    internal static let title = L10n.tr("Localizable", "LayoutSelectionView.title")
  }

  internal enum LayoutSummaryView {
    /// Each PECS card measures:
    internal static let cardSizeTitle = L10n.tr("Localizable", "LayoutSummaryView.cardSizeTitle")
    /// Page measurements:
    internal static let pageMeasurements = L10n.tr("Localizable", "LayoutSummaryView.pageMeasurements")
    /// Summary
    internal static let title = L10n.tr("Localizable", "LayoutSummaryView.title")
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

  internal enum OrientationSelectionView {
    /// Orientation
    internal static let title = L10n.tr("Localizable", "OrientationSelectionView.title")
  }

  internal enum PageSizeSelectionView {
    /// Page Size
    internal static let title = L10n.tr("Localizable", "PageSizeSelectionView.title")
  }

  internal enum PreviewPage {
    /// Repeat Image
    internal static let repeatButton = L10n.tr("Localizable", "PreviewPage.repeatButton")
    /// Save or Print
    internal static let saveButton = L10n.tr("Localizable", "PreviewPage.saveButton")
    /// Print
    internal static let title = L10n.tr("Localizable", "PreviewPage.title")
  }

  internal enum RatingAlert {
    /// Your rating will help other users to find this app more easily.
    internal static let message = L10n.tr("Localizable", "RatingAlert.message")
    /// No
    internal static let noButton = L10n.tr("Localizable", "RatingAlert.noButton")
    /// Rate
    internal static let rateButton = L10n.tr("Localizable", "RatingAlert.rateButton")
    /// Please Rate Easy PECS
    internal static let title = L10n.tr("Localizable", "RatingAlert.title")
  }

  internal enum RatingPromptView {
    /// Maybe Later
    internal static let laterButton = L10n.tr("Localizable", "RatingPromptView.laterButton")
    /// No Thanks
    internal static let noButton = L10n.tr("Localizable", "RatingPromptView.noButton")
    /// Rate
    internal static let rateButton = L10n.tr("Localizable", "RatingPromptView.rateButton")
  }

  internal enum SettingsPage {
    /// Settings
    internal static let title = L10n.tr("Localizable", "SettingsPage.title")
  }

  internal enum TitlesPage {
    /// Titles
    internal static let title = L10n.tr("Localizable", "TitlesPage.title")
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
