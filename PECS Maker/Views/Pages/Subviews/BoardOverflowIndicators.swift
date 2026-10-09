import SwiftUI

struct BoardOverflowIndicators: View {
    let overflow: BoardPageViewport.Overflow
    let scroll: (UnitPoint) -> Void

    var body: some View {
        Color.clear.allowsHitTesting(false)
            .overlay(alignment: .leading) {
                if overflow.left { arrow("arrow.left", label: L10n.BoardEditor.moreLeft, id: "left") }
            }
            .overlay(alignment: .trailing) {
                if overflow.right { arrow("arrow.right", label: L10n.BoardEditor.moreRight, id: "right") }
            }
            .overlay(alignment: .top) {
                if overflow.top { arrow("arrow.up", label: L10n.BoardEditor.moreAbove, id: "top") }
            }
            .overlay(alignment: .bottom) {
                if overflow.bottom { arrow("arrow.down", label: L10n.BoardEditor.moreBelow, id: "bottom") }
            }
    }

    private func arrow(_ symbol: String, label: String, id: String) -> some View {
        Button {
            scroll(UnitPoint(x: id == "left" ? -1 : id == "right" ? 1 : 0,
                             y: id == "top" ? -1 : id == "bottom" ? 1 : 0))
        } label: {
            Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 30, height: 30)
            .background(.regularMaterial, in: Circle())
            .shadow(color: .black.opacity(0.2), radius: 2)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
            .accessibilityIdentifier("BoardEditor.more.\(id)")
    }
}
