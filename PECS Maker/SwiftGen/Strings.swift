// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Done
  internal static let doneButton = L10n.tr("Localizable", "DoneButton", fallback: "Done")
  internal enum ClearSelectionsAlert {
    /// Clear selections and start a new project?
    internal static let message = L10n.tr("Localizable", "ClearSelectionsAlert.message", fallback: "Clear selections and start a new project?")
    /// Clear Selections
    internal static let title = L10n.tr("Localizable", "ClearSelectionsAlert.title", fallback: "Clear Selections")
  }
  internal enum CopyPhotoList {
    /// Copy %d photo(s) to another board
    internal static func title(_ p1: Int) -> String {
      return L10n.tr("Localizable", "CopyPhotoList.title", p1, fallback: "Copy %d photo(s) to another board")
    }
  }
  internal enum DeleteAllPhotosAlert {
    /// Delete all photos from your project?
    internal static let message = L10n.tr("Localizable", "DeleteAllPhotosAlert.message", fallback: "Delete all photos from your project?")
  }
  internal enum DeletePhotoAlert {
    /// Delete photo from your project?
    internal static let message = L10n.tr("Localizable", "DeletePhotoAlert.message", fallback: "Delete photo from your project?")
  }
  internal enum DeletePhotosAlert {
    /// Delete %d photo(s) from your project?
    internal static func message(_ p1: Int) -> String {
      return L10n.tr("Localizable", "DeletePhotosAlert.message", p1, fallback: "Delete %d photo(s) from your project?")
    }
  }
  internal enum FitzgeraldKey {
    /// Adjective
    internal static let adjective = L10n.tr("Localizable", "FitzgeraldKey.adjective", fallback: "Adjective")
    /// Adverb
    internal static let adverb = L10n.tr("Localizable", "FitzgeraldKey.adverb", fallback: "Adverb")
    /// Conjunction
    internal static let conjunction = L10n.tr("Localizable", "FitzgeraldKey.conjunction", fallback: "Conjunction")
    /// Determiner
    internal static let determiner = L10n.tr("Localizable", "FitzgeraldKey.determiner", fallback: "Determiner")
    /// Important
    internal static let important = L10n.tr("Localizable", "FitzgeraldKey.important", fallback: "Important")
    /// No Fitzgerald Key
    internal static let `none` = L10n.tr("Localizable", "FitzgeraldKey.none", fallback: "No Fitzgerald Key")
    /// Noun
    internal static let noun = L10n.tr("Localizable", "FitzgeraldKey.noun", fallback: "Noun")
    /// Preposition
    internal static let preposition = L10n.tr("Localizable", "FitzgeraldKey.preposition", fallback: "Preposition")
    /// Pronoun
    internal static let pronoun = L10n.tr("Localizable", "FitzgeraldKey.pronoun", fallback: "Pronoun")
    /// Question
    internal static let question = L10n.tr("Localizable", "FitzgeraldKey.question", fallback: "Question")
    /// Verb
    internal static let verb = L10n.tr("Localizable", "FitzgeraldKey.verb", fallback: "Verb")
  }
  internal enum FormattingView {
    /// Background colour
    internal static let cellBackgroundColour = L10n.tr("Localizable", "FormattingView.cellBackgroundColour", fallback: "Background colour")
    /// Background
    internal static let cellBackgroundTitle = L10n.tr("Localizable", "FormattingView.cellBackgroundTitle", fallback: "Background")
    /// Fitzgerald Keys
    internal static let fitzgeraldKeysSectionTitle = L10n.tr("Localizable", "FormattingView.fitzgeraldKeysSectionTitle", fallback: "Fitzgerald Keys")
    /// Thicker borders
    internal static let fitzgeraldKeysThickerBorders = L10n.tr("Localizable", "FormattingView.fitzgeraldKeysThickerBorders", fallback: "Thicker borders")
    /// Grid colour
    internal static let gridlinesColour = L10n.tr("Localizable", "FormattingView.gridlinesColour", fallback: "Grid colour")
    /// Gridlines
    internal static let gridlinesSectionTitle = L10n.tr("Localizable", "FormattingView.gridlinesSectionTitle", fallback: "Gridlines")
    /// Thicker gridlines
    internal static let gridlinesThicker = L10n.tr("Localizable", "FormattingView.gridlinesThicker", fallback: "Thicker gridlines")
    /// Large
    internal static let marginLarge = L10n.tr("Localizable", "FormattingView.marginLarge", fallback: "Large")
    /// Margins
    internal static let marginSectionTitle = L10n.tr("Localizable", "FormattingView.marginSectionTitle", fallback: "Margins")
    /// Small
    internal static let marginSmall = L10n.tr("Localizable", "FormattingView.marginSmall", fallback: "Small")
    /// Formatting
    internal static let title = L10n.tr("Localizable", "FormattingView.title", fallback: "Formatting")
    internal enum BoardSection {
      /// Show board title
      internal static let showTitle = L10n.tr("Localizable", "FormattingView.boardSection.showTitle", fallback: "Show board title")
      /// Board Title
      internal static let title = L10n.tr("Localizable", "FormattingView.boardSection.title", fallback: "Board Title")
    }
    internal enum CardSection {
      /// Card Titles
      internal static let title = L10n.tr("Localizable", "FormattingView.cardSection.title", fallback: "Card Titles")
    }
    internal enum Font {
      /// Bold font
      internal static let bold = L10n.tr("Localizable", "FormattingView.font.bold", fallback: "Bold font")
      /// Text colour
      internal static let color = L10n.tr("Localizable", "FormattingView.font.color", fallback: "Text colour")
      internal enum Size {
        /// Large
        internal static let large = L10n.tr("Localizable", "FormattingView.font.size.large", fallback: "Large")
        /// Small
        internal static let small = L10n.tr("Localizable", "FormattingView.font.size.small", fallback: "Small")
      }
    }
    internal enum TextPosition {
      /// Bottom
      internal static let bottom = L10n.tr("Localizable", "FormattingView.textPosition.bottom", fallback: "Bottom")
      /// Position
      internal static let title = L10n.tr("Localizable", "FormattingView.textPosition.title", fallback: "Position")
      /// Top
      internal static let top = L10n.tr("Localizable", "FormattingView.textPosition.top", fallback: "Top")
    }
  }
  internal enum FruitNames {
    /// apple
    internal static let apple = L10n.tr("Localizable", "FruitNames.apple", fallback: "apple")
    /// avocado
    internal static let avocado = L10n.tr("Localizable", "FruitNames.avocado", fallback: "avocado")
    /// banana
    internal static let banana = L10n.tr("Localizable", "FruitNames.banana", fallback: "banana")
    /// blueberry
    internal static let blueberry = L10n.tr("Localizable", "FruitNames.blueberry", fallback: "blueberry")
    /// cherries
    internal static let cherry = L10n.tr("Localizable", "FruitNames.cherry", fallback: "cherries")
    /// coconut
    internal static let coconut = L10n.tr("Localizable", "FruitNames.coconut", fallback: "coconut")
    /// durian
    internal static let durian = L10n.tr("Localizable", "FruitNames.durian", fallback: "durian")
    /// fig
    internal static let fig = L10n.tr("Localizable", "FruitNames.fig", fallback: "fig")
    /// grapes
    internal static let grapes = L10n.tr("Localizable", "FruitNames.grapes", fallback: "grapes")
    /// kiwi
    internal static let kiwi = L10n.tr("Localizable", "FruitNames.kiwi", fallback: "kiwi")
    /// lemon
    internal static let lemon = L10n.tr("Localizable", "FruitNames.lemon", fallback: "lemon")
    /// mango
    internal static let mango = L10n.tr("Localizable", "FruitNames.mango", fallback: "mango")
    /// melon
    internal static let melon = L10n.tr("Localizable", "FruitNames.melon", fallback: "melon")
    /// papaya
    internal static let papaya = L10n.tr("Localizable", "FruitNames.papaya", fallback: "papaya")
    /// peach
    internal static let peach = L10n.tr("Localizable", "FruitNames.peach", fallback: "peach")
    /// pear
    internal static let pear = L10n.tr("Localizable", "FruitNames.pear", fallback: "pear")
    /// pineapple
    internal static let pineapple = L10n.tr("Localizable", "FruitNames.pineapple", fallback: "pineapple")
    /// plum
    internal static let plum = L10n.tr("Localizable", "FruitNames.plum", fallback: "plum")
    /// pomegranate
    internal static let pomegranate = L10n.tr("Localizable", "FruitNames.pomegranate", fallback: "pomegranate")
    /// raspberry
    internal static let raspberry = L10n.tr("Localizable", "FruitNames.raspberry", fallback: "raspberry")
    /// strawberry
    internal static let strawberry = L10n.tr("Localizable", "FruitNames.strawberry", fallback: "strawberry")
    /// strawberry
    internal static let watermelon = L10n.tr("Localizable", "FruitNames.watermelon", fallback: "strawberry")
  }
  internal enum LayoutScreen {
    /// Done
    internal static let doneButton = L10n.tr("Localizable", "LayoutScreen.doneButton", fallback: "Done")
    /// Layout
    internal static let title = L10n.tr("Localizable", "LayoutScreen.title", fallback: "Layout")
  }
  internal enum LayoutSelectionView {
    /// Layout
    internal static let title = L10n.tr("Localizable", "LayoutSelectionView.title", fallback: "Layout")
  }
  internal enum LayoutSummaryView {
    /// Aspect ratio:
    internal static let aspectRatio = L10n.tr("Localizable", "LayoutSummaryView.aspectRatio", fallback: "Aspect ratio:")
    /// Number of cards per page:
    internal static let cardCount = L10n.tr("Localizable", "LayoutSummaryView.cardCount", fallback: "Number of cards per page:")
    /// %d across by %d down
    internal static func cardsAcrossAndDown(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "LayoutSummaryView.cardsAcrossAndDown", p1, p2, fallback: "%d across by %d down")
    }
    /// Each card measures:
    internal static let cardSizeTitle = L10n.tr("Localizable", "LayoutSummaryView.cardSizeTitle", fallback: "Each card measures:")
    /// Page measurements:
    internal static let pageMeasurements = L10n.tr("Localizable", "LayoutSummaryView.pageMeasurements", fallback: "Page measurements:")
    /// Summary
    internal static let title = L10n.tr("Localizable", "LayoutSummaryView.title", fallback: "Summary")
  }
  internal enum MainMenu {
    /// Add Titles
    internal static let addTitlesButton = L10n.tr("Localizable", "MainMenu.addTitlesButton", fallback: "Add Titles")
    /// Change Selections
    internal static let changeSelectionsButton = L10n.tr("Localizable", "MainMenu.changeSelectionsButton", fallback: "Change Selections")
    /// Change Image
    internal static let changeTopicImageButton = L10n.tr("Localizable", "MainMenu.changeTopicImageButton", fallback: "Change Image")
    /// Choice Board
    internal static let choiceBoardButton = L10n.tr("Localizable", "MainMenu.choiceBoardButton", fallback: "Choice Board")
    /// Clear Selections
    internal static let clearSelectionsButton = L10n.tr("Localizable", "MainMenu.clearSelectionsButton", fallback: "Clear Selections")
    /// More Apps
    internal static let moreAppsButton = L10n.tr("Localizable", "MainMenu.moreAppsButton", fallback: "More Apps")
    /// Design Mode
    internal static let pecsMakerButton = L10n.tr("Localizable", "MainMenu.pecsMakerButton", fallback: "Design Mode")
    /// Preview and Print
    internal static let printButton = L10n.tr("Localizable", "MainMenu.printButton", fallback: "Preview and Print")
    /// Rename
    internal static let renameButton = L10n.tr("Localizable", "MainMenu.renameButton", fallback: "Rename")
    /// Select Layout
    internal static let selectLayoutButton = L10n.tr("Localizable", "MainMenu.selectLayoutButton", fallback: "Select Layout")
    /// Select Photos
    internal static let selectPhotosButton = L10n.tr("Localizable", "MainMenu.selectPhotosButton", fallback: "Select Photos")
    /// Settings
    internal static let settingsButton = L10n.tr("Localizable", "MainMenu.settingsButton", fallback: "Settings")
  }
  internal enum NoPhotosView {
    /// Add Photos
    internal static let addPhotosButton = L10n.tr("Localizable", "NoPhotosView.addPhotosButton", fallback: "Add Photos")
    /// Get your project started by adding some photos.
    internal static let message = L10n.tr("Localizable", "NoPhotosView.message", fallback: "Get your project started by adding some photos.")
  }
  internal enum OrientationSelectionView {
    /// Orientation
    internal static let title = L10n.tr("Localizable", "OrientationSelectionView.title", fallback: "Orientation")
  }
  internal enum PageSize {
    /// 10x15 (Photo)
    internal static let photo10by15 = L10n.tr("Localizable", "PageSize.photo10by15", fallback: "10x15 (Photo)")
  }
  internal enum PageSizeSelectionView {
    /// Paper Size
    internal static let title = L10n.tr("Localizable", "PageSizeSelectionView.title", fallback: "Paper Size")
  }
  internal enum PhotoContextMenu {
    /// Delete
    internal static let deleteButton = L10n.tr("Localizable", "PhotoContextMenu.deleteButton", fallback: "Delete")
    /// Duplicate
    internal static let duplicate = L10n.tr("Localizable", "PhotoContextMenu.duplicate", fallback: "Duplicate")
    /// Edit
    internal static let editButton = L10n.tr("Localizable", "PhotoContextMenu.editButton", fallback: "Edit")
    /// Change Title
    internal static let renameButton = L10n.tr("Localizable", "PhotoContextMenu.renameButton", fallback: "Change Title")
  }
  internal enum PhotoSelectionView {
    /// Add Photos
    internal static let addMorePhotosButton = L10n.tr("Localizable", "PhotoSelectionView.addMorePhotosButton", fallback: "Add Photos")
    /// Crop selected photos
    internal static let autoCropButton = L10n.tr("Localizable", "PhotoSelectionView.autoCropButton", fallback: "Crop selected photos")
    /// Copy selected photos
    internal static let copyButton = L10n.tr("Localizable", "PhotoSelectionView.copyButton", fallback: "Copy selected photos")
    /// Delete All
    internal static let deleteAllButton = L10n.tr("Localizable", "PhotoSelectionView.deleteAllButton", fallback: "Delete All")
    /// Delete selected photos
    internal static let deleteButton = L10n.tr("Localizable", "PhotoSelectionView.deleteButton", fallback: "Delete selected photos")
    /// Deselect All
    internal static let deselectAllButton = L10n.tr("Localizable", "PhotoSelectionView.deselectAllButton", fallback: "Deselect All")
    /// Duplicate selected photos
    internal static let duplicateButton = L10n.tr("Localizable", "PhotoSelectionView.duplicateButton", fallback: "Duplicate selected photos")
    /// %d Photos
    internal static func photoCountLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "PhotoSelectionView.photoCountLabel", p1, fallback: "%d Photos")
    }
    /// Select All
    internal static let selectAllButton = L10n.tr("Localizable", "PhotoSelectionView.selectAllButton", fallback: "Select All")
    /// (%d Photos Selected)
    internal static func selectedPhotoCountLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "PhotoSelectionView.selectedPhotoCountLabel", p1, fallback: "(%d Photos Selected)")
    }
    /// Selected Photos
    internal static let title = L10n.tr("Localizable", "PhotoSelectionView.title", fallback: "Selected Photos")
    /// [Untitled]
    internal static let untitledCell = L10n.tr("Localizable", "PhotoSelectionView.untitledCell", fallback: "[Untitled]")
    internal enum CopyPhotosSuccessAlert {
      /// Photo(s) Copied
      internal static let title = L10n.tr("Localizable", "PhotoSelectionView.CopyPhotosSuccessAlert.title", fallback: "Photo(s) Copied")
    }
  }
  internal enum PhotoZoomView {
    /// Close
    internal static let closeButton = L10n.tr("Localizable", "PhotoZoomView.closeButton", fallback: "Close")
    /// Crop
    internal static let cropButton = L10n.tr("Localizable", "PhotoZoomView.cropButton", fallback: "Crop")
    /// Erase Background
    internal static let eraseBackgroundButton = L10n.tr("Localizable", "PhotoZoomView.eraseBackgroundButton", fallback: "Erase Background")
    /// Revert
    internal static let revertButton = L10n.tr("Localizable", "PhotoZoomView.revertButton", fallback: "Revert")
    /// Save
    internal static let saveButton = L10n.tr("Localizable", "PhotoZoomView.saveButton", fallback: "Save")
  }
  internal enum PreviewPage {
    /// Formatting
    internal static let formattingButton = L10n.tr("Localizable", "PreviewPage.formattingButton", fallback: "Formatting")
    /// Repeat Image
    internal static let repeatButton = L10n.tr("Localizable", "PreviewPage.repeatButton", fallback: "Repeat Image")
    /// Print
    internal static let saveButton = L10n.tr("Localizable", "PreviewPage.saveButton", fallback: "Print")
    /// Save to Photo Library
    internal static let saveImageButton = L10n.tr("Localizable", "PreviewPage.saveImageButton", fallback: "Save to Photo Library")
    /// Preview
    internal static let title = L10n.tr("Localizable", "PreviewPage.title", fallback: "Preview")
    internal enum SuccessAlert {
      /// Board saved to your files.
      internal static let fileSaved = L10n.tr("Localizable", "PreviewPage.SuccessAlert.FileSaved", fallback: "Board saved to your files.")
      /// Board saved to your photo library.
      internal static let photoSaved = L10n.tr("Localizable", "PreviewPage.SuccessAlert.PhotoSaved", fallback: "Board saved to your photo library.")
      /// Board sent to the printer.
      internal static let print = L10n.tr("Localizable", "PreviewPage.SuccessAlert.Print", fallback: "Board sent to the printer.")
    }
  }
  internal enum RenamePhotoAlert {
    /// Photo title
    internal static let placeholder = L10n.tr("Localizable", "RenamePhotoAlert.placeholder", fallback: "Photo title")
    /// Rename Photo
    internal static let title = L10n.tr("Localizable", "RenamePhotoAlert.title", fallback: "Rename Photo")
  }
  internal enum RenameTopicAlert {
    /// Board title
    internal static let placeholder = L10n.tr("Localizable", "RenameTopicAlert.placeholder", fallback: "Board title")
    /// Rename Board
    internal static let title = L10n.tr("Localizable", "RenameTopicAlert.title", fallback: "Rename Board")
  }
  internal enum Repo {
    /// New Board
    internal static let defaultTopicTitle = L10n.tr("Localizable", "Repo.defaultTopicTitle", fallback: "New Board")
  }
  internal enum Settings {
    /// We welcome your feedback and bug reports. Please email them to:
    /// %@
    internal static func feedbackMessageNoEmail(_ p1: Any) -> String {
      return L10n.tr("Localizable", "Settings.FeedbackMessageNoEmail", String(describing: p1), fallback: "We welcome your feedback and bug reports. Please email them to:\n%@")
    }
    internal enum BugReportEmail {
      /// Found a problem with the app? Please describe it...
      internal static let body = L10n.tr("Localizable", "Settings.BugReportEmail.body", fallback: "Found a problem with the app? Please describe it...")
      /// Bug report for %@ version %@
      internal static func subject(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "Settings.BugReportEmail.subject", String(describing: p1), String(describing: p2), fallback: "Bug report for %@ version %@")
      }
    }
    internal enum FeatureRequestEmail {
      /// Got an idea to improve the app? Please type it below...
      internal static let body = L10n.tr("Localizable", "Settings.FeatureRequestEmail.body", fallback: "Got an idea to improve the app? Please type it below...")
      /// Feature request for %@ version %@
      internal static func subject(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "Settings.FeatureRequestEmail.subject", String(describing: p1), String(describing: p2), fallback: "Feature request for %@ version %@")
      }
    }
    internal enum SendLogsEmail {
      /// Thank you for taking the time to provide feedback.
      /// 
      /// The content below is diagnostic information that will help with troubleshooting and improving the app. No personal data will be sent.
      /// 
      /// 
      internal static let body = L10n.tr("Localizable", "Settings.SendLogsEmail.body", fallback: "Thank you for taking the time to provide feedback.\n\nThe content below is diagnostic information that will help with troubleshooting and improving the app. No personal data will be sent.\n\n")
      /// Log info for %@ version %@
      internal static func subject(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "Settings.SendLogsEmail.subject", String(describing: p1), String(describing: p2), fallback: "Log info for %@ version %@")
      }
    }
  }
  internal enum SettingsPage {
    /// Settings
    internal static let title = L10n.tr("Localizable", "SettingsPage.title", fallback: "Settings")
  }
  internal enum SettingsView {
    /// Diagnostics
    internal static let diagnosticsButton = L10n.tr("Localizable", "SettingsView.diagnosticsButton", fallback: "Diagnostics")
    /// Reset Feature Voting
    internal static let resetVotingButton = L10n.tr("Localizable", "SettingsView.resetVotingButton", fallback: "Reset Feature Voting")
  }
  internal enum TitlesPage {
    /// Titles
    internal static let title = L10n.tr("Localizable", "TitlesPage.title", fallback: "Titles")
    /// Title
    internal static let titleTextPlaceholder = L10n.tr("Localizable", "TitlesPage.titleTextPlaceholder", fallback: "Title")
  }
  internal enum TitlesScreen {
    /// Select some photos and then come back to this screen to enter their titles.
    internal static let noPhotosMessage = L10n.tr("Localizable", "TitlesScreen.noPhotosMessage", fallback: "Select some photos and then come back to this screen to enter their titles.")
  }
  internal enum TopicContextMenu {
    /// Change Image
    internal static let changeTopicImageButton = L10n.tr("Localizable", "TopicContextMenu.changeTopicImageButton", fallback: "Change Image")
    /// Delete
    internal static let deleteButton = L10n.tr("Localizable", "TopicContextMenu.deleteButton", fallback: "Delete")
    /// Duplicate
    internal static let duplicate = L10n.tr("Localizable", "TopicContextMenu.duplicate", fallback: "Duplicate")
    /// Edit
    internal static let editButton = L10n.tr("Localizable", "TopicContextMenu.editButton", fallback: "Edit")
    /// Rename
    internal static let renameButton = L10n.tr("Localizable", "TopicContextMenu.renameButton", fallback: "Rename")
    /// View
    internal static let viewButton = L10n.tr("Localizable", "TopicContextMenu.viewButton", fallback: "View")
  }
  internal enum TopicImageSelector {
    /// Change Board Icon
    internal static let title = L10n.tr("Localizable", "TopicImageSelector.title", fallback: "Change Board Icon")
  }
  internal enum TopicSelectionView {
    /// New Board
    internal static let createDesignButton = L10n.tr("Localizable", "TopicSelectionView.createDesignButton", fallback: "New Board")
    /// Done
    internal static let doneButton = L10n.tr("Localizable", "TopicSelectionView.doneButton", fallback: "Done")
    /// Edit
    internal static let editButton = L10n.tr("Localizable", "TopicSelectionView.editButton", fallback: "Edit")
    /// Maximize Sidebar
    internal static let maximizeButton = L10n.tr("Localizable", "TopicSelectionView.maximizeButton", fallback: "Maximize Sidebar")
    /// Tap New Board to get started.
    internal static let noTopicsMessage = L10n.tr("Localizable", "TopicSelectionView.noTopicsMessage", fallback: "Tap New Board to get started.")
    /// Boards
    internal static let title = L10n.tr("Localizable", "TopicSelectionView.title", fallback: "Boards")
    /// Delete %@
    internal static func topicDeleteButton(_ p1: Any) -> String {
      return L10n.tr("Localizable", "TopicSelectionView.topicDeleteButton", String(describing: p1), fallback: "Delete %@")
    }
    internal enum DeleteTopicAlert {
      /// Delete %@?
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "TopicSelectionView.DeleteTopicAlert.message", String(describing: p1), fallback: "Delete %@?")
      }
      /// Delete Board
      internal static let title = L10n.tr("Localizable", "TopicSelectionView.DeleteTopicAlert.title", fallback: "Delete Board")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
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
