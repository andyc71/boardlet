import SwiftUI

struct BoardPageControls: View {
    @Binding var selectedPage: Int
    let pageCount: Int
    let onDropPage: ([String], Int) -> Bool

    var body: some View {
        Menu {
            ForEach(0..<pageCount, id: \.self) { page in
                Button {
                    selectedPage = page
                } label: {
                    if page == selectedPage {
                        Label(L10n.PreviewPage.pageStatus(page + 1, pageCount), systemImage: "checkmark")
                    } else {
                        Text(L10n.PreviewPage.pageStatus(page + 1, pageCount))
                    }
                }
                .dropDestination(for: String.self) { items, _ in onDropPage(items, page) }
            }
        } label: {
            Text(selectedPage + 1, format: .number)
                .monospacedDigit()
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel(L10n.PreviewPage.pageStatus(selectedPage + 1, pageCount))
        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.pagePicker)
    }
}
