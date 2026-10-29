import SwiftUI
import SharedSwiftUI

/// Shared background, outline and shadow for the main menu's photo card and large actions.
struct BoardCardSurface: ViewModifier {
    var isFilled = false
    var isSelected = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.boardCardCornerRadius, style: .continuous)
        let accent = Color.mfVeryBrightBlue

        content
            .background(
                isFilled ? accent : Color(uiColor: .secondarySystemGroupedBackground),
                in: shape
            )
            .overlay(shape.strokeBorder(accent.opacity(isSelected ? 0.7 : 0.25),
                                        lineWidth: isSelected ? 2 : 1))
            .shadow(color: accent.opacity(0.07), radius: 8, y: 3)
    }
}
