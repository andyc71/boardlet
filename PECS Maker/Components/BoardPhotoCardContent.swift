import SwiftUI

/// The populated photo card's heading, editable thumbnails and selection action.
struct BoardPhotoCardContent: View {
    let photos: [PhotoItem]
    let status: String
    let editPhoto: (PhotoItem) -> Void
    let changeSelections: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BoardCardIcon(icon: "photo.on.rectangle")
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.MainMenu.photosCardTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(status)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(photos, id: \.id) { photo in
                            BoardPhotoThumbnail(photo: photo) {
                                editPhoto(photo)
                            }
                        }
                    }
                }

                Button(action: changeSelections) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(L10n.MainMenu.changeSelectionsButton)
                        Image(systemName: .chevronRight)
                            .font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
