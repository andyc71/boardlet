//
//  PagePreviewView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import PhotosUI
import Combine
import AVKit
import StoreKit
import LogFramework
import LazyViewSwiftUI
import SharedSwiftUI
import RatingFramework
import LogFrameworkFirebase
import FeatureFramework

///Flow:
///1. User taps a save button to launch the ActivityViewController, or taps Print to launch the system print controller directly.
///2. The presented controller calls its completion handler.
///3. AVC completion handler sets a successMessage to say what was done, and isShowingSuccessAlert=true to cause the Success message box alert to appear.
///4. Success message box alert is dismissed, and RatingHelper.signifcantEventOccurred is called with a callback that sets isShowingSuccessAlert=true to cause the Rating alert message box to appear.
///5. Rating alert message box asks the user if they want to rate the app, and if so, calls SKStoreReviewController.requestReviewInCurrentScene; otherwise just records that the user doesn't want to rate.
///Note that the two alerts have not been placed on the VStack because they would override each other. Instead they have been
///placed on arbitrary views withing the VStack.

struct PagePreviewView: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    @EnvironmentObject private var featuresViewModel: FeaturesViewModel
    @EnvironmentObject private var presentationContext: ScenePresentationContext
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State var isShowingShareSheet: Bool = false
    @State var exportFormat: ExportCollageFormat = .pdf

    @State var isShowingSuccessAlert: Bool = false
    @State private var isSavingToPhotoLibrary = false
    @State private var isShowingPhotoLibraryError = false
    @State private var photoLibraryErrorMessage = ""
    
    //@State var isShowingRatingAlert: Bool = false
    //@State var ratingAlertState: RatingStage = .initialQuestion
    @EnvironmentObject var ratingStateMachine: RatingStateMachine2
    
    @State var isShowingFormatting: Bool = false
    @EnvironmentObject private var navigationModel: NavigationModel
    @State private var cardListPath: [AppRoute] = []
    @State private var isShowingCardList = false
    @State private var selectedPreviewPage = 0
    @State private var boardZoom = BoardPageViewport.fitZoom
    
    @State var successMessage: String = ""
    
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private let paddingAmount: CGFloat = 12
    
    private var minToggleWidth: CGFloat {
        return AppSettings.maxButtonWidth - (2 * paddingAmount)
    }
    
    private var maxToggleWidth: CGFloat {
        if horizontalSizeClass == .compact {
            return AppSettings.maxButtonWidth - (2 * paddingAmount)
        }
        else {
            let widthOfButtons = (2 * AppSettings.maxButtonWidth) + paddingAmount
            return widthOfButtons
        }
    }
    
    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
    }

    
    func activityCompletionHandler(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) {
        
        
        //print("Completion handler: completed - \(completed)")
        
        //TODO: display any errors returned in error.
        if let error = error {
            logger.logError(.general, "Error returned from UI Activity controller", error)
        }
        
        
        let saveToFilesActivityType = UIActivity.ActivityType("com.apple.DocumentManagerUICore.SaveToFiles")
        
        ////Users/andy/Library/Developer/CoreSimulator/Devices/79F23C03-EA23-424E-A86F-EF734A231E96/data/Containers/Shared/AppGroup/D42B885A-9F13-488B-88B6-E543AA40FED3/File Provider Storage/PECS.pdf
        ///
        //NSHomeDirectory()
        
        //For some reason completed gets called twice on iPad, but it's never true
        //even when successful. If we remove the completed=true check then we have
        //two issues:
        //1. on iPad, if we remove temp files after the first call then it stops
        //printing from happening. We could just not cleanup, and let the system do
        //it, but we still have the next issue.
        //2. The success dialog pops up underneath the printing progress dialog, gets
        //called twice, and we potentially also start the rating workflow also
        //underneath the printing dialog.
        //For now we have to accept that the success dialog and the rating workflow
        //aren't available on iPad.
        guard completed else {
            return
        }
    
        DispatchQueue.main.async {
            
            //Cleanup.
            pageLayoutState.deleteTempFiles()

            //Display an appropriate success message, depending on which action the
            //user selected.
            //TODO: Localize
            switch activityType {
            case UIActivity.ActivityType.saveToCameraRoll:
                //RatingHelper.signifcantEventOccurred(canPromptForReview: true)
                MFAnalytics.logSuccess("SavedToCameraRoll")
                successMessage = L10n.PreviewPage.SuccessAlert.photoSaved
                isShowingSuccessAlert = true
            case UIActivity.ActivityType.print:
                //RatingHelper.signifcantEventOccurred(canPromptForReview: true)
                MFAnalytics.logSuccess("Print")
                successMessage = L10n.PreviewPage.SuccessAlert.print
                isShowingSuccessAlert = true
            case saveToFilesActivityType:
                //RatingHelper.signifcantEventOccurred(canPromptForReview: true)
                MFAnalytics.logSuccess("SavedToFiles")
                successMessage = L10n.PreviewPage.SuccessAlert.fileSaved
                isShowingSuccessAlert = true
            default:
                MFAnalytics.logSuccess("OtherActivity")
                return
            }
        }
    }
    
    func excludedApplicationActivities(for exportFormat: ExportCollageFormat) -> [UIActivity.ActivityType]? {
        switch exportFormat {
        case .pdf:
            // Any activity is allowed
            return nil
        case .image:
            // Only save to amera roll is allowed. Main reason for the limitation
            // is to encourage people to use PDF as their route for printing.
            return [
                UIActivity.ActivityType.print,
                UIActivity.ActivityType.assignToContact,
            ]
        }
    }
    
    var body: some View {
        //GeometryReader { geometry in
        
        VStack {

            CollageView(pageLayoutState: pageLayoutState,
                            selectedPage: $selectedPreviewPage, zoom: $boardZoom,
                            compactActions: EmptyView()) { index in
                    navigationModel.openCard(at: index)
                }
                .alert(L10n.PreviewPage.PhotoSaveError.title,
                       isPresented: $isShowingPhotoLibraryError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(photoLibraryErrorMessage)
                }

            VStack(spacing: 0) {
                if pageLayoutState.canRepeatSinglePhoto {
                    Toggle(L10n.PreviewPage.repeatButton, isOn: $pageLayoutState.repeatSinglePhoto)
                    //.toggleStyle(CheckboxToggleStyle(style: .square))
                    //.foregroundColor(.blue)
                        .toggleStyle(SwitchToggleStyle(tint: Color("mfBrightBlue") ))
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.repeatImageButton)
                        .frame(minWidth: minToggleWidth, maxWidth: maxToggleWidth)
                        .padding()
                }
                
                //MARK: Formatting button and nav link
                AdaptiveStack(isVertical: horizontalSizeClass == .compact) {
                    
                    StandardButton(action: { isShowingFormatting = true }, systemIconName: "paintbrush", text: L10n.PreviewPage.formattingButton, purpose: .secondary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.formattingButton)
                        //.padding()

#if EasyPECSPlus
                    //TODO: Localize and correct accessibility identifier
                    
                    /*
                     //Could use ShareLink, but you have to create the items up-front.
                    let images = pageLayoutState.createPrintableCollage().map{Image(uiImage: ($0.image))}
                    if !images.isEmpty {
                        ShareLink(items: images) { image in
                            SharePreview("Page 1", image: image)
                            } label: {
                            Text("Save Image")
                        }
                        .buttonStyle(.bordered)
                    }

                    if let pdfURL = pageLayoutState.createPDF(), let previewImage = pageLayoutState.createCollageForScreen(maxWidth: 1000).first?.image {
                        ShareLink(item: pdfURL, preview:
                                    SharePreview("Choice Board.pdf", image: Image(uiImage: previewImage)), label: {
                            Text("Save PDF")
                        })
                        .buttonStyle(.bordered)
                    }
                     */
                    
                    StandardButton(action: {
                        saveToPhotoLibrary()
                    }, systemIconName: "printer", text: "Save Image", purpose: .secondary)
                        //.accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintImageButton)
                        //.padding()
                        .disabled(isSavingToPhotoLibrary)
                    
                    StandardButton(action: {
                        exportFormat = .pdf
                        //isShowingShareSheet = true
                        presentActivityView()
                    }, systemIconName: "printer", text: "Save PDF", purpose: .secondary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintPDFButton)
                        //.padding()

                    StandardButton(action: {
                        presentPrintView()
                    }, systemIconName: "printer",
                        text: "Print",
                        //text: L10n.PreviewPage.saveButton,
                        purpose: .primary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
                        //.padding()
#else

                    StandardButton(action: {
                        saveToPhotoLibrary()
                    }, systemIconName: "photo.badge.arrow.down",
                                   text: L10n.PreviewPage.saveImageButton,
                                   purpose: .secondary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintImageButton)
                        .padding()
                        .disabled(isSavingToPhotoLibrary)
                    
                    StandardButton(action: {
                        presentPrintView()
                    }, systemIconName: "printer",
                        text: L10n.PreviewPage.saveButton,
                        purpose: .primary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
                        //.padding()
#endif

                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            
        }
        //.frame(maxWidth: .infinity)
        .navigationBarTitle(L10n.PreviewPage.title, displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.PreviewPage.cardsButton) { isShowingCardList = true }
                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.cardsButton)
            }
        }
        //        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .sheet(isPresented: $isShowingCardList, onDismiss: { cardListPath = [] }) {
            cardList
        }
        //.onDisappear { dismissAction() }
        .sheet(isPresented: $isShowingShareSheet){ [exportFormat] in
            
            //Note that we have captured exportFormat, this method doesn't pick
            //up the changes each time a button is tapped and changes the value.
            
            //TODO: If we make createShareableItems return an array of URLs
            //then we can get the images to have a proper preview... probably!
            let activityItems = pageLayoutState.createShareableItems(format: exportFormat)
            
            if activityItems.count > 0 {
            //if let pdf = pageLayoutState.createPrintableCollage() {
                
                let excludedActivities = excludedApplicationActivities(for: exportFormat)
                
                ActivityViewController(activityItems: activityItems as [Any], excludedActivities: excludedActivities, completionHandler: activityCompletionHandler)
                    //Need this line on MacOS to avoid a crash.
                    .environmentObject(featuresViewModel)
            }
            else {
                EmptyView()
            }
        }
        .sheet(isPresented: $isShowingFormatting) {
            //let options = CollageFormatting.shared
            FormattingView(formattingOptions: pageLayoutState.topic.formatting, dismissAction: {
                pageLayoutState.save()
                self.isShowingFormatting = false
            })
        }
        .alert(successMessage, isPresented: $isShowingSuccessAlert) {
            Button(L10n.PhotoZoomView.closeButton, role: .cancel) {
                // Defer the rating flow until the native alert has dismissed.
                DispatchQueue.main.async {
                    ratingStateMachine.significantEventOccurred()
                }
            }
        }
    }

    private var cardList: some View {
        NavigationStack(path: $cardListPath) {
            List {
                let photos = pageLayoutState.photoBrowserData.photoItems
                let cardsPerPage = max(pageLayoutState.pageLayout.total, 1)
                let rowCount = photos.count + (photos.count < AppSettings.maxSelectionsInPhotoPicker ? 1 : 0)
                ForEach(0..<rowCount, id: \.self) { index in
                    let title = index < photos.count
                        ? (photos[index].title.flatMap { $0.isEmpty ? nil : $0 }
                            ?? L10n.PhotoSelectionView.untitledCell)
                        : L10n.PhotoSelectionView.emptyCard
                    Button {
                        cardListPath.append(index < photos.count ? .photo(photos[index].itemID) : .emptyCard(index))
                    } label: {
                        Text(L10n.PreviewPage.cardPosition(
                            index / cardsPerPage + 1, index % cardsPerPage + 1, title))
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .accessibilityHint(index < photos.count
                                       ? L10n.PreviewPage.editCardHint
                                       : L10n.PreviewPage.addCardHint)
                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.cardListRow(for: index))
                }
            }
            .navigationTitle(L10n.PreviewPage.cardsButton)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.PreviewPage.closeCards) { isShowingCardList = false }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                cardEditor(for: route)
            }
        }
    }

    @ViewBuilder
    private func cardEditor(for route: AppRoute) -> some View {
        switch route {
        case .photo(let id):
            PhotoCellZoomed(pageLayoutState: pageLayoutState,
                photo: Binding(get: { pageLayoutState.photoBrowserData.photoItems.first { $0.itemID == id } },
                               set: { if $0 == nil, !cardListPath.isEmpty { cardListPath.removeLast() } }),
                onDelete: { pageLayoutState.deletePhotos([$0]) })
        case .emptyCard(let index):
            PhotoCellZoomed(pageLayoutState: pageLayoutState,
                photo: Binding(get: {
                    let photos = pageLayoutState.photoBrowserData.photoItems
                    return photos.indices.contains(index) ? photos[index] : nil
                }, set: { if $0 == nil, !cardListPath.isEmpty { cardListPath.removeLast() } }),
                onDelete: { pageLayoutState.deletePhotos([$0]) }, isEmptySlot: true, index: index)
        default:
            EmptyView()
        }
    }

    private func presentActivityView() {
        let items = pageLayoutState.createShareableItems(format: exportFormat)
        guard !items.isEmpty else { return }
        
        let excluded = excludedApplicationActivities(for: exportFormat)
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.excludedActivityTypes = excluded
        vc.completionWithItemsHandler = activityCompletionHandler
        
        guard let presenter = presentationContext.presenter else { return }
        if let popover = vc.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX,
                                        y: presenter.view.bounds.midY,
                                        width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        presenter.present(vc, animated: true)
    }

    @MainActor
    private func saveToPhotoLibrary() {
        guard !isSavingToPhotoLibrary else { return }
        isSavingToPhotoLibrary = true

        Task { @MainActor in
            defer { isSavingToPhotoLibrary = false }
            do {
                try await pageLayoutState.exportCollageToPhotoLibrary()
                MFAnalytics.logSuccess("SavedToCameraRoll")
                successMessage = L10n.PreviewPage.SuccessAlert.photoSaved
                isShowingSuccessAlert = true
            } catch {
                logger.logError(.general, "Unable to save board to the photo library", error)
                photoLibraryErrorMessage = error.localizedDescription
                isShowingPhotoLibraryError = true
            }
        }
    }

    private func presentPrintView() {
        guard let pdfURL = pageLayoutState.createPDF() else { return }
        let jobName = pageLayoutState.title.isEmpty ? L10n.PreviewPage.title : pageLayoutState.title
        let didPresent = presentSystemPrintController(
            printingItem: pdfURL,
            jobName: jobName,
            from: presentationContext.presenter
        ) { _, completed, error in
            DispatchQueue.main.async {
                pageLayoutState.deleteTempFiles()
                if let error {
                    logger.logError(.general, "Error returned from print controller", error)
                }
                guard completed else { return }
                MFAnalytics.logSuccess("Print")
                successMessage = L10n.PreviewPage.SuccessAlert.print
                isShowingSuccessAlert = true
            }
        }
        if !didPresent {
            pageLayoutState.deleteTempFiles()
        }
    }
    
}

//struct PreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        PagePreviewView(isVertical: true)
//    }
//}
