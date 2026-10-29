import SwiftUI

struct SnapButtonTile: View {
  let button: SnapButton
  let asset: SnapAsset?
  let height: CGFloat
  var hidden = false

  var body: some View {
    VStack(spacing: 3) {
      artwork
      label
        .frame(maxWidth: .infinity)
        .layoutPriority(1)
    }
    .padding(4)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .foregroundStyle(button.foregroundARGB.map { Color(snapARGB: $0) } ?? .primary)
    .background(button.backgroundARGB.map { Color(snapARGB: $0) } ?? Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 8))
    .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(button.borderARGB.map { Color(snapARGB: $0) } ?? Color.secondary.opacity(0.3)) }
    .overlay(alignment: .topTrailing) {
      if SnapCommunicationBehavior.resolve(button) == .destinations {
        Image(systemName: "arrow.up.right").font(.system(size: 10)).padding(3).accessibilityHidden(true)
      }
    }
  }

  @ViewBuilder private var artwork: some View {
    if let data = asset?.previewPNG, let image = UIImage(data: data) {
      ArtworkImage(image: image)
        .frame(maxWidth: max(12, height * 0.62), maxHeight: max(12, height * 0.62))
        .accessibilityHidden(true)
    } else if button.assetKey != nil {
      Image(systemName: "photo.badge.exclamationmark").resizable().scaledToFit()
        .frame(maxWidth: 28, maxHeight: 28)
        .foregroundStyle(.secondary).accessibilityHidden(true)
    }
  }

  private var label: some View {
    VStack(spacing: 6) {
      Text(button.label.isEmpty ? "Unlabelled" : button.label)
        .font(height < 90 ? .caption : .body).multilineTextAlignment(.center).lineLimit(2)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity)
      if hidden { Label("Hidden", systemImage: "eye.slash").font(.caption) }
    }
  }
}
