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

///Flow:
///1. User taps Print which launches the ActivityViewController with an AVC completion handler
///2. User selects Save to Camera Roll or Print, and the ActivityViewController calls the AVC completion handler
///3. AVC completion handler sets a successMessage to say what was done, and isShowingSuccessAlert=true to cause the Success message box alert to appear.
///4. Success message box alert is dismissed, and RatingHelper.signifcantEventOccurred is called with a callback that sets isShowingSuccessAlert=true to cause the Rating alert message box to appear.
///5. Rating alert message box asks the user if they want to rate the app, and if so, calls SKStoreReviewController.requestReviewInCurrentScene; otherwise just records that the user doesn't want to rate.
///Note that the two alerts have not been placed on the VStack because they would override each other. Instead they have been
///placed on arbitrary views withing the VStack.

struct PagePreviewView: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State var isShowingShareSheet: Bool = false
    @State var exportFormat: ExportCollageFormat = .pdf

    @State var isShowingSuccessAlert: Bool = false
    
    //@State var isShowingRatingAlert: Bool = false
    //@State var ratingAlertState: RatingStage = .initialQuestion
    @EnvironmentObject var ratingStateMachine: RatingStateMachine2
    
    @State var isShowingFormatting: Bool = false
    
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
            let collageSize = pageLayoutState.calculateCollageSizeForScreen2()
            return min(widthOfButtons, collageSize.width)
        }
    }
    
    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
        MFAnalytics.logScreenView(screenName: "PagePreview")
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

            CollageView(pageLayoutState: pageLayoutState)
                .padding()
                        
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
                    StandardButton(action: {
                        exportFormat = .image
                        isShowingShareSheet = true
                    }, systemIconName: "printer", text: "Save Image", purpose: .secondary)
                        //.accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintImageButton)
                        //.padding()
                    
                    StandardButton(action: {
                        exportFormat = .pdf
                        isShowingShareSheet = true
                    }, systemIconName: "printer", text: "Save PDF", purpose: .secondary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintPDFButton)
                        //.padding()

                    StandardButton(action: {
                        exportFormat = .pdf
                        isShowingShareSheet = true
                    }, systemIconName: "printer",
                        text: "Print",
                        //text: L10n.PreviewPage.saveButton,
                        purpose: .primary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
                        //.padding()
#else

                    StandardButton(action: {
                        exportFormat = .image
                        isShowingShareSheet = true
                    }, systemIconName: "photo.badge.arrow.down",
                                   text: L10n.PreviewPage.saveImageButton,
                                   purpose: .secondary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintImageButton)
                        .padding()
                    
                    StandardButton(action: {
                        exportFormat = .pdf
                        isShowingShareSheet = true
                    }, systemIconName: "printer",
                        text: L10n.PreviewPage.saveButton,
                        purpose: .primary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
                        //.padding()
#endif

                }
            }
            
            Spacer()
            
            
        }
        //.frame(maxWidth: .infinity)
        .navigationBarTitle(L10n.PreviewPage.title, displayMode: .inline)
        //        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
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
        .successAlert(isPresented: $isShowingSuccessAlert, theme: currentTheme, completion: {
            DispatchQueue.main.async {
                self.isShowingSuccessAlert = false
                //Important to dispatch this separately or rating alert doesn't go away
                DispatchQueue.main.async {
                    ratingStateMachine.significantEventOccurred()
                    //self.ratingAlertState.start()
                }
            }
        })


    }
}

//struct PreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        PagePreviewView(isVertical: true)
//    }
//}
