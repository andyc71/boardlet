//
//  BoardPhotoCard.swift
//  PECS Maker
//
//  Created by Andy on 26/10/2026.
//
import SwiftUI

struct BoardPhotoCard: View {
    @ObservedObject var pageLayoutState: PageLayoutState
    let photos: [PhotoItem]
    let status: String
    let editPhoto: (PhotoItem) -> Void
    let changeSelections: () -> Void

    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            if photos.isEmpty {
                NoPhotosTipView(pageLayoutState: pageLayoutState,
                                source: .mainMenu,
                                presentation: .card)
                .padding(.small)
            } else {

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
                                    Button {
                                        editPhoto(photo)
                                    } label: {
                                        Image(uiImage: photo.image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: thumbnailSize, height: thumbnailSize)
                                            .padding(4)
                                            .background(AppSettings.photoBackgroundColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(BoardPalette.accent.opacity(0.4))
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(photo.title?.isEmpty == false
                                                        ? (photo.title ?? "") : L10n.PhotoSelectionView.untitledCell)
                                    .accessibilityIdentifier("ClassicMainMenu.photo.\(photo.itemID)")
                                }
                            }
                        }
                        
                        
                        if !photos.isEmpty {
                            Button( action: changeSelections ) {
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text(L10n.MainMenu.changeSelectionsButton)
                                    Image(systemName: .chevronRight)
                                        .font(.caption)
                                }
                            }
                            //.padding(.leading, 46 + 12) //46 is the size of the image at the top of this section. 12 is the spacing from that image to the text.
                            /*
                             CapsuleButton(L10n.MainMenu.changeSelectionsButton,
                             role: .secondary,
                             borderWidth: 0.5,
                             action: changeSelections)
                             .accessibilityIdentifier(AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
                             .accessibilityHint(L10n.MainMenu.changeSelectionsHint)
                             .frame(maxWidth: .infinity)
                             */
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
        .padding(16)
        .modifier(BoardCardSurface())
    }

}
