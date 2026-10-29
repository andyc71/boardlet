import SwiftUI

struct ClassicPreviewActionLabel: View {
    let title: String
    let symbol: String
    let usesRow: Bool

    private var layout: AnyLayout {
        usesRow ? AnyLayout(HStackLayout(spacing: 10)) : AnyLayout(VStackLayout(spacing: 5))
    }

    var body: some View {
        layout {
            Image(systemName: symbol)
                .font(usesRow ? .body : .title3)
                .foregroundStyle(.tint)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .font(usesRow ? .subheadline : .caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, usesRow ? 10 : 6)
        .padding(.vertical, usesRow ? 2 : 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: usesRow ? .leading : .center)
        .contentShape(Rectangle())
    }
}
