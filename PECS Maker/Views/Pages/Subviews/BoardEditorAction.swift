import SwiftUI

enum BoardEditorAction: String, CaseIterable, Identifiable {
    case layout, format, share, print, useBoard
    var id: String { rawValue }

    var title: String {
        switch self {
        case .layout: L10n.PhotoSelectionView.layoutAction
        case .format: L10n.BoardEditor.formatAction
        case .share: L10n.PhotoSelectionView.shareAction
        case .print: L10n.PhotoSelectionView.printAction
        case .useBoard: L10n.MainMenu.choiceBoardButton
        }
    }

    var symbol: String {
        switch self {
        case .layout: "square.grid.2x2"
        case .format: "paintbrush"
        case .share: "square.and.arrow.up"
        case .print: "printer"
        case .useBoard: "play.fill"
        }
    }

    var accessibilityID: String {
        switch self {
        case .layout: AccessibilityIdentifiers.PhotoSelectionView.layoutButton
        case .format: AccessibilityIdentifiers.PreviewScreen.formattingButton
        case .share: AccessibilityIdentifiers.PhotoSelectionView.shareButton
        case .print: AccessibilityIdentifiers.PhotoSelectionView.printButton
        case .useBoard: AccessibilityIdentifiers.PhotoSelectionView.useBoardButton
        }
    }
}
