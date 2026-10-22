import SwiftUI
import SharedSwiftUI

struct WelcomeView: View {
    let onChoose: (StartupExperience.StartingPoint) -> Void
    @EnvironmentObject private var currentTheme: SharedUITheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 20) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        GetStartedArtwork()
                            .frame(height: 148)
                            .accessibilityHidden(true)
                    }

                    VStack(spacing: 10) {
                        Text(L10n.Welcome.title)
                            .font(.custom(Theme.headerFontName, size: 24, relativeTo: .title2))
                            .foregroundStyle(Color.mfVeryBrightBlue)
                        Text(L10n.Welcome.getStartedQuestion)
                            .font(.system(.largeTitle, design: .rounded).bold())
                            .foregroundStyle(Color(currentTheme.headerStyle.textColor))
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("Welcome.title")
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 16) {
                    WelcomeChoiceCard(title: L10n.Welcome.readyMade,
                                      detail: L10n.Welcome.readyMadeDetail,
                                      symbol: "square.grid.2x2.fill", isProminent: true) {
                        onChoose(.readyMadeBoards)
                    }
                    .accessibilityIdentifier("Welcome.readyMadeBoards")

                    WelcomeChoiceCard(title: L10n.Welcome.blankBoard,
                                      detail: L10n.Welcome.blankBoardDetail,
                                      symbol: "plus", isProminent: false) {
                        onChoose(.blankBoard)
                    }
                    .accessibilityIdentifier("Welcome.blankBoard")
                }

                Text(L10n.Welcome.getStartedReassurance)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea())
    }
}
