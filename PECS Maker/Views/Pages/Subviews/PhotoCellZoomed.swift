//
//  TitleRow2.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import SwiftUI
import SharedSwiftUI

struct PhotoCellZoomed: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var presentationContext: ScenePresentationContext
    @ObservedObject var pageLayoutState: PageLayoutState
    @Binding var photo: PhotoItem?
    @State var editedPhoto: UIImage?
    @State private var photoToDelete: PhotoItem?
    @State private var draftTitle = ""
    @State private var cardTitleInitialized = false
    @State private var showPhotoSourceOptions = false
    @State private var showARASAACSymbolsPicker = false
    @State private var boardTitle = ""
    @State private var boardCover: PhotoItem?
    @State private var boardCoverWasReplaced = false
    @State private var boardCoverUsesGeneratedThumbnail = true
    @State private var boardDetailsInitialized = false
#if EasyPECSPlus
    @State private var showAACStandardSymbolsPicker = false
    @State private var showDVSymbolsPicker = false
    @State private var showAISymbolsPicker = false
#endif
    var onDelete: (PhotoItem) -> Void
    var isEmptySlot = false
    var isBoardDetails = false
    var index: Int?
    
    private var safeIndex: Int { index ?? 0 }
    private var currentPhoto: PhotoItem? { isBoardDetails ? boardCover : (photo?.isPlaceholder == true ? nil : photo) }

    private var titleBinding: Binding<String> {
        Binding(
            get: { isBoardDetails ? boardTitle : draftTitle },
            set: { newValue in
                if isBoardDetails {
                    boardTitle = newValue
                } else {
                    draftTitle = newValue
                }
            }
        )
    }

    private var photoFrameAspectRatio: CGFloat {
        if isBoardDetails { return pageLayoutState.aspectRatio }
        let size = pageLayoutState.individualCardMeasurements.sizeInMM
        return size.height > 0 ? size.width / size.height : 1
    }

    private func usesTwoColumnLayout(in size: CGSize) -> Bool {
        size.width >= 700 &&
            size.height >= 280 &&
            size.width >= size.height * 1.5 &&
            dynamicTypeSize <= .xxLarge
    }

    private func landscapePhotoPreviewHeight(in size: CGSize) -> CGFloat {
        let replaceRowHeight: CGFloat = 44
        let imageRowInsets: CGFloat = 16
        let sectionHeaderAndFormMargins: CGFloat = 88
        let reservedHeight = replaceRowHeight + imageRowInsets + sectionHeaderAndFormMargins
        return min(320, max(160, size.height - reservedHeight))
    }
    
#if EasyPECSPlus
    func eraseBackground() {
        guard let photo = currentPhoto else { return }
        guard let image =  photo.image.removeBackground(returnResult: .finalImage) else {
            return
        }
        editedPhoto = image
    }
