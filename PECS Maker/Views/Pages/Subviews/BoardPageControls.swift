import SwiftUI

struct BoardPageControls: View {
    @Binding var selectedPage: Int
    let pageCount: Int
    let compact: Bool
    let onDropPage: ([String], Int) -> Bool

    var body: some View {
        HStack(spacing: 0) {
            if !compact, pageCount > 1 {
                Button { selectedPage -= 1 } label: {
                    Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(L10n.PreviewPage.previousPage)
                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.previousPage)
                .disabled(selectedPage == 0)
                .dropDestination(for: String.self) { items, _ in onDropPage(items, selectedPage - 1) }
                Spacer(minLength: 0)
                Text(L10n.PreviewPage.pageStatus(selectedPage + 1, pageCount))
                    .font(.caption).monospacedDigit()
                    .accessibilityIdentifier("BoardEditor.pageStatus")
            }
            if !compact { Spacer(minLength: 0) }
            if compact, pageCount > 1 {
                Menu {
                    Picker(L10n.PreviewPage.pageStatus(selectedPage + 1, pageCount), selection: $selectedPage) {
                        ForEach(0..<pageCount, id: \.self) { page in
                            Text(L10n.PreviewPage.pageStatus(page + 1, pageCount)).tag(page)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    BoardPageNumberIcon(number: selectedPage + 1)
                        .frame(minWidth: 32, minHeight: 32)
                }
                .accessibilityLabel(L10n.PreviewPage.pageStatus(selectedPage + 1, pageCount))
                .accessibilityIdentifier("BoardEditor.pagePicker")
            }
            if !compact, pageCount > 1 {
                Button { selectedPage += 1 } label: {
                    Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(L10n.PreviewPage.nextPage)
                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.nextPage)
                .disabled(selectedPage >= pageCount - 1)
                .dropDestination(for: String.self) { items, _ in onDropPage(items, selectedPage + 1) }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, compact ? 0 : 12)
    }
}

private struct BoardPageNumberIcon: View {
    let number: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(systemName: "doc")
                .font(.system(size: 32, weight: .light))
            Text(number, format: .number)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                //.monospacedDigit()
                .padding(.bottom, 5)
        }
        .accessibilityHidden(true)
    }
}
