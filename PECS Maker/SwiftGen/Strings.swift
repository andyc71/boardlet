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

  internal enum ClearSelectionsAlert {
    /// Clear selections and start a new design?
    internal static let message = L10n.tr("Localizable", "ClearSelectionsAlert.message")
    /// Clear Selections
    internal static let title = L10n.tr("Localizable", "ClearSelectionsAlert.title")
  }

  internal enum FitzgeraldKey {
    /// Adjective
    internal static let adjective = L10n.tr("Localizable", "FitzgeraldKey.adjective")
    /// Adverb
    internal static let adverb = L10n.tr("Localizable", "FitzgeraldKey.adverb")
    /// Conjunction
    internal static let conjunction = L10n.tr("Localizable", "FitzgeraldKey.conjunction")
    /// Determiner
    internal static let determiner = L10n.tr("Localizable", "FitzgeraldKey.determiner")
    /// Important
    internal static let important = L10n.tr("Localizable", "FitzgeraldKey.important")
    /// No Fitzgerald Key
    internal static let `none` = L10n.tr("Localizable", "FitzgeraldKey.none")
    /// Noun
    internal static let noun = L10n.tr("Localizable", "FitzgeraldKey.noun")
    /// Preposition
    internal static let preposition = L10n.tr("Localizable", "FitzgeraldKey.preposition")
    /// Pronoun
    internal static let pronoun = L10n.tr("Localizable", "FitzgeraldKey.pronoun")
    /// Question
    internal static let question = L10n.tr("Localizable", "FitzgeraldKey.question")
    /// Verb
    internal static let verb = L10n.tr("Localizable", "FitzgeraldKey.verb")
  }

  internal enum FormattingView {
    /// Fitzgerald Keys
    internal static let fitzgeraldKeysSectionTitle = L10n.tr("Localizable", "FormattingView.fitzgeraldKeysSectionTitle")
    /// Thicker borders
    internal static let fitzgeraldKeysThickerBorders = L10n.tr("Localizable", "FormattingView.fitzgeraldKeysThickerBorders")
    /// Grid colour
    internal static let gridlinesColour = L10n.tr("Localizable", "FormattingView.gridlinesColour")
    /// Gridlines
    internal static let gridlinesSectionTitle = L10n.tr("Localizable", "FormattingView.gridlinesSectionTitle")
    /// Thicker gridlines
    internal static let gridlinesThicker = L10n.tr("Localizable", "FormattingView.gridlinesThicker")
    /// Big
    internal static let labelBig = L10n.tr("Localizable", "FormattingView.labelBig")
    /// Label size
    internal static let labelSectionTitle = L10n.tr("Localizable", "FormattingView.labelSectionTitle")
    /// Small
    internal static let labelSmall = L10n.tr("Localizable", "FormattingView.labelSmall")
    /// Big
    internal static let marginBig = L10n.tr("Localizable", "FormattingView.marginBig")
    /// Margins
    internal static let marginSectionTitle = L10n.tr("Localizable", "FormattingView.marginSectionTitle")
    /// Small
    internal static let marginSmall = L10n.tr("Localizable", "FormattingView.marginSmall")
    /// Formatting
    internal static let title = L10n.tr("Localizable", "FormattingView.title")
    /// Bold font
    internal static let titlesBoldFontOption = L10n.tr("Localizable", "FormattingView.titlesBoldFontOption")
    /// Titles
    internal static let titlesSectionTitle = L10n.tr("Localizable", "FormattingView.titlesSectionTitle")
    /// Text colour
    internal static let titlesTextColor = L10n.tr("Localizable", "FormattingView.titlesTextColor")
    /// Position
    internal static let titlesTextPosition = L10n.tr("Localizable", "FormattingView.titlesTextPosition")
  }

  internal enum FruitNames {
    /// apple
    internal static let apple = L10n.tr("Localizable", "FruitNames.apple")
    /// banana
    internal static let banana = L10n.tr("Localizable", "FruitNames.banana")
    /// cherry
    internal static let cherry = L10n.tr("Localizable", "FruitNames.cherry")
    /// grapes
    internal static let grapes = L10n.tr("Localizable", "FruitNames.grapes")
    /// lemon
    internal static let lemon = L10n.tr("Localizable", "FruitNames.lemon")
    /// peach
    internal static let peach = L10n.tr("Localizable", "FruitNames.peach")
    /// pear
    internal static let pear = L10n.tr("Localizable", "FruitNames.pear")
    /// pineapple
    internal static let pineapple = L10n.tr("Localizable", "FruitNames.pineapple")
    /// strawberry
    internal static let strawberry = L10n.tr("Localizable", "FruitNames.strawberry")
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
    /// Aspect ratio:
    internal static let aspectRatio = L10n.tr("Localizable", "LayoutSummaryView.aspectRatio")
    /// Number of PECS cards per page:
    internal static let cardCount = L10n.tr("Localizable", "LayoutSummaryView.cardCount")
    /// %d across by %d down
    internal static func cardsAcrossAndDown(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "LayoutSummaryView.cardsAcrossAndDown", p1, p2)
    }
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
    /// Clear Selections
    internal static let clearSelectionsButton = L10n.tr("Localizable", "MainMenu.clearSelectionsButton")
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
    /// No, Thanks
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

  internal enum Repo {
    /// New Design
    internal static let defaultTopicTitle = L10n.tr("Localizable", "Repo.defaultTopicTitle")
  }

  internal enum SettingsPage {
    /// Settings
    internal static let title = L10n.tr("Localizable", "SettingsPage.title")
  }

  internal enum SettingsView {
    /// Diagnostics
    internal static let diagnosticsButton = L10n.tr("Localizable", "SettingsView.diagnosticsButton")
  }

  internal enum TitlesPage {
    /// Titles
    internal static let title = L10n.tr("Localizable", "TitlesPage.title")
    /// Title
    internal static let titleTextPlaceholder = L10n.tr("Localizable", "TitlesPage.titleTextPlaceholder")
  }

  internal enum TitlesScreen {
    /// Select some photos and then come back to this screen to enter their titles.
    internal static let noPhotosMessage = L10n.tr("Localizable", "TitlesScreen.noPhotosMessage")
  }

  internal enum TopicSelectionView {
    /// Create Design
    internal static let createDesignButton = L10n.tr("Localizable", "TopicSelectionView.createDesignButton")
    /// Click Create Design to start a new PECS template.
    internal static let noTopicsMessage = L10n.tr("Localizable", "TopicSelectionView.noTopicsMessage")
    /// My Designs
    internal static let title = L10n.tr("Localizable", "TopicSelectionView.title")
    internal enum DeleteTopicAlert {
      /// Delete design %s?
      internal static func message(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "TopicSelectionView.DeleteTopicAlert.message", p1)
      }
      /// Delete Design
      internal static let title = L10n.tr("Localizable", "TopicSelectionView.DeleteTopicAlert.title")
    }
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