#endif
    
    func cropPhoto() {
        guard let photo = currentPhoto else { return }
        let newImage = photo.image.trimWhitespace()
        editedPhoto = newImage
    }
    
    func save() {
        if isBoardDetails {
            pageLayoutState.title = boardTitle
            let isReturningToGeneratedCover = boardCoverUsesGeneratedThumbnail &&
                !pageLayoutState.generateTopicThumbnail
            if isReturningToGeneratedCover {
                pageLayoutState.useGeneratedTopicThumbnail(saveChanges: false)
            } else if let boardCover, boardCoverWasReplaced || editedPhoto != nil {
                let cover = boardCover.copy()
                if let editedPhoto { cover.image = editedPhoto }
                pageLayoutState.setTopicImage(cover, isUserSelection: true, saveChanges: false)
            }
            pageLayoutState.save()
            if isReturningToGeneratedCover {
                pageLayoutState.flushThumbnail()
            }
        } else if let photo {
            let titleChanged = draftTitle != (photo.title ?? "")
            if titleChanged { photo.title = draftTitle }
            if let editedPhoto { photo.image = editedPhoto }
            if titleChanged || editedPhoto != nil {
                // Committing once avoids rebuilding the collage on every keystroke.
                pageLayoutState.photosDidChange()
            }
        } else if isEmptySlot, !draftTitle.isEmpty {
            photo = pageLayoutState.photoBrowserData.fillEmptySlot(at: safeIndex, with: PhotoItem.blankCard(title: draftTitle))
            pageLayoutState.photosDidChange()
        }
    }
    
    func revert() {
        editedPhoto = nil
        if isBoardDetails && !boardCoverWasReplaced {
            boardCoverUsesGeneratedThumbnail = pageLayoutState.generateTopicThumbnail
        }
    }
    
    func saveAndClose() {
        save()
        dismiss()
    }

    private func replacePhoto(with replacement: PhotoItem) {
        if isBoardDetails {
            boardCover = replacement
            boardCoverWasReplaced = true
            boardCoverUsesGeneratedThumbnail = false
        } else if let photo {
            pageLayoutState.photoBrowserData.replacePhoto(photo, with: replacement)
            if let title = replacement.title { draftTitle = title }
        } else if isEmptySlot {
            let newPhoto = PhotoItem(image: replacement.image, asset: replacement.asset,
                                     assetId: replacement.assetId, title: draftTitle.isEmpty ? replacement.title : draftTitle,
                                     symbolSource: replacement.symbolSource)
            self.photo = pageLayoutState.photoBrowserData.fillEmptySlot(at: safeIndex, with: newPhoto)
            if let title = self.photo?.title { draftTitle = title }
        }
        editedPhoto = nil
    }

    var body: some View {
        GeometryReader { geometry in
            if photo != nil || isEmptySlot || isBoardDetails {
                let titleSection = ZoomedPhotoTitleSection(title: titleBinding)
#if EasyPECSPlus
                let eraseBackgroundAction = {
                    eraseBackground()
                    if isBoardDetails && editedPhoto != nil {
                        boardCoverUsesGeneratedThumbnail = false
                    }
                }
#else
                let eraseBackgroundAction: () -> Void = {}
#endif
                let actionsSection = ZoomedPhotoActionsSection(
                    hasPhoto: currentPhoto != nil,
                    hasEditedPhoto: editedPhoto != nil,
                    isBoardDetails: isBoardDetails,
                    usesGeneratedBoardCover: boardCoverUsesGeneratedThumbnail,
                    showsHeader: usesTwoColumnLayout(in: geometry.size),
                    onCrop: {
                        cropPhoto()
                        if isBoardDetails { boardCoverUsesGeneratedThumbnail = false }
                    },
                    onEraseBackground: eraseBackgroundAction,
                    onEditPhoto: {
                        guard let photo = currentPhoto else { return }
                        guard let presenter = presentationContext.presenter else { return }
                        PhotoPresentation.edit(editedPhoto ?? photo.image, theme: currentTheme,
                                               from: presenter) { image in
                            editedPhoto = image
                            if isBoardDetails { boardCoverUsesGeneratedThumbnail = false }
                        }
                    },
                    onRevert: revert,
                    onDuplicate: {
                        guard let photo = currentPhoto else { return }
                        pageLayoutState.duplicatePhotos([photo])
                    },
                    onUseAsBoardCover: {
                        guard let photo = currentPhoto else { return }
                        let cover = photo.copy()
                        if let editedPhoto { cover.image = editedPhoto }
                        pageLayoutState.setTopicImage(cover, isUserSelection: true, saveChanges: true)
                    },
                    onUseGeneratedBoardCover: {
                        boardCover = PhotoItem(image: pageLayoutState.createTopicImage())
                        boardCoverWasReplaced = false
                        boardCoverUsesGeneratedThumbnail = true
                        editedPhoto = nil
                    },
                    onDelete: {
                        photoToDelete = currentPhoto
                    }
                )
                Group {
                    if usesTwoColumnLayout(in: geometry.size) {
                        let columnSpacing: CGFloat = 16
                        let availableWidth = geometry.size.width - columnSpacing
                        HStack(spacing: columnSpacing) {
                            Form {
                                ZoomedPhotoMediaSection(
                                    image: editedPhoto ?? currentPhoto?.image,
                                    aspectRatio: photoFrameAspectRatio,
                                    accessibilityID: AccessibilityIdentifiers.TitlesScreen.image(for: safeIndex),
                                    previewHeight: landscapePhotoPreviewHeight(in: geometry.size),
                                    replaceTitle: currentPhoto == nil ? L10n.PhotoZoomView.addPhotoButton : L10n.PhotoZoomView.replacePhotoButton,
                                    replaceSymbol: currentPhoto == nil ? "plus" : "arrow.triangle.2.circlepath",
                                    compactReplaceRow: true,
                                    headerTitle: L10n.PhotoZoomView.photoSectionTitle
                                ) {
                                    showPhotoSourceOptions = true
                                }
                            }
                            .frame(width: availableWidth * 0.4)
                            .modifier(ZoomedPhotoLandscapeFormStyle())
                            .scrollDisabled(true)

                            Form {
                                titleSection
                                actionsSection
#if DEBUG
                                if !isBoardDetails, let debugInfo = photo?.debugInfo {
                                    ZoomedPhotoDebugSection(debugInfo: debugInfo)
                                }
#endif
                            }
                            .frame(width: availableWidth * 0.6)
                            .modifier(ZoomedPhotoLandscapeFormStyle())
                        }
                    } else {
                        Form {
                            ZoomedPhotoMediaSection(
                                image: editedPhoto ?? currentPhoto?.image,
                                aspectRatio: photoFrameAspectRatio,
                                accessibilityID: AccessibilityIdentifiers.TitlesScreen.image(for: safeIndex),
                                previewHeight: min(280, max(120, geometry.size.height * 0.4)),
                                replaceTitle: currentPhoto == nil ? L10n.PhotoZoomView.addPhotoButton : L10n.PhotoZoomView.replacePhotoButton,
                                replaceSymbol: currentPhoto == nil ? "plus" : "arrow.triangle.2.circlepath"
                            ) {
                                showPhotoSourceOptions = true
                            }
                            titleSection
                            actionsSection
#if DEBUG
                            if !isBoardDetails, let debugInfo = photo?.debugInfo {
                                ZoomedPhotoDebugSection(debugInfo: debugInfo)
                            }
#endif
                        }
                    }
                }
                .navigationTitle(isBoardDetails ? L10n.PhotoSelectionView.boardDetails : L10n.PhotoZoomView.editCardTitle)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    CancelToolbarItem(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton) {
                        dismiss()
                    }
                    ConfirmToolbarItem(id: AccessibilityIdentifiers.PhotoZoomView.saveButton) {
                        saveAndClose()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
                .confirmationDialog(currentPhoto == nil ? L10n.PhotoZoomView.addPhotoButton : L10n.PhotoZoomView.replacePhotoButton,
                                    isPresented: $showPhotoSourceOptions, titleVisibility: .visible) {
                    Button(L10n.PhotoSelectionView.photoLibrary, systemImage: "photo") {
                        guard let presenter = presentationContext.presenter else { return }
                        selectTopicPhoto(currentTheme: currentTheme, from: presenter) { image in
                            replacePhoto(with: PhotoItem(image: image))
                        }
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.PhotoZoomView.replaceFromLibraryButton)
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button(L10n.PhotoSelectionView.camera, systemImage: "camera") {
                            guard let presenter = presentationContext.presenter else { return }
                            takePhoto(from: presenter) { image in
                                replacePhoto(with: PhotoItem(image: image))
                            }
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.PhotoZoomView.replaceFromCameraButton)
                    }
#if EasyPECSPlus
                    Button(L10n.Symbols.aacStandard) { showAACStandardSymbolsPicker = true }
                    Button(L10n.Symbols.dynavox) { showDVSymbolsPicker = true }
                    Button(L10n.Symbols.createWithAI) { showAISymbolsPicker = true }
#endif
                    if FeatureFlags.current.arasaacSymbolsEnabled {
                        Button(L10n.Symbols.arasaac) { showARASAACSymbolsPicker = true }
                    }
                }
    #if EasyPECSPlus
                .selectAACStandardSymbols(isPresented: $showAACStandardSymbolsPicker,
                                          pageLayoutState: pageLayoutState, onSelect: replacePhoto(with:))
                .selectDVSymbols(isPresented: $showDVSymbolsPicker,
                                 pageLayoutState: pageLayoutState, onSelect: replacePhoto(with:))
                .selectAISymbols(isPresented: $showAISymbolsPicker,
                                 pageLayoutState: pageLayoutState, onSelect: replacePhoto(with:))
    #endif
                .selectARASAACSymbols(isPresented: $showARASAACSymbolsPicker,
                                      pageLayoutState: pageLayoutState, onSelect: replacePhoto(with:))
                .askToDeletePhoto(photo: $photoToDelete, theme: currentTheme) { photo in
                    self.photo = nil
                    onDelete(photo)
                }
                .onAppear {
                    if !isBoardDetails && !cardTitleInitialized {
                        draftTitle = photo?.title ?? ""
                        cardTitleInitialized = true
                    }
                    if isBoardDetails && !boardDetailsInitialized {
                        boardTitle = pageLayoutState.title
                        boardCover = pageLayoutState.topicImage
                        boardCoverWasReplaced = false
                        boardCoverUsesGeneratedThumbnail = pageLayoutState.generateTopicThumbnail
                        boardDetailsInitialized = true
                    }
                }
            }
            else {
                EmptyView()
            }
        }
    }
}

