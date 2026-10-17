//
//  ConfirmToolbarButton.swift
//  PECS Maker
//
//  Created by Andy on 05/10/2026.
//
import SwiftUI

/// Standard Done button.
/// Wrapper around `Button(role: .confirm) { }`
/// with a fallback for older versions.
struct ConfirmToolbarItem: ToolbarContent {
    let id: String
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if #available(iOS 26.0, *) {
                Button(role: .confirm, action: action)
                    .accessibilityIdentifier(id)
            } else {
                Button(L10n.PhotoZoomView.saveButton, systemImage: "checkmark", action: action)
                    .accessibilityIdentifier(id)
            }
        }
    }
}


/// Standard Cancel button.
/// Wrapper around `Button(role: .cancel) { }`
/// with a fallback for older versions.
struct CancelToolbarItem: ToolbarContent {
    let id: String
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if #available(iOS 26.0, *) {
                Button(role: .cancel, action: action)
                    .accessibilityIdentifier(id)
            } else {
                Button(L10n.PhotoZoomView.cancelButton, systemImage: "xmark", role: .cancel, action: action)
                    .accessibilityIdentifier(id)
            }
        }
    }
}

/// Standard Done button.
/// Wrapper around `Button(role: .cancel) { }`
/// with a fallback for older versions.
struct DoneToolbarItem: ToolbarContent {
    let id: String
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(L10n.PhotoSelectionView.closeSelection, action: action)
                .accessibilityIdentifier(id)
        }
    }
}

