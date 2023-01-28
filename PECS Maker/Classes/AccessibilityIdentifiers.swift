//
//  AccessibilityIdentifiers.swift
//  PECS Maker
//
//  Created by Andy on 25/03/2022.
//

import Foundation
import UIKit

enum PageOrientation: String, CaseIterable { case portrait, landscape }

enum PageSize: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case a4 = "A4"
    case usLetter = "US Letter"
    case photo10by15 = "10x15 Photo Paper"
}

struct PageLayoutType : Hashable {
    var width: Int
    var height: Int
    var total: Int { return width * height }
    var isDefault: PageOrientation?
    var shortDebugDescription: String {
        get { return "\(width)x\(height)"}
    }
}

typealias PageLayout = PageLayoutType

typealias A12 = AccessibilityIdentifiers

struct AccessibilityIdentifiers {
    struct MainMenu {
        static var selectPhotoButton = "MainMenu.selectPhotoButton"
        static var clearSelectionsButton = "MainMenu.clearSelectionsButton"
        static var selectLayoutButton = "MainMenu.selectLayoutButton"
        static var selectTitlesButton = "MainMenu.selectTitlesButton"
        static var previewAndPrintButton = "MainMenu.previewAndPrintButton"
        static var settingsButton = "MainMenu.settingsButton"
        static var moreAppsButton = "MainMenu.moreAppsButton"
    }
    
    struct LayoutScreen {
        
        static var pageSizeHeading = "LayoutScreen.pageSizeHeading"

        static func pageSizeButton(for pageSizeType: PageSize) -> String {
            return "LayoutScreen.pageSize.\(pageSizeType.rawValue)"
        }
        
        static var orientationHeading = "LayoutScreen.orientationHeading"

        static func orientationButton(for pageOrientationType: PageOrientation) -> String {
            return "LayoutScreen.orientation.\(pageOrientationType.rawValue)"
        }

        static var layoutHeading = "LayoutScreen.layoutHeading"
        static var layoutButtonPrefix = "LayoutScreen.layout."
        static func layoutButton(for layout: PageLayout) -> String {
            return "\(layoutButtonPrefix).\(layout.width).\(layout.height))"
        }

        static var doneButton = "LayoutScreen.doneButton"
    }

    struct TitlesScreen {
        
        //static var pageSizeHeading = "TitlesScreen.titles"

        static var imagePrefix: String = "TitlesScreen.image."
        static func image(for index: Int) -> String {
            return "\(imagePrefix)\(index)"
        }
        
        static var titlePrefix: String = "TitlesScreen.title."
        static func titleText(for index: Int) -> String {
            return "\(titlePrefix)\(index)"
        }
        
        static var deletePrefix: String = "TitlesScreen.deleteButton."
        static func deleteButton(for index: Int) -> String {
            return "\(deletePrefix)\(index)"
        }

        static var duplicatePrefix: String = "TitlesScreen.duplicateButton."
        static func duplicateButton(for index: Int) -> String {
            return "\(duplicatePrefix)\(index)"
        }


        
        static var doneButton = "TitlesScreen.doneButton"
    }
    
    struct PreviewScreen {
        
        static var previewImagePrefix: String = "PreviewScreen.previewImage"
        static func previewImage(for index: Int) -> String {
            return "\(previewImagePrefix).\(index)"
        }

        static var repeatImageButton = "PreviewScreen.repeatImageButton"
        static var formattingButton = "PreviewScreen.formattingButton"
        static var saveAndPrintButton = "PreviewScreen.saveAndPrintButton"
        static var doneButton = "PreviewScreen.doneButton"
        static var doneAnimation = "PreviewScreen.doneAnimation"
    }
    
    struct FormattingView {

        internal static let title = "FormattingView.title"
        
        struct Titles {
            internal static let sectionTitle =  "FormattingView.Titles.sectionTitle"
            internal static let sizeSlider = "FormattingView.Margin.Titles.sizeSlider"
            internal static let boldFontOption =  "FormattingView.Titles.boldFontOption"
            internal static let textColor = "FormattingView.Titles.textColor"
            internal static let textPosition =  "FormattingView.titles.textPosition"
            internal enum TextPosition {
                /// Bottom
                internal static let bottom = "FormattingView.Titles.TextPosition.bottom"
                /// Top
                internal static let top = "FormattingView.Titles.TextPosition.top"
            }
        }

        struct Margins {
            internal static let sectionTitle =  "FormattingView.Margins.sectionTitle"
            internal static let sizeSlider = "FormattingView.Margin.sizeSlider"
        }

        struct Gridlines {
            internal static let sectionTitle = "FormattingView.Gridlines.sectionTitle"
            internal static let colour = "FormattingView.Gridlines.colour"
            internal static let thicker = "FormattingView.Gridlines.thicker"
        }
        
        struct FitzgeraldKeys {
            internal static let sectionTitle = "FormattingView.FitzgeraldKeys.sectionTitle"
            internal static let thickerBorders = "FormattingView.FitzgeraldKeys.thickerBorders"
        }

    }
    
}
