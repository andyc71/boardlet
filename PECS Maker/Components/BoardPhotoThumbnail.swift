import SwiftUI

struct BoardPhotoThumbnail: View {
    let photo: PhotoItem
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 50

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.boardContentCornerRadius,
                                     style: .continuous)

        Button(action: action) {
            Image(uiImage: photo.image)
                .resizable()
                .scaledToFit()
                .frame(width: thumbnailSize, height: thumbnailSize)
                .padding(4)
                .background(AppSettings.photoBackgroundColor)
                .clipShape(shape)
                .overlay {
                    shape.strokeBorder(BoardPalette.accent.opacity(0.4))
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(photo.title?.isEmpty == false
                            ? (photo.title ?? "") : L10n.PhotoSelectionView.untitledCell)
        .accessibilityIdentifier("ClassicMainMenu.photo.\(photo.itemID)")
    }
}