private struct ZoomedPhotoMediaSection: View {
    let image: UIImage?
    let aspectRatio: CGFloat
    let accessibilityID: String
    let previewHeight: CGFloat
    let replaceTitle: String
    let replaceSymbol: String
    var compactReplaceRow = false
    var headerTitle: String? = nil
    let onReplace: () -> Void

    var body: some View {
        Section {
            ZoomedPhotoFrame(image: image,
                             aspectRatio: aspectRatio,
                             accessibilityID: accessibilityID)
                .frame(height: previewHeight)
                .frame(maxWidth: .infinity)
            ZoomedPhotoActionButton(replaceTitle,
                                    symbol: replaceSymbol,
                                    id: AccessibilityIdentifiers.PhotoZoomView.replaceButton,
                                    minimumHeight: compactReplaceRow ? 44 : nil,
                                    action: onReplace)
                .listRowInsets(compactReplaceRow
                               ? EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
                               : nil)
        } header: {
            if let headerTitle {
                Text(headerTitle)
            }
        }
    }
}

private struct ZoomedPhotoTitleSection: View {
    @Binding var title: String

    var body: some View {
        Section(L10n.TitlesPage.titleTextPlaceholder) {
            TextField(L10n.TitlesPage.titleTextPlaceholder, text: $title)
                .accessibilityIdentifier(AccessibilityIdentifiers.PhotoZoomView.titleField)
        }
    }
}

