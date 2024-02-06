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
    /// Copy %d photo(s) to another topic
    internal static func title(_ p1: Int) -> String {
      return L10n.tr("Localizable", "CopyPhotoList.title", p1, fallback: "Copy %d photo(s) to another topic")
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
    /// Big
    internal static let labelBig = L10n.tr("Localizable", "FormattingView.labelBig", fallback: "Big")
    /// Label size
    internal static let labelSectionTitle = L10n.tr("Localizable", "FormattingView.labelSectionTitle", fallback: "Label size")
    /// Small
    internal static let labelSmall = L10n.tr("Localizable", "FormattingView.labelSmall", fallback: "Small")
    /// Big
    internal static let marginBig = L10n.tr("Localizable", "FormattingView.marginBig", fallback: "Big")
    /// Margins
    internal static let marginSectionTitle = L10n.tr("Localizable", "FormattingView.marginSectionTitle", fallback: "Margins")
    /// Small
    internal static let marginSmall = L10n.tr("Localizable", "FormattingView.marginSmall", fallback: "Small")
    /// Formatting
    internal static let title = L10n.tr("Localizable", "FormattingView.title", fallback: "Formatting")
    /// Bold font
    internal static let titlesBoldFontOption = L10n.tr("Localizable", "FormattingView.titlesBoldFontOption", fallback: "Bold font")
    /// Titles
    internal static let titlesSectionTitle = L10n.tr("Localizable", "FormattingView.titlesSectionTitle", fallback: "Titles")
    /// Text colour
    internal static let titlesTextColor = L10n.tr("Localizable", "FormattingView.titlesTextColor", fallback: "Text colour")
    /// Position
    internal static let titlesTextPosition = L10n.tr("Localizable", "FormattingView.titlesTextPosition", fallback: "Position")
    internal enum TitlesTextPosition {
      /// Bottom
      internal static let bottom = L10n.tr("Localizable", "FormattingView.titlesTextPosition.bottom", fallback: "Bottom")
      /// Top
      internal static let top = L10n.tr("Localizable", "FormattingView.titlesTextPosition.top", fallback: "Top")
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
    /// Number of PECS cards per page:
    internal static let cardCount = L10n.tr("Localizable", "LayoutSummaryView.cardCount", fallback: "Number of PECS cards per page:")
    /// %d across by %d down
    internal static func cardsAcrossAndDown(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "LayoutSummaryView.cardsAcrossAndDown", p1, p2, fallback: "%d across by %d down")
    }
    /// Each PECS card measures:
    internal static let cardSizeTitle = L10n.tr("Localizable", "LayoutSummaryView.cardSizeTitle", fallback: "Each PECS card measures:")
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
    /// Clear Selections
    internal static let clearSelectionsButton = L10n.tr("Localizable", "MainMenu.clearSelectionsButton", fallback: "Clear Selections")
    /// More Apps
    internal static let moreAppsButton = L10n.tr("Localizable", "MainMenu.moreAppsButton", fallback: "More Apps")
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
  internal enum PageSizeSelectionView {
    /// Paper Size
    internal static let title = L10n.tr("Localizable", "PageSizeSelectionView.title", fallback: "Paper Size")
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
      /// PECS design saved to your files.
      internal static let fileSaved = L10n.tr("Localizable", "PreviewPage.SuccessAlert.FileSaved", fallback: "PECS design saved to your files.")
      /// PECS design saved to your photo library.
      internal static let photoSaved = L10n.tr("Localizable", "PreviewPage.SuccessAlert.PhotoSaved", fallback: "PECS design saved to your photo library.")
      /// PECS design sent to the printer.
      internal static let print = L10n.tr("Localizable", "PreviewPage.SuccessAlert.Print", fallback: "PECS design sent to the printer.")
    }
  }
  internal enum RenamePhotoAlert {
    /// Photo title
    internal static let placeholder = L10n.tr("Localizable", "RenamePhotoAlert.placeholder", fallback: "Photo title")
    /// Rename Photo
    internal static let title = L10n.tr("Localizable", "RenamePhotoAlert.title", fallback: "Rename Photo")
  }
  internal enum RenameTopicAlert {
    /// Project title
    internal static let placeholder = L10n.tr("Localizable", "RenameTopicAlert.placeholder", fallback: "Project title")
    /// Rename Project
    internal static let title = L10n.tr("Localizable", "RenameTopicAlert.title", fallback: "Rename Project")
  }
  internal enum Repo {
    /// New Project
    internal static let defaultTopicTitle = L10n.tr("Localizable", "Repo.defaultTopicTitle", fallback: "New Project")
  }
  internal enum SettingsPage {
    /// Settings
    internal static let title = L10n.tr("Localizable", "SettingsPage.title", fallback: "Settings")
  }
  internal enum SettingsView {
    /// Diagnostics
    internal static let diagnosticsButton = L10n.tr("Localizable", "SettingsView.diagnosticsButton", fallback: "Diagnostics")
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
  internal enum TopicSelectionView {
    /// New Project
    internal static let createDesignButton = L10n.tr("Localizable", "TopicSelectionView.createDesignButton", fallback: "New Project")
    /// Done
    internal static let doneButton = L10n.tr("Localizable", "TopicSelectionView.doneButton", fallback: "Done")
    /// Edit
    internal static let editButton = L10n.tr("Localizable", "TopicSelectionView.editButton", fallback: "Edit")
    /// Maximize Sidebar
    internal static let maximizeButton = L10n.tr("Localizable", "TopicSelectionView.maximizeButton", fallback: "Maximize Sidebar")
    /// Click New Project to create a new PECS template.
    internal static let noTopicsMessage = L10n.tr("Localizable", "TopicSelectionView.noTopicsMessage", fallback: "Click New Project to create a new PECS template.")
    /// My Projects
    internal static let title = L10n.tr("Localizable", "TopicSelectionView.title", fallback: "My Projects")
    /// Delete %@
    internal static func topicDeleteButton(_ p1: Any) -> String {
      return L10n.tr("Localizable", "TopicSelectionView.topicDeleteButton", String(describing: p1), fallback: "Delete %@")
    }
    internal enum DeleteTopicAlert {
      /// Delete %@?
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "TopicSelectionView.DeleteTopicAlert.message", String(describing: p1), fallback: "Delete %@?")
      }
      /// Delete Project
      internal static let title = L10n.tr("Localizable", "TopicSelectionView.DeleteTopicAlert.title", fallback: "Delete Project")
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
