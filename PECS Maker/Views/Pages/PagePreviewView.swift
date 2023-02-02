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

///Flow:
///1. User taps Print which launches the ActivityViewController with an AVC completion handler
///2. User selects Save to Camera Roll or Print, and the ActivityViewController calls the AVC completion handler
///3. AVC completion handler sets a successMessage to say what was done, and isShowingSuccessAlert=true to cause the Success message box alert to appear.
///4. Success message box alert is dismissed, and RatingHelper.signifcantEventOccurred is called with a callback that sets isShowingSuccessAlert=true to cause the Rating alert message box to appear.
///5. Rating alert message box asks the user if they want to rate the app, and if so, calls SKStoreReviewController.requestReviewInCurrentScene; otherwise just records that the user doesn't want to rate.
///Note that the two alerts have not been placed on the VStack because they would override each other. Instead they have been
///placed on arbitrary views withing the VStack.

struct PagePreviewView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State var isShowingShareSheet: Bool = false
    
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
    
    var body: some View {

        VStack {
            
            CollageView(pageLayoutState: pageLayoutState)
            
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
                        .padding()

                    StandardButton(action: { isShowingShareSheet = true }, systemIconName: "printer", text: L10n.PreviewPage.saveButton, purpose: .primary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
                        .padding()
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
        .sheet(isPresented: $isShowingShareSheet, content: {
            
            if let pdf = pageLayoutState.createPDF() {
                
                ActivityViewController(activityItems: [pdf as Any]
                                       //[pageLayoutState.createPrintableCollage(from: pageLayoutState.photoData)]
                                       
                ) { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                    
                    //TODO: display any errors returned in error.
                    if let error = error {
                        logger.logError(.general, "Error returned from UI Activity controller", error)
                    }
                    
                    
                    let saveToFilesActivityType = UIActivity.ActivityType("com.apple.DocumentManagerUICore.SaveToFiles")
                    
                    ////Users/andy/Library/Developer/CoreSimulator/Devices/79F23C03-EA23-424E-A86F-EF734A231E96/data/Containers/Shared/AppGroup/D42B885A-9F13-488B-88B6-E543AA40FED3/File Provider Storage/PECS.pdf
                    ///
                    //NSHomeDirectory()
                    
                    if completed {
                        DispatchQueue.main.async {
                            switch activityType {
                            case UIActivity.ActivityType.saveToCameraRoll:
                                //RatingHelper.signifcantEventOccurred(canPromptForReview: true)
                                successMessage = "PECS layout saved to your photo library."
                                isShowingSuccessAlert = true
                            case UIActivity.ActivityType.print:
                                //RatingHelper.signifcantEventOccurred(canPromptForReview: true)
                                successMessage = "PECS layout sent to the printer."
                                isShowingSuccessAlert = true
                            case saveToFilesActivityType:
                                //RatingHelper.signifcantEventOccurred(canPromptForReview: true)
                                successMessage = "PECS layout saved."
                                isShowingSuccessAlert = true
                            default:
                                return
                            }
                        }
                    }
                    
                    //Cleanup.
                    pageLayoutState.deleteTempFiles()
                }
            }
            else {
                EmptyView()
            }
        })
        .sheet(isPresented: $isShowingFormatting) {
            //let options = CollageFormatting.shared
            FormattingView(formattingOptions: pageLayoutState.topic.formatting, dismissAction: {
                pageLayoutState.save()
                self.isShowingFormatting = false
            })
        }
        .successAlert(isPresented: $isShowingSuccessAlert, completion: {
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