private struct ZoomedPhotoActionsSection: View {
    let hasPhoto: Bool
    let hasEditedPhoto: Bool
    let isBoardDetails: Bool
    let usesGeneratedBoardCover: Bool
    var showsHeader = false
    let onCrop: () -> Void
    let onEraseBackground: () -> Void
    let onEditPhoto: () -> Void
    let onRevert: () -> Void
    let onDuplicate: () -> Void
    let onUseAsBoardCover: () -> Void
    let onUseGeneratedBoardCover: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Section {
            if hasPhoto {
                if !hasEditedPhoto {
                    ZoomedPhotoActionButton(L10n.PhotoZoomView.cropButton,
                                            symbol: "crop",
                                            id: AccessibilityIdentifiers.PhotoZoomView.cropButton,
                                            action: onCrop)
#if EasyPECSPlus
                    ZoomedPhotoActionButton(L10n.PhotoZoomView.eraseBackgroundButton,
                                            symbol: "wand.and.stars",
                                            id: AccessibilityIdentifiers.PhotoZoomView.eraseBackgroundButton,
                                            action: onEraseBackground)
#endif
                }

                ZoomedPhotoActionButton(L10n.PhotoZoomView.editPhotoButton,
                                        symbol: "pencil",
                                        id: AccessibilityIdentifiers.PhotoZoomView.editPhotoButton,
                                        action: onEditPhoto)

                if hasEditedPhoto {
                    ZoomedPhotoActionButton(L10n.PhotoZoomView.revertButton,
                                            symbol: "arrow.uturn.backward",
                                            id: AccessibilityIdentifiers.PhotoZoomView.revertButton,
                                            action: onRevert)
                }

                if !isBoardDetails {
                    ZoomedPhotoActionButton(L10n.PhotoZoomView.duplicateCardButton,
                                            symbol: "square.on.square",
                                            id: AccessibilityIdentifiers.PhotoZoomView.duplicateCardButton,
                                            action: onDuplicate)
                    ZoomedPhotoActionButton(L10n.PhotoZoomView.useAsBoardCoverButton,
                                            symbol: "photo",
                                            id: AccessibilityIdentifiers.PhotoZoomView.useAsBoardCoverButton,
                                            action: onUseAsBoardCover)

                    Button(role: .destructive, action: onDelete) {
                        Label(L10n.PhotoZoomView.removePhotoButton, systemImage: "trash")
                            .labelStyle(.titleAndIcon)
                    }
                    .foregroundColor(.red)
                    .accessibilityIdentifier(AccessibilityIdentifiers.PhotoZoomView.deleteButton)
                } else if !usesGeneratedBoardCover {
                    ZoomedPhotoActionButton(L10n.TopicImageSelector.useGeneratedThumbnailButton,
                                            symbol: "rectangle.stack",
                                            id: AccessibilityIdentifiers.PhotoZoomView.useGeneratedThumbnailButton,
                                            action: onUseGeneratedBoardCover)
                }
            }
        } header: {
            if showsHeader {
                Text(L10n.PhotoZoomView.actionsSectionTitle)
            }
        }
    }
}

