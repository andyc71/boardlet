import SwiftUI

struct CardTile: View {
    let card: ScannedCard
    var height: CGFloat? = nil

    var body: some View {
        Group {
            if height != nil {
                ViewThatFits(in: .vertical) {
                    VStack(spacing: 8) {
                        artwork.frame(width: 70, height: 70)
                        caption
                    }
                    HStack(spacing: 12) {
                        artwork.frame(width: 70, height: 70)
                        caption
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    artwork.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                    caption
                }
            }
        }
        .padding(10)
        .frame(height: height)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary, lineWidth: 1) }
    }

    @ViewBuilder private var artwork: some View {
        if card.included, let image = UIImage(data: card.imagePNG) {
            Image(uiImage: image).resizable().scaledToFit().accessibilityHidden(true)
        } else {
            Image(systemName: "eye.slash").foregroundStyle(.secondary).accessibilityHidden(true)
        }
    }

    private var caption: some View {
        VStack(spacing: 8) {
            Text(card.included ? (card.label.isEmpty ? "Add label" : card.label) : "Hidden card")
                .font(.headline).multilineTextAlignment(.center).frame(minHeight: 28)
                .lineLimit(height == nil ? nil : 2)
            if card.needsReview {
                Label("Review", systemImage: "exclamationmark.circle").font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}
