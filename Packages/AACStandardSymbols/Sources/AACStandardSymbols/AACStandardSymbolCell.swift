#if os(iOS)
import SwiftUI

struct AACStandardSymbolCell: View {
    let symbol: AACStandardSymbol
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                AsyncImage(url: symbol.previewURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFit()
                    case .failure: Image(systemName: "photo").foregroundStyle(.secondary)
                    case .empty:
                        if symbol.previewURL == nil { Image(systemName: "photo") }
                        else { ProgressView() }
                    @unknown default: Image(systemName: "photo")
                    }
                }
                .frame(height: 90)
                .accessibilityHidden(true)
                Text(symbol.title).font(.caption).frame(maxWidth: .infinity)
            }
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor).padding(4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
#endif
