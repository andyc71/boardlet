import Foundation

typealias A12SSUI = AccessibilityIdentifiersSSUI

enum AccessibilityIdentifiersSSUI {
    enum Alert {
        static let yesButton = "Alert.yesButton"
        static let noButton = "Alert.noButton"
        static let saveButton = "Alert.saveButton"
        static let cancelButton = "Alert.cancelButton"
        static let textField = "Alert.textField"
        static let textFieldClearButton = "Alert.textFieldClearButton"
        static let title = "Alert.title"
        static let message = "Alert.message"
    }

    enum PopupHeader {
        static let title = "PopupHeader.title"
        static let closeButton = "PopupHeader.closeButton"
        static let minimizeButton = "PopupHeader.minimizeButton"
        static let maximizeButton = "PopupHeader.maximizeButton"
        static let shareButton = "PopupHeader.shareButton"
        static let backButton = "PopupHeader.backButton"
        static let menuButton = "PopupHeader.menuButton"
    }

    enum Animations {
        static let doneAnimation = "Animations.done"
        static let thankYou = "Animations.thankYou"
    }

    enum PhotoCell {
        private static let imagePrefix = "PhotoSelectionScreen.image."
        private static let titlePrefix = "PhotoSelectionScreen.title."
        private static let selectButtonPrefix = "PhotoSelectionScreen.selectButton."
        private static let deleteButtonPrefix = "PhotoSelectionScreen.deleteButton."

        static func image(for index: Int) -> String {
            "\(imagePrefix)\(index)"
        }

        static func title(for index: Int) -> String {
            "\(titlePrefix)\(index)"
        }

        static func selectButton(for index: Int) -> String {
            "\(selectButtonPrefix)\(index)"
        }

        static func deleteButton(for index: Int) -> String {
            "\(deleteButtonPrefix)\(index)"
        }
    }
}