#if DEBUG
private struct ZoomedPhotoDebugSection: View {
    let debugInfo: [String]

    var body: some View {
        Section {
            VStack {
                ForEach(debugInfo, id: \.self) { debugString in
                    Text(debugString)
                }
            }
        }
    }
}
#endif

private struct ZoomedPhotoActionButton: View {
    let title: String
    let symbol: String
    let id: String
    let minimumHeight: CGFloat?
    let action: () -> Void

    init(_ title: String,
         symbol: String,
         id: String,
         minimumHeight: CGFloat? = nil,
         action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.id = id
        self.minimumHeight = minimumHeight
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .labelStyle(.titleAndIcon)
                .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
                .contentShape(Rectangle())
        }
            //.buttonStyle(.plain)
            //.foregroundColor(.accentColor)
            //.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .accessibilityIdentifier(id)
    }
}

private struct ZoomedPhotoLandscapeFormStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentMargins(.top, 8, for: .scrollContent)
                .listSectionSpacing(.custom(16))
        } else {
            // Match the reduced iOS 17+ form margin without changing portrait forms.
            content.padding(.top, -24)
        }
    }
}

private struct ZoomedPhotoTitleStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            configuration.label
            configuration.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ZoomedPhotoFrame: View {
    let image: UIImage?
    let aspectRatio: CGFloat
    let accessibilityID: String

    var body: some View {

        RoundedRectangle(cornerRadius: 5)
            .fill(AppSettings.photoBackgroundColor)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        //.padding(8)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.secondary, lineWidth: 1)
            }
            .accessibilityIdentifier(accessibilityID)
    }
}
