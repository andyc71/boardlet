import SwiftUI

struct BoardPhotoCard: View {
    @ObservedObject var pageLayoutState: PageLayoutState
    let photos: [PhotoItem]
    let status: String
    let editPhoto: (PhotoItem) -> Void
    let changeSelections: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if photos.isEmpty {
                NoPhotosTipView(pageLayoutState: pageLayoutState,
                                source: .mainMenu,
                                presentation: .card)
                    .padding(.small)
            } else {
                BoardPhotoCardContent(
                    photos: photos,
                    status: status,
                    editPhoto: editPhoto,
                    changeSelections: changeSelections
                )
            }
        }
        .padding(16)
        .modifier(BoardCardSurface())
    }
}
