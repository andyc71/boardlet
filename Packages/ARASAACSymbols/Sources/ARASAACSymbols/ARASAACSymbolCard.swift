import SwiftUI

struct ARASAACSymbolCard: View {
    let symbol: ARASAACSymbol
    let isSelected: Bool
    let style: ARASAACPickerStyle
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 10) {
                AsyncImage(url: symbol.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFit()
                    case .failure: Image(systemName: "photo").foregroundStyle(.gray)
                    default: ProgressView()
                    }
                }
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                Text(symbol.title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .frame(maxWidth: .infinity)
            }
            .padding(10)
            .background(isSelected ? style.selection.opacity(0.2) : Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(isSelected ? style.accent : .primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? style.accent : .gray)
                    .background(.white, in: Circle())
                    .padding(16)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
