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
    /// Clear selections and start a new project?
    internal static let message = L10n.tr("Localizable", "ClearSelectionsAlert.message")
    /// Clear Selections
    internal static let title = L10n.tr("Localizable", "ClearSelectionsAlert.title")
  }

  internal enum CopyPhotoList {
    /// Copy %d photo(s) to another topic
    internal static func title(_ p1: Int) -> String {
      return L10n.tr("Localizable", "CopyPhotoList.title", p1)
    }
  }

  internal enum DeleteAllPhotosAlert {
    /// Delete all photos from your project?
    internal static let message = L10n.tr("Localizable", "DeleteAllPhotosAlert.message")
  }

  internal enum DeletePhotoAlert {
    /// Delete photo from your project?
    internal static let message = L10n.tr("Localizable", "DeletePhotoAlert.message")
  }

  internal enum DeletePhotosAlert {
    /// Delete %d photo(s) from your project?
    internal static func message(_ p1: Int) -> String {
      return L10n.tr("Localizable", "DeletePhotosAlert.message", p1)
    }
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
    internal enum TitlesTextPosition {
      /// Bottom
      internal static let bottom = L10n.tr("Localizable", "FormattingView.titlesTextPosition.bottom")
      /// Top
      internal static let top = L10n.tr("Localizable", "FormattingView.titlesTextPosition.top")
    }
  }

  internal enum FruitNames {
    /// apple
    internal static let apple = L10n.tr("Localizable", "FruitNames.apple")
    /// avocado
    internal static let avocado = L10n.tr("Localizable", "FruitNames.avocado")
    /// banana
    internal static let banana = L10n.tr("Localizable", "FruitNames.banana")
    /// blueberry
    internal static let blueberry = L10n.tr("Localizable", "FruitNames.blueberry")
    /// cherries
    internal static let cherry = L10n.tr("Localizable", "FruitNames.cherry")
    /// coconut
    internal static let coconut = L10n.tr("Localizable", "FruitNames.coconut")
    /// durian
    internal static let durian = L10n.tr("Localizable", "FruitNames.durian")
    /// fig
    internal static let fig = L10n.tr("Localizable", "FruitNames.fig")
    /// grapes
    internal static let grapes = L10n.tr("Localizable", "FruitNames.grapes")
    /// kiwi
    internal static let kiwi = L10n.tr("Localizable", "FruitNames.kiwi")
    /// lemon
    internal static let lemon = L10n.tr("Localizable", "FruitNames.lemon")
    /// mango
    internal static let mango = L10n.tr("Localizable", "FruitNames.mango")
    /// melon
    internal static let melon = L10n.tr("Localizable", "FruitNames.melon")
    /// papaya
    internal static let papaya = L10n.tr("Localizable", "FruitNames.papaya")
    /// peach
    internal static let peach = L10n.tr("Localizable", "FruitNames.peach")
    /// pear
    internal static let pear = L10n.tr("Localizable", "FruitNames.pear")
    /// pineapple
    internal static let pineapple = L10n.tr("Localizable", "FruitNames.pineapple")
    /// plum
    internal static let plum = L10n.tr("Localizable", "FruitNames.plum")
    /// pomegranate
    internal static let pomegranate = L10n.tr("Localizable", "FruitNames.pomegranate")
    /// raspberry
    internal static let raspberry = L10n.tr("Localizable", "FruitNames.raspberry")
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
    /// Change Selections
    internal static let changeSelectionsButton = L10n.tr("Localizable", "MainMenu.changeSelectionsButton")
    /// Choice Board
    internal static let choiceBoardButton = L10n.tr("Localizable", "MainMenu.choiceBoardButton")
    /// Clear Selections
    internal static let clearSelectionsButton = L10n.tr("Localizable", "MainMenu.clearSelectionsButton")
    /// More Apps
    internal static let moreAppsButton = L10n.tr("Localizable", "MainMenu.moreAppsButton")
    /// Edit
    internal static let pecsMakerButton = L10n.tr("Localizable", "MainMenu.pecsMakerButton")
    /// Preview and Print
    internal static let printButton = L10n.tr("Localizable", "MainMenu.printButton")
    /// Rename
    internal static let renameButton = L10n.tr("Localizable", "MainMenu.renameButton")
    /// Select Layout
    internal static let selectLayoutButton = L10n.tr("Localizable", "MainMenu.selectLayoutButton")
    /// Select Photos
    internal static let selectPhotosButton = L10n.tr("Localizable", "MainMenu.selectPhotosButton")
    /// Settings
    internal static let settingsButton = L10n.tr("Localizable", "MainMenu.settingsButton")
  }

  internal enum NoPhotosView {
    /// Add Photos
    internal static let addPhotosButton = L10n.tr("Localizable", "NoPhotosView.addPhotosButton")
    /// Get your project started by adding some photos.
    internal static let message = L10n.tr("Localizable", "NoPhotosView.message")
  }

  internal enum OrientationSelectionView {
    /// Orientation
    internal static let title = L10n.tr("Localizable", "OrientationSelectionView.title")
  }

  internal enum PageSizeSelectionView {
    /// Paper Size
    internal static let title = L10n.tr("Localizable", "PageSizeSelectionView.title")
  }

  internal enum PhotoSelectionView {
    /// Add Photos
    internal static let addMorePhotosButton = L10n.tr("Localizable", "PhotoSelectionView.addMorePhotosButton")
    /// Crop selected photos
    internal static let autoCropButton = L10n.tr("Localizable", "PhotoSelectionView.autoCropButton")
    /// Copy selected photos
    internal static let copyButton = L10n.tr("Localizable", "PhotoSelectionView.copyButton")
    /// Crop
    internal static let cropButton = L10n.tr("Localizable", "PhotoSelectionView.cropButton")
    /// Delete All
    internal static let deleteAllButton = L10n.tr("Localizable", "PhotoSelectionView.deleteAllButton")
    /// Delete selected photos
    internal static let deleteButton = L10n.tr("Localizable", "PhotoSelectionView.deleteButton")
    /// Deselect All
    internal static let deselectAllButton = L10n.tr("Localizable", "PhotoSelectionView.deselectAllButton")
    /// Duplicate selected photos
    internal static let duplicateButton = L10n.tr("Localizable", "PhotoSelectionView.duplicateButton")
    /// Erase Background
    internal static let eraseBackgroundButton = L10n.tr("Localizable", "PhotoSelectionView.eraseBackgroundButton")
    /// %d Photos
    internal static func photoCountLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "PhotoSelectionView.photoCountLabel", p1)
    }
    /// Revert
    internal static let revertButton = L10n.tr("Localizable", "PhotoSelectionView.revertButton")
    /// Save
    internal static let saveButton = L10n.tr("Localizable", "PhotoSelectionView.saveButton")
    /// Select All
    internal static let selectAllButton = L10n.tr("Localizable", "PhotoSelectionView.selectAllButton")
    /// (%d Photos Selected)
    internal static func selectedPhotoCountLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "PhotoSelectionView.selectedPhotoCountLabel", p1)
    }
    /// Selected Photos
    internal static let title = L10n.tr("Localizable", "PhotoSelectionView.title")
    /// [Untitled]
    internal static let untitledCell = L10n.tr("Localizable", "PhotoSelectionView.untitledCell")
    internal enum CopyPhotosSuccessAlert {
      /// Photo(s) Copied
      internal static let title = L10n.tr("Localizable", "PhotoSelectionView.CopyPhotosSuccessAlert.title")
    }
  }

  internal enum PreviewPage {
    /// Formatting
    internal static let formattingButton = L10n.tr("Localizable", "PreviewPage.formattingButton")
    /// Repeat Image
    internal static let repeatButton = L10n.tr("Localizable", "PreviewPage.repeatButton")
    /// Print
    internal static let saveButton = L10n.tr("Localizable", "PreviewPage.saveButton")
    /// Save to Photo Library
    internal static let saveImageButton = L10n.tr("Localizable", "PreviewPage.saveImageButton")
    /// Preview
    internal static let title = L10n.tr("Localizable", "PreviewPage.title")
    internal enum SuccessAlert {
      /// PECS design saved to your files.
      internal static let fileSaved = L10n.tr("Localizable", "PreviewPage.SuccessAlert.FileSaved")
      /// PECS design saved to your photo library.
      internal static let photoSaved = L10n.tr("Localizable", "PreviewPage.SuccessAlert.PhotoSaved")
      /// PECS design sent to the printer.
      internal static let print = L10n.tr("Localizable", "PreviewPage.SuccessAlert.Print")
    }
  }

  internal enum RenamePhotoAlert {
    /// Photo title
    internal static let placeholder = L10n.tr("Localizable", "RenamePhotoAlert.placeholder")
    /// Rename Photo
    internal static let title = L10n.tr("Localizable", "RenamePhotoAlert.title")
  }

  internal enum RenameTopicAlert {
    /// Topic title
    internal static let placeholder = L10n.tr("Localizable", "RenameTopicAlert.placeholder")
    /// Rename Topic
    internal static let title = L10n.tr("Localizable", "RenameTopicAlert.title")
  }

  internal enum Repo {
    /// New Topic
    internal static let defaultTopicTitle = L10n.tr("Localizable", "Repo.defaultTopicTitle")
  }

  internal enum Settings {
    /// We welcome your feedback and bug reports. Please email them to:
    /// %@
    internal static func feedbackMessageNoEmail(_ p1: Any) -> String {
      return L10n.tr("Localizable", "Settings.FeedbackMessageNoEmail", String(describing: p1))
    }
    internal enum BugReportEmail {
      /// Found a problem with the app? Please describe it...
      internal static let body = L10n.tr("Localizable", "Settings.BugReportEmail.body")
      /// Bug report for %@ version %@
      internal static func subject(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "Settings.BugReportEmail.subject", String(describing: p1), String(describing: p2))
      }
    }
    internal enum FeatureRequestEmail {
      /// Got an idea to improve the app? Please type it below...
      internal static let body = L10n.tr("Localizable", "Settings.FeatureRequestEmail.body")
      /// Feature request for %@ version %@
      internal static func subject(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "Settings.FeatureRequestEmail.subject", String(describing: p1), String(describing: p2))
      }
    }
    internal enum SendLogsEmail {
      /// Thank you for taking the time to provide feedback.
      /// 
      /// The content below is diagnostic information that will help with troubleshooting and improving the app. No personal data will be sent.
      /// 
      /// 
      internal static let body = L10n.tr("Localizable", "Settings.SendLogsEmail.body")
      /// Log info for %@ version %@
      internal static func subject(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "Settings.SendLogsEmail.subject", String(describing: p1), String(describing: p2))
      }
    }
  }

  internal enum SettingsPage {
    /// Settings
    internal static let title = L10n.tr("Localizable", "SettingsPage.title")
  }

  internal enum SettingsView {
    /// Diagnostics
    internal static let diagnosticsButton = L10n.tr("Localizable", "SettingsView.diagnosticsButton")
    /// Reset Feature Voting
    internal static let resetVotingButton = L10n.tr("Localizable", "SettingsView.resetVotingButton")
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

  internal enum TopicContextMenu {
    /// Delete
    internal static let deleteButton = L10n.tr("Localizable", "TopicContextMenu.deleteButton")
    /// Duplicate
    internal static let duplicate = L10n.tr("Localizable", "TopicContextMenu.duplicate")
    /// Edit
    internal static let editButton = L10n.tr("Localizable", "TopicContextMenu.editButton")
    /// Rename
    internal static let renameButton = L10n.tr("Localizable", "TopicContextMenu.renameButton")
    /// View
    internal static let viewButton = L10n.tr("Localizable", "TopicContextMenu.viewButton")
  }

  internal enum TopicSelectionView {
    /// New Topic
    internal static let createDesignButton = L10n.tr("Localizable", "TopicSelectionView.createDesignButton")
    /// Done
    internal static let doneButton = L10n.tr("Localizable", "TopicSelectionView.doneButton")
    /// Edit
    internal static let editButton = L10n.tr("Localizable", "TopicSelectionView.editButton")
    /// Maximize Sidebar
    internal static let maximizeButton = L10n.tr("Localizable", "TopicSelectionView.maximizeButton")
    /// Tap New Topic to get started.
    internal static let noTopicsMessage = L10n.tr("Localizable", "TopicSelectionView.noTopicsMessage")
    /// Topics
    internal static let title = L10n.tr("Localizable", "TopicSelectionView.title")
    /// Delete %@
    internal static func topicDeleteButton(_ p1: Any) -> String {
      return L10n.tr("Localizable", "TopicSelectionView.topicDeleteButton", String(describing: p1))
    }
    internal enum DeleteTopicAlert {
      /// Delete %@?
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "TopicSelectionView.DeleteTopicAlert.message", String(describing: p1))
      }
      /// Delete Topic
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
