//
//  AccessibilityIdentifiers.swift
//  PECS Maker
//
//  Created by Andy on 25/03/2022.
//

import Foundation
import UIKit

enum PageOrientation: String, CaseIterable, Codable { case portrait, landscape }

enum PageSize: String, CaseIterable, Identifiable, Codable {
    var id: String { self.rawValue }
    case a4 = "A4"
    case usLetter = "US Letter"
    case photo10by15 = "10x15 Photo Paper"
}

struct PageLayoutType : Hashable, Codable {
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
    
}
