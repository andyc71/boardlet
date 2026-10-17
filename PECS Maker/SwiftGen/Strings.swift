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
  internal enum Attribution {
    /// Symbols: AAC Standard · © aisay.co · aacstandard.com/license
    internal static let aacStandard = L10n.tr("Localizable", "Attribution.aacStandard", fallback: "Symbols: AAC Standard · © aisay.co · aacstandard.com/license")
    /// Pictograms: Sergio Palao / ARASAAC · © Government of Aragón · CC BY-NC-SA · arasaac.org · creativecommons.org/licenses/by-nc-sa/4.0/
    internal static let arasaac = L10n.tr("Localizable", "Attribution.arasaac", fallback: "Pictograms: Sergio Palao / ARASAAC · © Government of Aragón · CC BY-NC-SA · arasaac.org · creativecommons.org/licenses/by-nc-sa/4.0/")
    ///  · Some pictograms modified in this app
    internal static let arasaacModified = L10n.tr("Localizable", "Attribution.arasaacModified", fallback: " · Some pictograms modified in this app")
  }
  internal enum BoardEditor {
    /// Format
    internal static let formatAction = L10n.tr("Localizable", "BoardEditor.formatAction", fallback: "Format")
    /// More content above
    internal static let moreAbove = L10n.tr("Localizable", "BoardEditor.moreAbove", fallback: "More content above")
    /// More content below
    internal static let moreBelow = L10n.tr("Localizable", "BoardEditor.moreBelow", fallback: "More content below")
    /// More content to the left
    internal static let moreLeft = L10n.tr("Localizable", "BoardEditor.moreLeft", fallback: "More content to the left")
    /// More content to the right
    internal static let moreRight = L10n.tr("Localizable", "BoardEditor.moreRight", fallback: "More content to the right")
    /// Move card earlier
    internal static let moveEarlier = L10n.tr("Localizable", "BoardEditor.moveEarlier", fallback: "Move card earlier")
    /// Move card later
    internal static let moveLater = L10n.tr("Localizable", "BoardEditor.moveLater", fallback: "Move card later")
    /// Zoom
    internal static let zoom = L10n.tr("Localizable", "BoardEditor.zoom", fallback: "Zoom")
    /// Fit to Screen
    internal static let zoomFit = L10n.tr("Localizable", "BoardEditor.zoomFit", fallback: "Fit to Screen")
    /// Zoom In
    internal static let zoomIn = L10n.tr("Localizable", "BoardEditor.zoomIn", fallback: "Zoom In")
    /// Zoom Out
    internal static let zoomOut = L10n.tr("Localizable", "BoardEditor.zoomOut", fallback: "Zoom Out")
  }
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
  internal enum DeleteCardAlert {
    /// Delete card from your board?
    internal static let message = L10n.tr("Localizable", "DeleteCardAlert.message", fallback: "Delete card from your board?")
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
  internal enum EmptyBoardView {
    /// Add Photos
    internal static let addPhotosButton = L10n.tr("Localizable", "EmptyBoardView.addPhotosButton", fallback: "Add Photos")
    /// Search Pictograms
    internal static let browseSymbolsButton = L10n.tr("Localizable", "EmptyBoardView.browseSymbolsButton", fallback: "Search Pictograms")
    /// Add photos or pictograms to create your own board.
    internal static let message = L10n.tr("Localizable", "EmptyBoardView.message", fallback: "Add photos or pictograms to create your own board.")
    /// Take Photo
    internal static let takePhotoButton = L10n.tr("Localizable", "EmptyBoardView.takePhotoButton", fallback: "Take Photo")
    /// Bring your board to life
    internal static let title = L10n.tr("Localizable", "EmptyBoardView.title", fallback: "Bring your board to life")
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
  internal enum InterfaceStyle {
    /// Classic
    internal static let classic = L10n.tr("Localizable", "InterfaceStyle.classic", fallback: "Classic")
    /// Classic uses the original Main Menu, Selected Photos, and Preview and Print screens. Both interfaces use the updated Layout and Format screens and the same saved boards.
    internal static let explanation = L10n.tr("Localizable", "InterfaceStyle.explanation", fallback: "Classic uses the original Main Menu, Selected Photos, and Preview and Print screens. Both interfaces use the updated Layout and Format screens and the same saved boards.")
    /// New (default)
    internal static let modern = L10n.tr("Localizable", "InterfaceStyle.modern", fallback: "New (default)")
    /// Interface
    internal static let title = L10n.tr("Localizable", "InterfaceStyle.title", fallback: "Interface")
  }
  internal enum LayoutScreen {
    /// All Sizes
    internal static let allSizes = L10n.tr("Localizable", "LayoutScreen.allSizes", fallback: "All Sizes")
    /// %d cells
    internal static func cellCount(_ p1: Int) -> String {
      return L10n.tr("Localizable", "LayoutScreen.cellCount", p1, fallback: "%d cells")
    }
    /// %d columns
    internal static func columns(_ p1: Int) -> String {
      return L10n.tr("Localizable", "LayoutScreen.columns", p1, fallback: "%d columns")
    }
    /// Done
    internal static let doneButton = L10n.tr("Localizable", "LayoutScreen.doneButton", fallback: "Done")
    /// Extra Small Cards
    internal static let extraSmallCards = L10n.tr("Localizable", "LayoutScreen.extraSmallCards", fallback: "Extra Small Cards")
    /// Landscape
    internal static let landscape = L10n.tr("Localizable", "LayoutScreen.landscape", fallback: "Landscape")
    /// Large Cards
    internal static let largeCards = L10n.tr("Localizable", "LayoutScreen.largeCards", fallback: "Large Cards")
    /// Layouts
    internal static let layouts = L10n.tr("Localizable", "LayoutScreen.layouts", fallback: "Layouts")
    /// Medium Cards
    internal static let mediumCards = L10n.tr("Localizable", "LayoutScreen.mediumCards", fallback: "Medium Cards")
    /// Narrow Cards
    internal static let narrowCards = L10n.tr("Localizable", "LayoutScreen.narrowCards", fallback: "Narrow Cards")
    /// 1 cell
    internal static let oneCell = L10n.tr("Localizable", "LayoutScreen.oneCell", fallback: "1 cell")
    /// 1 column
    internal static let oneColumn = L10n.tr("Localizable", "LayoutScreen.oneColumn", fallback: "1 column")
    /// 1 row
    internal static let oneRow = L10n.tr("Localizable", "LayoutScreen.oneRow", fallback: "1 row")
    /// Portrait
    internal static let portrait = L10n.tr("Localizable", "LayoutScreen.portrait", fallback: "Portrait")
    /// Recommended
    internal static let recommendedLayouts = L10n.tr("Localizable", "LayoutScreen.recommendedLayouts", fallback: "Recommended")
    /// %d rows
    internal static func rows(_ p1: Int) -> String {
      return L10n.tr("Localizable", "LayoutScreen.rows", p1, fallback: "%d rows")
    }
    /// See All
    internal static let seeAll = L10n.tr("Localizable", "LayoutScreen.seeAll", fallback: "See All")
    /// Single Row
    internal static let singleRow = L10n.tr("Localizable", "LayoutScreen.singleRow", fallback: "Single Row")
    /// Small Cards
    internal static let smallCards = L10n.tr("Localizable", "LayoutScreen.smallCards", fallback: "Small Cards")
    /// %@ · %@ · %@
    internal static func summary(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
      return L10n.tr("Localizable", "LayoutScreen.summary", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "%@ · %@ · %@")
    }
    /// Page Layout
    internal static let title = L10n.tr("Localizable", "LayoutScreen.title", fallback: "Page Layout")
    /// Wide Cards
    internal static let wideCards = L10n.tr("Localizable", "LayoutScreen.wideCards", fallback: "Wide Cards")
  }
  internal enum LayoutSelectionView {
    /// Grid layout
    internal static let title = L10n.tr("Localizable", "LayoutSelectionView.title", fallback: "Grid layout")
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
    /// Allow Personal Voice Access
    internal static let allowPersonalVoice = L10n.tr("Localizable", "MainMenu.allowPersonalVoice", fallback: "Allow Personal Voice Access")
    /// App Language
    internal static let appLanguage = L10n.tr("Localizable", "MainMenu.appLanguage", fallback: "App Language")
    /// Back
    internal static let back = L10n.tr("Localizable", "MainMenu.back", fallback: "Back")
    /// Change Selections
    internal static let changeSelectionsButton = L10n.tr("Localizable", "MainMenu.changeSelectionsButton", fallback: "Change Selections")
    /// Opens your selected photos, where you can add more from the library or camera.
    internal static let changeSelectionsHint = L10n.tr("Localizable", "MainMenu.changeSelectionsHint", fallback: "Opens your selected photos, where you can add more from the library or camera.")
    /// Change Image
    internal static let changeTopicImageButton = L10n.tr("Localizable", "MainMenu.changeTopicImageButton", fallback: "Change Image")
    /// Change Voice
    internal static let changeVoiceButton = L10n.tr("Localizable", "MainMenu.changeVoiceButton", fallback: "Change Voice")
    /// Use Board
    internal static let choiceBoardButton = L10n.tr("Localizable", "MainMenu.choiceBoardButton", fallback: "Use Board")
    /// Choose Photos
    internal static let choosePhotosButton = L10n.tr("Localizable", "MainMenu.choosePhotosButton", fallback: "Choose Photos")
    /// Search for a Symbol
    internal static let classicSymbolSearchButton = L10n.tr("Localizable", "MainMenu.classicSymbolSearchButton", fallback: "Search for a Symbol")
    /// Clear Selections
    internal static let clearSelectionsButton = L10n.tr("Localizable", "MainMenu.clearSelectionsButton", fallback: "Clear Selections")
    /// How to Create a Personal Voice
    internal static let createPersonalVoice = L10n.tr("Localizable", "MainMenu.createPersonalVoice", fallback: "How to Create a Personal Voice")
    /// System Recommended Voice
    internal static let defaultVoice = L10n.tr("Localizable", "MainMenu.defaultVoice", fallback: "System Recommended Voice")
    /// You're using an enhanced quality voice. Premium voices may be available in iPhone Settings.
    internal static let enhancedVoiceNotice = L10n.tr("Localizable", "MainMenu.enhancedVoiceNotice", fallback: "You're using an enhanced quality voice. Premium voices may be available in iPhone Settings.")
    /// Get More Voices
    internal static let getMoreVoices = L10n.tr("Localizable", "MainMenu.getMoreVoices", fallback: "Get More Voices")
    /// Layout
    internal static let layoutCardTitle = L10n.tr("Localizable", "MainMenu.layoutCardTitle", fallback: "Layout")
    /// %d × %d grid
    internal static func layoutStatus(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "MainMenu.layoutStatus", p1, p2, fallback: "%d × %d grid")
    }
    /// More Apps
    internal static let moreAppsButton = L10n.tr("Localizable", "MainMenu.moreAppsButton", fallback: "More Apps")
    /// More options
    internal static let moreOptions = L10n.tr("Localizable", "MainMenu.moreOptions", fallback: "More options")
    /// Got it
    internal static let moreVoicesGotIt = L10n.tr("Localizable", "MainMenu.moreVoicesGotIt", fallback: "Got it")
    /// Add a clearer voice in iPhone Settings, then choose it here for your Choice Board.
    internal static let moreVoicesIntro = L10n.tr("Localizable", "MainMenu.moreVoicesIntro", fallback: "Add a clearer voice in iPhone Settings, then choose it here for your Choice Board.")
    /// Accessibility › Spoken Content › Voices
    internal static let moreVoicesPathLegacy = L10n.tr("Localizable", "MainMenu.moreVoicesPathLegacy", fallback: "Accessibility › Spoken Content › Voices")
    /// Accessibility › Read & Speak › Voices
    internal static let moreVoicesPathModern = L10n.tr("Localizable", "MainMenu.moreVoicesPathModern", fallback: "Accessibility › Read & Speak › Voices")
    /// Preview the new voice and tap it to use it on your Choice Board.
    internal static let moreVoicesReturnDetail = L10n.tr("Localizable", "MainMenu.moreVoicesReturnDetail", fallback: "Preview the new voice and tap it to use it on your Choice Board.")
    /// Come back to %@
    internal static func moreVoicesReturnTitle(_ p1: Any) -> String {
      return L10n.tr("Localizable", "MainMenu.moreVoicesReturnTitle", String(describing: p1), fallback: "Come back to %@")
    }
    /// Find the Settings app on your Home Screen or in App Library.
    internal static let moreVoicesStepOneDetail = L10n.tr("Localizable", "MainMenu.moreVoicesStepOneDetail", fallback: "Find the Settings app on your Home Screen or in App Library.")
    /// Open iPhone Settings
    internal static let moreVoicesStepOneTitle = L10n.tr("Localizable", "MainMenu.moreVoicesStepOneTitle", fallback: "Open iPhone Settings")
    /// Choose your language, then tap the download icon beside an enhanced or premium voice.
    internal static let moreVoicesStepThreeDetail = L10n.tr("Localizable", "MainMenu.moreVoicesStepThreeDetail", fallback: "Choose your language, then tap the download icon beside an enhanced or premium voice.")
    /// Download a voice
    internal static let moreVoicesStepThreeTitle = L10n.tr("Localizable", "MainMenu.moreVoicesStepThreeTitle", fallback: "Download a voice")
    /// Go to Voices
    internal static let moreVoicesStepTwoTitle = L10n.tr("Localizable", "MainMenu.moreVoicesStepTwoTitle", fallback: "Go to Voices")
    /// Download more voices
    internal static let moreVoicesTitle = L10n.tr("Localizable", "MainMenu.moreVoicesTitle", fallback: "Download more voices")
    /// No Personal Voice matches this language. Choose your Personal Voice's language above to see it.
    internal static let noPersonalVoiceForLanguage = L10n.tr("Localizable", "MainMenu.noPersonalVoiceForLanguage", fallback: "No Personal Voice matches this language. Choose your Personal Voice's language above to see it.")
    /// No Personal Voice is available yet. Create one in iPhone Settings, then return here.
    internal static let noPersonalVoices = L10n.tr("Localizable", "MainMenu.noPersonalVoices", fallback: "No Personal Voice is available yet. Create one in iPhone Settings, then return here.")
    /// No photos selected
    internal static let noPhotosStatus = L10n.tr("Localizable", "MainMenu.noPhotosStatus", fallback: "No photos selected")
    /// No premium voices are installed for this language. Higher quality voices may be available in iPhone Settings.
    internal static let noPremiumVoiceNotice = L10n.tr("Localizable", "MainMenu.noPremiumVoiceNotice", fallback: "No premium voices are installed for this language. Higher quality voices may be available in iPhone Settings.")
    /// 1 photo selected
    internal static let onePhotoStatus = L10n.tr("Localizable", "MainMenu.onePhotoStatus", fallback: "1 photo selected")
    /// Opens this board option
    internal static let openActionHint = L10n.tr("Localizable", "MainMenu.openActionHint", fallback: "Opens this board option")
    /// Design Board
    internal static let pecsMakerButton = L10n.tr("Localizable", "MainMenu.pecsMakerButton", fallback: "Design Board")
    /// Personal Voice
    internal static let personalVoice = L10n.tr("Localizable", "MainMenu.personalVoice", fallback: "Personal Voice")
    /// Personal Voice access is off for this app. Turn it on in iPhone Settings > Accessibility > Personal Voice.
    internal static let personalVoiceAccessDenied = L10n.tr("Localizable", "MainMenu.personalVoiceAccessDenied", fallback: "Personal Voice access is off for this app. Turn it on in iPhone Settings > Accessibility > Personal Voice.")
    /// Allow access to use a Personal Voice you created on this iPhone.
    internal static let personalVoiceAccessExplanation = L10n.tr("Localizable", "MainMenu.personalVoiceAccessExplanation", fallback: "Allow access to use a Personal Voice you created on this iPhone.")
    /// In iPhone Settings, go to Accessibility > Personal Voice. Create a voice and turn on Allow Apps to Request to Use. If access was denied, allow this app there. Return here to select your voice.
    internal static let personalVoiceHelp = L10n.tr("Localizable", "MainMenu.personalVoiceHelp", fallback: "In iPhone Settings, go to Accessibility > Personal Voice. Create a voice and turn on Allow Apps to Request to Use. If access was denied, allow this app there. Return here to select your voice.")
    /// You're using a Personal Voice.
    internal static let personalVoiceSelectedNotice = L10n.tr("Localizable", "MainMenu.personalVoiceSelectedNotice", fallback: "You're using a Personal Voice.")
    /// How to Enable Personal Voice
    internal static let personalVoiceSettingsHelp = L10n.tr("Localizable", "MainMenu.personalVoiceSettingsHelp", fallback: "How to Enable Personal Voice")
    /// Personal Voice isn't available on this device.
    internal static let personalVoiceUnsupported = L10n.tr("Localizable", "MainMenu.personalVoiceUnsupported", fallback: "Personal Voice isn't available on this device.")
    /// Photos
    internal static let photosCardTitle = L10n.tr("Localizable", "MainMenu.photosCardTitle", fallback: "Photos")
    /// Choose photos from your library or take a new photo.
    internal static let photosEmptyHelp = L10n.tr("Localizable", "MainMenu.photosEmptyHelp", fallback: "Choose photos from your library or take a new photo.")
    /// %d photos selected
    internal static func photosSelectedStatus(_ p1: Int) -> String {
      return L10n.tr("Localizable", "MainMenu.photosSelectedStatus", p1, fallback: "%d photos selected")
    }
    /// You're using a premium quality voice. Other premium voices may be available in iPhone Settings.
    internal static let premiumVoiceNotice = L10n.tr("Localizable", "MainMenu.premiumVoiceNotice", fallback: "You're using a premium quality voice. Other premium voices may be available in iPhone Settings.")
    /// Recommended Premium Voices
    internal static let premiumVoices = L10n.tr("Localizable", "MainMenu.premiumVoices", fallback: "Recommended Premium Voices")
    /// Preview blank grid
    internal static let previewBlankStatus = L10n.tr("Localizable", "MainMenu.previewBlankStatus", fallback: "Preview blank grid")
    /// Preview your board
    internal static let previewReadyStatus = L10n.tr("Localizable", "MainMenu.previewReadyStatus", fallback: "Preview your board")
    /// Preview %@
    internal static func previewVoice(_ p1: Any) -> String {
      return L10n.tr("Localizable", "MainMenu.previewVoice", String(describing: p1), fallback: "Preview %@")
    }
    /// Preview and Print
    internal static let printButton = L10n.tr("Localizable", "MainMenu.printButton", fallback: "Preview and Print")
    /// Rename
    internal static let renameButton = L10n.tr("Localizable", "MainMenu.renameButton", fallback: "Rename")
    /// Select Layout
    internal static let selectLayoutButton = L10n.tr("Localizable", "MainMenu.selectLayoutButton", fallback: "Select Layout")
    /// Add Photos From Library
    internal static let selectPhotosButton = L10n.tr("Localizable", "MainMenu.selectPhotosButton", fallback: "Add Photos From Library")
    /// Opens the photo library picker.
    internal static let selectPhotosHint = L10n.tr("Localizable", "MainMenu.selectPhotosHint", fallback: "Opens the photo library picker.")
    /// Settings
    internal static let settingsButton = L10n.tr("Localizable", "MainMenu.settingsButton", fallback: "Settings")
    /// You're using a standard quality voice. Better quality voices may be available in iPhone Settings.
    internal static let standardVoiceNotice = L10n.tr("Localizable", "MainMenu.standardVoiceNotice", fallback: "You're using a standard quality voice. Better quality voices may be available in iPhone Settings.")
    /// Symbol Search
    internal static let symbolSearchButton = L10n.tr("Localizable", "MainMenu.symbolSearchButton", fallback: "Symbol Search")
    /// Search ARASAAC pictograms to add to this board.
    internal static let symbolSearchHint = L10n.tr("Localizable", "MainMenu.symbolSearchHint", fallback: "Search ARASAAC pictograms to add to this board.")
    /// Take Photo
    internal static let takePhotoButton = L10n.tr("Localizable", "MainMenu.takePhotoButton", fallback: "Take Photo")
    /// Opens the camera to take a photo.
    internal static let takePhotoHint = L10n.tr("Localizable", "MainMenu.takePhotoHint", fallback: "Opens the camera to take a photo.")
    /// Titles
    internal static let titlesCardTitle = L10n.tr("Localizable", "MainMenu.titlesCardTitle", fallback: "Titles")
    /// Off
    internal static let titlesOffStatus = L10n.tr("Localizable", "MainMenu.titlesOffStatus", fallback: "Off")
    /// On
    internal static let titlesOnStatus = L10n.tr("Localizable", "MainMenu.titlesOnStatus", fallback: "On")
    /// Language and Locale
    internal static let voiceLanguage = L10n.tr("Localizable", "MainMenu.voiceLanguage", fallback: "Language and Locale")
  }
  internal enum NoPhotosView {
    /// Add Photos From Library
    internal static let addPhotosButton = L10n.tr("Localizable", "NoPhotosView.addPhotosButton", fallback: "Add Photos From Library")
    /// Get your project started by adding some photos.
    internal static let message = L10n.tr("Localizable", "NoPhotosView.message", fallback: "Get your project started by adding some photos.")
    /// Take Photo
    internal static let takePhotoButton = L10n.tr("Localizable", "NoPhotosView.takePhotoButton", fallback: "Take Photo")
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
    /// Add items
    internal static let addItems = L10n.tr("Localizable", "PhotoSelectionView.addItems", fallback: "Add items")
    /// Add Photos
    internal static let addMorePhotosButton = L10n.tr("Localizable", "PhotoSelectionView.addMorePhotosButton", fallback: "Add Photos")
    /// Crop selected photos
    internal static let autoCropButton = L10n.tr("Localizable", "PhotoSelectionView.autoCropButton", fallback: "Crop selected photos")
    /// Board Details
    internal static let boardDetails = L10n.tr("Localizable", "PhotoSelectionView.boardDetails", fallback: "Board Details")
    /// Camera
    internal static let camera = L10n.tr("Localizable", "PhotoSelectionView.camera", fallback: "Camera")
    /// Done
    internal static let closeSelection = L10n.tr("Localizable", "PhotoSelectionView.closeSelection", fallback: "Done")
    /// Copy
    internal static let copyAction = L10n.tr("Localizable", "PhotoSelectionView.copyAction", fallback: "Copy")
    /// Copy selected photos
    internal static let copyButton = L10n.tr("Localizable", "PhotoSelectionView.copyButton", fallback: "Copy selected photos")
    /// Crop
    internal static let cropAction = L10n.tr("Localizable", "PhotoSelectionView.cropAction", fallback: "Crop")
    /// Delete
    internal static let deleteAction = L10n.tr("Localizable", "PhotoSelectionView.deleteAction", fallback: "Delete")
    /// Delete All
    internal static let deleteAllButton = L10n.tr("Localizable", "PhotoSelectionView.deleteAllButton", fallback: "Delete All")
    /// Delete selected photos
    internal static let deleteButton = L10n.tr("Localizable", "PhotoSelectionView.deleteButton", fallback: "Delete selected photos")
    /// Deselect All
    internal static let deselectAllButton = L10n.tr("Localizable", "PhotoSelectionView.deselectAllButton", fallback: "Deselect All")
    /// Deselect photo
    internal static let deselectPhoto = L10n.tr("Localizable", "PhotoSelectionView.deselectPhoto", fallback: "Deselect photo")
    /// Duplicate
    internal static let duplicateAction = L10n.tr("Localizable", "PhotoSelectionView.duplicateAction", fallback: "Duplicate")
    /// Duplicate selected photos
    internal static let duplicateButton = L10n.tr("Localizable", "PhotoSelectionView.duplicateButton", fallback: "Duplicate selected photos")
    /// Edit Board
    internal static let editBoardTitle = L10n.tr("Localizable", "PhotoSelectionView.editBoardTitle", fallback: "Edit Board")
    /// Empty card
    internal static let emptyCard = L10n.tr("Localizable", "PhotoSelectionView.emptyCard", fallback: "Empty card")
    /// Layout
    internal static let layoutAction = L10n.tr("Localizable", "PhotoSelectionView.layoutAction", fallback: "Layout")
    /// %d selected
    internal static func manySelectedSubtitle(_ p1: Int) -> String {
      return L10n.tr("Localizable", "PhotoSelectionView.manySelectedSubtitle", p1, fallback: "%d selected")
    }
    /// More actions
    internal static let moreActions = L10n.tr("Localizable", "PhotoSelectionView.moreActions", fallback: "More actions")
    /// %d selected
    internal static func oneSelectedSubtitle(_ p1: Int) -> String {
      return L10n.tr("Localizable", "PhotoSelectionView.oneSelectedSubtitle", p1, fallback: "%d selected")
    }
    /// %d Photos
    internal static func photoCountLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "PhotoSelectionView.photoCountLabel", p1, fallback: "%d Photos")
    }
    /// Photo Library
    internal static let photoLibrary = L10n.tr("Localizable", "PhotoSelectionView.photoLibrary", fallback: "Photo Library")
    /// Selected Photos browsing and selection
    internal static let photosTitle = L10n.tr("Localizable", "PhotoSelectionView.photosTitle", fallback: "Photos")
    /// Print
    internal static let printAction = L10n.tr("Localizable", "PhotoSelectionView.printAction", fallback: "Print")
    /// Select
    internal static let select = L10n.tr("Localizable", "PhotoSelectionView.select", fallback: "Select")
    /// Select All
    internal static let selectAllButton = L10n.tr("Localizable", "PhotoSelectionView.selectAllButton", fallback: "Select All")
    /// (%d Photos Selected)
    internal static func selectedPhotoCountLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "PhotoSelectionView.selectedPhotoCountLabel", p1, fallback: "(%d Photos Selected)")
    }
    /// Share
    internal static let shareAction = L10n.tr("Localizable", "PhotoSelectionView.shareAction", fallback: "Share")
    /// Selected Photos
    internal static let title = L10n.tr("Localizable", "PhotoSelectionView.title", fallback: "Selected Photos")
    /// [Untitled]
    internal static let untitledCell = L10n.tr("Localizable", "PhotoSelectionView.untitledCell", fallback: "[Untitled]")
    internal enum CopyPhotosSuccessAlert {
      /// Photo(s) Copied
      internal static let title = L10n.tr("Localizable", "PhotoSelectionView.CopyPhotosSuccessAlert.title", fallback: "Photo(s) Copied")
    }
  }
  internal enum PhotoSourceMenu {
    /// Symbol
    internal static let symbol = L10n.tr("Localizable", "PhotoSourceMenu.symbol", fallback: "Symbol")
  }
  internal enum PhotoZoomView {
    /// Actions
    internal static let actionsSectionTitle = L10n.tr("Localizable", "PhotoZoomView.actionsSectionTitle", fallback: "Actions")
    /// Add Photo
    internal static let addPhotoButton = L10n.tr("Localizable", "PhotoZoomView.addPhotoButton", fallback: "Add Photo")
    /// Cancel
    internal static let cancelButton = L10n.tr("Localizable", "PhotoZoomView.cancelButton", fallback: "Cancel")
    /// Close
    internal static let closeButton = L10n.tr("Localizable", "PhotoZoomView.closeButton", fallback: "Close")
    /// Crop
    internal static let cropButton = L10n.tr("Localizable", "PhotoZoomView.cropButton", fallback: "Crop")
    /// Delete Card
    internal static let deleteCardButton = L10n.tr("Localizable", "PhotoZoomView.deleteCardButton", fallback: "Delete Card")
    /// Duplicate Card
    internal static let duplicateCardButton = L10n.tr("Localizable", "PhotoZoomView.duplicateCardButton", fallback: "Duplicate Card")
    /// Edit Card
    internal static let editCardTitle = L10n.tr("Localizable", "PhotoZoomView.editCardTitle", fallback: "Edit Card")
    /// Edit Photo
    internal static let editPhotoButton = L10n.tr("Localizable", "PhotoZoomView.editPhotoButton", fallback: "Edit Photo")
    /// Erase Background
    internal static let eraseBackgroundButton = L10n.tr("Localizable", "PhotoZoomView.eraseBackgroundButton", fallback: "Erase Background")
    /// Photo
    internal static let photoSectionTitle = L10n.tr("Localizable", "PhotoZoomView.photoSectionTitle", fallback: "Photo")
    /// Remove Photo
    internal static let removePhotoButton = L10n.tr("Localizable", "PhotoZoomView.removePhotoButton", fallback: "Remove Photo")
    /// Replace
    internal static let replaceButton = L10n.tr("Localizable", "PhotoZoomView.replaceButton", fallback: "Replace")
    /// Replace Photo
    internal static let replacePhotoButton = L10n.tr("Localizable", "PhotoZoomView.replacePhotoButton", fallback: "Replace Photo")
    /// Revert
    internal static let revertButton = L10n.tr("Localizable", "PhotoZoomView.revertButton", fallback: "Revert")
    /// Save
    internal static let saveButton = L10n.tr("Localizable", "PhotoZoomView.saveButton", fallback: "Save")
    /// Use as Board Cover
    internal static let useAsBoardCoverButton = L10n.tr("Localizable", "PhotoZoomView.useAsBoardCoverButton", fallback: "Use as Board Cover")
  }
  internal enum PreviewPage {
    /// Opens the add card editor
    internal static let addCardHint = L10n.tr("Localizable", "PreviewPage.addCardHint", fallback: "Opens the add card editor")
    /// Page %d, card %d: %@
    internal static func cardPosition(_ p1: Int, _ p2: Int, _ p3: Any) -> String {
      return L10n.tr("Localizable", "PreviewPage.cardPosition", p1, p2, String(describing: p3), fallback: "Page %d, card %d: %@")
    }
    /// Edit Cards
    internal static let cardsButton = L10n.tr("Localizable", "PreviewPage.cardsButton", fallback: "Edit Cards")
    /// Done
    internal static let closeCards = L10n.tr("Localizable", "PreviewPage.closeCards", fallback: "Done")
    /// Opens the card editor
    internal static let editCardHint = L10n.tr("Localizable", "PreviewPage.editCardHint", fallback: "Opens the card editor")
    /// Formatting
    internal static let formattingButton = L10n.tr("Localizable", "PreviewPage.formattingButton", fallback: "Formatting")
    /// Next page
    internal static let nextPage = L10n.tr("Localizable", "PreviewPage.nextPage", fallback: "Next page")
    /// Page %d of %d
    internal static func pageStatus(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "PreviewPage.pageStatus", p1, p2, fallback: "Page %d of %d")
    }
    /// Previous page
    internal static let previousPage = L10n.tr("Localizable", "PreviewPage.previousPage", fallback: "Previous page")
    /// Repeat Card
    internal static let repeatButton = L10n.tr("Localizable", "PreviewPage.repeatButton", fallback: "Repeat Card")
    /// Print
    internal static let saveButton = L10n.tr("Localizable", "PreviewPage.saveButton", fallback: "Print")
    /// Save to Photo Library
    internal static let saveImageButton = L10n.tr("Localizable", "PreviewPage.saveImageButton", fallback: "Save to Photo Library")
    /// Preview
    internal static let title = L10n.tr("Localizable", "PreviewPage.title", fallback: "Preview")
    internal enum PhotoSaveError {
      /// Allow access to Photos in Settings to save your board.
      internal static let accessDenied = L10n.tr("Localizable", "PreviewPage.PhotoSaveError.accessDenied", fallback: "Allow access to Photos in Settings to save your board.")
      /// There are no board pages to save.
      internal static let noImages = L10n.tr("Localizable", "PreviewPage.PhotoSaveError.noImages", fallback: "There are no board pages to save.")
      /// Couldn’t Save to Photos
      internal static let title = L10n.tr("Localizable", "PreviewPage.PhotoSaveError.title", fallback: "Couldn’t Save to Photos")
    }
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
  internal enum Symbols {
    /// AAC Standard
    internal static let aacStandard = L10n.tr("Localizable", "Symbols.aacStandard", fallback: "AAC Standard")
    /// ARASAAC
    internal static let arasaac = L10n.tr("Localizable", "Symbols.arasaac", fallback: "ARASAAC")
    /// Create with AI
    internal static let createWithAI = L10n.tr("Localizable", "Symbols.createWithAI", fallback: "Create with AI")
    /// Dynavox
    internal static let dynavox = L10n.tr("Localizable", "Symbols.dynavox", fallback: "Dynavox")
    /// Symbol Library
    internal static let library = L10n.tr("Localizable", "Symbols.library", fallback: "Symbol Library")
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
    /// Change Title
    internal static let renameButton = L10n.tr("Localizable", "TopicContextMenu.renameButton", fallback: "Change Title")
    /// View
    internal static let viewButton = L10n.tr("Localizable", "TopicContextMenu.viewButton", fallback: "View")
  }
  internal enum TopicImageSelector {
    /// Change Board Icon
    internal static let title = L10n.tr("Localizable", "TopicImageSelector.title", fallback: "Change Board Icon")
    /// Use Automatically Generated Cover
    internal static let useGeneratedThumbnailButton = L10n.tr("Localizable", "TopicImageSelector.useGeneratedThumbnailButton", fallback: "Use Automatically Generated Cover")
  }
  internal enum TopicSelectionView {
    /// New Board
    internal static let createDesignButton = L10n.tr("Localizable", "TopicSelectionView.createDesignButton", fallback: "New Board")
    /// Delete
    internal static let deleteButton = L10n.tr("Localizable", "TopicSelectionView.deleteButton", fallback: "Delete")
    /// Deselect All
    internal static let deselectAllButton = L10n.tr("Localizable", "TopicSelectionView.deselectAllButton", fallback: "Deselect All")
    /// Design Boards
    internal static let designBoardsButton = L10n.tr("Localizable", "TopicSelectionView.designBoardsButton", fallback: "Design Boards")
    /// Done
    internal static let doneButton = L10n.tr("Localizable", "TopicSelectionView.doneButton", fallback: "Done")
    /// Edit
    internal static let editButton = L10n.tr("Localizable", "TopicSelectionView.editButton", fallback: "Edit")
    /// Hide Sidebar
    internal static let hideSidebarButton = L10n.tr("Localizable", "TopicSelectionView.hideSidebarButton", fallback: "Hide Sidebar")
    /// Maximize Sidebar
    internal static let maximizeButton = L10n.tr("Localizable", "TopicSelectionView.maximizeButton", fallback: "Maximize Sidebar")
    /// Move board earlier
    internal static let moveEarlier = L10n.tr("Localizable", "TopicSelectionView.moveEarlier", fallback: "Move board earlier")
    /// Move board later
    internal static let moveLater = L10n.tr("Localizable", "TopicSelectionView.moveLater", fallback: "Move board later")
    /// Tap New Board to get started.
    internal static let noTopicsMessage = L10n.tr("Localizable", "TopicSelectionView.noTopicsMessage", fallback: "Tap New Board to get started.")
    /// Rename Topic
    internal static let renameTopicButton = L10n.tr("Localizable", "TopicSelectionView.renameTopicButton", fallback: "Rename Topic")
    /// Restore Split View
    internal static let restoreSplitViewButton = L10n.tr("Localizable", "TopicSelectionView.restoreSplitViewButton", fallback: "Restore Split View")
    /// Select All
    internal static let selectAllButton = L10n.tr("Localizable", "TopicSelectionView.selectAllButton", fallback: "Select All")
    /// Select
    internal static let selectButton = L10n.tr("Localizable", "TopicSelectionView.selectButton", fallback: "Select")
    /// Show Sidebar
    internal static let showSidebarButton = L10n.tr("Localizable", "TopicSelectionView.showSidebarButton", fallback: "Show Sidebar")
    /// Boards
    internal static let title = L10n.tr("Localizable", "TopicSelectionView.title", fallback: "Boards")
    /// Delete %@
    internal static func topicDeleteButton(_ p1: Any) -> String {
      return L10n.tr("Localizable", "TopicSelectionView.topicDeleteButton", String(describing: p1), fallback: "Delete %@")
    }
    internal enum DeleteSelectionAlert {
      /// Delete %d selected boards?
      internal static func manyMessage(_ p1: Int) -> String {
        return L10n.tr("Localizable", "TopicSelectionView.DeleteSelectionAlert.manyMessage", p1, fallback: "Delete %d selected boards?")
      }
      /// Delete the selected board?
      internal static let oneMessage = L10n.tr("Localizable", "TopicSelectionView.DeleteSelectionAlert.oneMessage", fallback: "Delete the selected board?")
      /// Delete Selected Boards
      internal static let title = L10n.tr("Localizable", "TopicSelectionView.DeleteSelectionAlert.title", fallback: "Delete Selected Boards")
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
