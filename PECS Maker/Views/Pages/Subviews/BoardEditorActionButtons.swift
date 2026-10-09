import SwiftUI

struct BoardEditorActionButtons: View {
    @ScaledMetric(relativeTo: .caption) private var iconHeight = 16

    let vertical: Bool
    let action: (BoardEditorAction) -> Void

    var body: some View {
        let layout = vertical ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(alignment: .lastTextBaseline, spacing: 4))
        layout {
            ForEach(BoardEditorAction.allCases.filter { $0 != .useBoard || FeatureFlags.current.voiceEnabled }) { item in
                if !vertical {
                    Spacer(minLength: 4)
                }
                Button { action(item) } label: {
                    // An explicit label keeps toolbar adaptation from discarding the text.
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .frame(height: iconHeight)
                        Text(item.title).lineLimit(1)
                    }
                    .font(.caption)
                    .frame(maxWidth: vertical ? .infinity : nil)
                    .contentShape(Rectangle())
                }
                //.buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .accessibilityLabel(item.title)
                .accessibilityIdentifier(item.accessibilityID)
            }
            if !vertical {
                Spacer(minLength: 4)
            }

        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, vertical ? 8 : 0)
    }
}
