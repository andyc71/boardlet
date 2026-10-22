import SwiftUI
import SharedSwiftUI

struct WelcomeChoiceCard: View {
    let title: String
    let detail: String
    let symbol: String
    let isProminent: Bool
    let action: () -> Void
    @EnvironmentObject private var currentTheme: SharedUITheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol)
                        .font(.title2.bold())
                        .frame(width: 46, height: 46)
                        .background(isProminent ? Color.white.opacity(0.16) : Theme.selectionHighlightColor,
                                    in: RoundedRectangle(cornerRadius: 14))
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).bold())
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(isProminent ? Color.white : Color.primary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .font(.subheadline.bold())
                    .padding(.top, 4)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(isProminent ? Color.white : Color(currentTheme.headerStyle.textColor))
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isProminent ? Color("mfBoardActionBlue") : currentTheme.cardBackgroundColor,
                        in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(isProminent ? Color.clear : Color.mfVeryBrightBlue.opacity(0.18), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .multilineTextAlignment(.leading)
        .accessibilityLabel(title)
        .accessibilityHint(detail)
        .accessibilityInputLabels([title])
    }
}
