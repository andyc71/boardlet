//
//  ClassicPreviewAndPrintView.swift
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
import LogFrameworkFirebase
import EngagementKit

///Flow:
///1. User taps Print which launches the ActivityViewController with an AVC completion handler
///2. User selects Save to Camera Roll or Print, and the ActivityViewController calls the AVC completion handler
///3. AVC completion handler sets a successMessage to say what was done, and isShowingSuccessAlert=true to cause the Success message box alert to appear.
///Note that the two alerts have not been placed on the VStack because they would override each other. Instead they have been
///placed on arbitrary views withing the VStack.

struct ClassicPreviewAndPrintView: View {
    
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
    @EnvironmentObject private var engagement: EngagementCoordinator
    @State private var engagementOperationID = UUID()
    
    @State var isShowingFormatting: Bool = false
    
    @State var successMessage: String = ""
    
    
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var availableSize: CGSize = .zero

    private var isCompactHeight: Bool { verticalSizeClass == .compact }

    private var previewLayout: AnyLayout {
        isCompactHeight
            ? AnyLayout(HStackLayout(alignment: .bottom, spacing: 24))
            : AnyLayout(VStackLayout(spacing: 20))
    }

    private var contentWidth: CGFloat {
        guard isCompactHeight, availableSize.height > 0 else { return .infinity }
        // Center the paper and action rail as one group instead of leaving an
        // expanding empty column between a portrait page and its controls.
        let paperWidth = max(1, availableSize.height - 24) * pageLayoutState.aspectRatio
        return min(availableSize.width - 24, paperWidth + 24 + 192)
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
        guard completed, error == nil else {
            return
        }
    
        DispatchQueue.main.async {
            
            engagement.recordCompletion(activityType == .print ? .printBoard : .shareBoard,
                                        id: engagementOperationID)
            //Cleanup.
            pageLayoutState.deleteTempFiles()

            //Display an appropriate success message, depending on which action the
            //user selected.
            //TODO: Localize
            switch activityType {
            case UIActivity.ActivityType.saveToCameraRoll:
                MFAnalytics.logSuccess("SavedToCameraRoll")
                successMessage = L10n.PreviewPage.SuccessAlert.photoSaved
                isShowingSuccessAlert = true
            case UIActivity.ActivityType.print:
                MFAnalytics.logSuccess("Print")
                engagement.recordCompletion(.printBoard, id: engagementOperationID)
                successMessage = L10n.PreviewPage.SuccessAlert.print
                isShowingSuccessAlert = true
            case saveToFilesActivityType:
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
        previewLayout {
            ClassicCollageView(pageLayoutState: pageLayoutState)
                .frame(minHeight: isCompactHeight ? 0 : 120)
                .alert(L10n.PreviewPage.PhotoSaveError.title,
                       isPresented: $isShowingPhotoLibraryError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(photoLibraryErrorMessage)
                }

            ClassicPreviewActions(
                pageLayoutState: pageLayoutState,
                isCompactHeight: isCompactHeight,
                isSavingToPhotoLibrary: isSavingToPhotoLibrary,
                showFormatting: { isShowingFormatting = true },
                saveImage: saveToPhotoLibrary,
                exportPDF: {
                    exportFormat = .pdf
                    presentActivityView()
                }
            )
            .frame(maxWidth: isCompactHeight ? 192 : 420)
            .layoutPriority(1)
        }
        .frame(maxWidth: contentWidth)
        .padding(isCompactHeight ? 12 : 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { availableSize = $0 }
        .navigationBarTitle(L10n.PreviewPage.title, displayMode: .inline)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
        .onDisappear { dismissAction() }
        .onChange(of: isShowingShareSheet) { showing in
            if showing { engagementOperationID = UUID() }
        }
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

            }
        }
    }
    
    private func presentActivityView() {
        let items = pageLayoutState.createShareableItems(format: exportFormat)
        guard !items.isEmpty else { return }
        
        let excluded = excludedApplicationActivities(for: exportFormat)
        engagementOperationID = UUID()
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
        engagementOperationID = UUID()

        Task { @MainActor in
            defer { isSavingToPhotoLibrary = false }
            do {
                try await pageLayoutState.exportCollageToPhotoLibrary()
                engagement.recordCompletion(.exportBoard, id: engagementOperationID)
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
    
}
