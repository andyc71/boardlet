import SwiftUI

struct CardArtwork: View {
    let card: Card
    let mediaURL: URL
    var body: some View {
        Group {
            if let name = card.image, let image = ArtworkCache.shared.image(at: mediaURL.appendingPathComponent(name)) {
                Image(uiImage: image).resizable().scaledToFit()
            } else if let symbol = card.systemSymbol {
                Image(systemName: symbol).resizable().scaledToFit().padding().foregroundStyle(.blue)
            } else {
                Image(systemName: "photo").resizable().scaledToFit().padding().foregroundStyle(.secondary)
            }
        }.accessibilityHidden(true)
    }
}

struct CardTile: View {
    let card: Card
    let mediaURL: URL
    var selected = false
    var labelsAbove = false
    var body: some View {
        VStack {
            if labelsAbove { Text(card.label.isEmpty ? L("Untitled card") : card.label).font(.headline).multilineTextAlignment(.center) }
            CardArtwork(card: card, mediaURL: mediaURL).frame(minHeight: 64, idealHeight: 120, maxHeight: 160)
            if !labelsAbove { Text(card.label.isEmpty ? L("Untitled card") : card.label).font(.headline).multilineTextAlignment(.center) }
            if selected { Label("Selected", systemImage: "checkmark.circle.fill").font(.caption) }
        }
        .padding().frame(maxWidth: .infinity, minHeight: 140)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(selected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: selected ? 3 : 1) }
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.label.isEmpty ? L("Untitled card") : card.label)
        .accessibilityValue(selected ? L("Selected") : "")
    }
}
