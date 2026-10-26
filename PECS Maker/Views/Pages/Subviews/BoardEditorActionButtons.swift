import SwiftUI

struct BoardEditorActionButtons: View {
    let vertical: Bool
    var actions: [BoardEditorAction] = BoardEditorAction.allCases.filter {
        $0 != .useBoard || FeatureFlags.current.voiceEnabled
    }
    let action: (BoardEditorAction) -> Void

    var body: some View {
        let layout = vertical
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 0))
        layout {
            ForEach(actions) { item in
                Button { action(item) } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .font(.title3)
                            .frame(minHeight: 24)
                        Text(item.title)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .accessibilityLabel(item.title)
                .accessibilityIdentifier(item.accessibilityID)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
