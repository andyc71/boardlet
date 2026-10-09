import SwiftUI
import SharedSwiftUI

struct BoardEditorTitle: View {
    @EnvironmentObject private var currentTheme: SharedUITheme

    let title: String
    let selectionSubtitle: String?
    let isVerticalStack: Bool

    var body: some View {
        //Should we replace AdaptiveStack with AnyLayout(HStackLayout(spacing: 0)) ?
        AdaptiveStack(stackType: isVerticalStack ? .vertical(horizontalAlignment: .center) : .horizontal(verticalAlignment: .firstTextBaseline)) {
            HStack(spacing: 4) {
                Text(title).lineLimit(1)
                if selectionSubtitle == nil {
                    Image(systemName: "pencil").font(.caption).accessibilityHidden(true)
                }
            }
            .font(currentTheme.headerStyle.smallFont)
            if let selectionSubtitle {
                if !isVerticalStack {
                    Spacer()
                }
                Text(selectionSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(AccessibilityIdentifiers.PhotoSelectionView.selectionCountLabel)
            }
        }
    }
}
