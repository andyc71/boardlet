import SwiftUI
import SharedSwiftUI

/// Preserved for a future interface-preference step; first launch currently assumes Screen.
struct ScreenPaperWelcomeView: View {
    let onContinue: (InterfaceStyle) -> Void
    @State private var selection: InterfaceStyle = .modern
    @EnvironmentObject private var currentTheme: SharedUITheme
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 34

    private let accent = Color.mfVeryBrightBlue

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WelcomeArtwork()
                    .frame(height: 172)
                    .padding(.top, 28)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(L10n.Welcome.title)
                        .font(.system(size: titleSize, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(Color(currentTheme.headerStyle.textColor))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("Welcome.title")
                    Text(L10n.Welcome.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Welcome.question)
                        .font(.headline)
                        .padding(.bottom, 2)
                    choice(.modern, title: L10n.Welcome.screen, detail: L10n.Welcome.screenDetail,
                           icon: "ipad.landscape")
                    choice(.classic, title: L10n.Welcome.paper, detail: L10n.Welcome.paperDetail,
                           icon: "printer")
                }

                VStack(spacing: 14) {
                    Button {
                        onContinue(selection)
                    } label: {
                        HStack {
                            Spacer()
                            Text(L10n.Welcome.continueButton).font(.headline)
                            Spacer()
                            Image(systemName: "arrow.right").font(.headline)
                        }
                        .padding(18)
                        .foregroundStyle(.white)
                        .background(Color("mfBoardActionBlue"), in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("Welcome.continue")
                    Text(L10n.Welcome.reassurance)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
        }
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea())
    }

    private func choice(_ style: InterfaceStyle, title: String, detail: String, icon: String) -> some View {
        let selected = selection == style
        return Button {
            selection = style
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.mfDarkBlue)
                    .frame(width: 48, height: 54)
                    .background(Theme.selectionHighlightColor, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.headline)
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? accent : Color.secondary.opacity(0.5))
            }
            .padding(16)
            .background(currentTheme.cardBackgroundColor,
                        in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(selected ? accent : Color.primary.opacity(0.08),
                                  lineWidth: selected ? 2 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(style == .modern ? "Welcome.screen" : "Welcome.paper")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
