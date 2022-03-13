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
import SharedUI
import StoreKit
import LogFramework

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
    
    @State var isShowingRatingAlert: Bool = false
    
    @State var successMessage: String = ""
    
    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
        MFAnalytics.logScreenView(screenName: "PagePreview")
    }
    
    var body: some View {
        VStack(alignment: .center) {
            
            
            Image(uiImage: pageLayoutState.collageForScreen)
            //Image(systemName: "music.note")
                .resizable()
                .aspectRatio( pageLayoutState.aspectRatio, contentMode: .fit )
                .border(Color(UIColor.secondaryLabel), width: 1)
                .padding()
            
            if pageLayoutState.canRepeatSinglePhoto {
                Toggle("Repeat Image", isOn: $pageLayoutState.repeatSinglePhoto)
                  //.toggleStyle(CheckboxToggleStyle(style: .square))
                    //.foregroundColor(.blue)
                    .toggleStyle(SwitchToggleStyle(tint: Color("mfBrightBlue") ))
                    .padding()
            }

            
            //StandardButton(action: { isShowingShareSheet = true }, systemIconName: "printer", text: "Save or Print", isHorizontal: true)
            MainMenuButton(action: { isShowingShareSheet = true }, systemIconName: "printer", text: "Save or Print")
                .padding()
                .alert(isPresented: $isShowingSuccessAlert, content: {
                    Alert(
                        title: Text("Success"),
                        message: Text(successMessage),
                        dismissButton: .default(Text("OK"), action: {
                            isShowingSuccessAlert = false
                            dismissAction()
                            
                            RatingHelper.promptForRatingCallback = {
                                (ratingStatus: RatingStatus) in
                                    self.isShowingRatingAlert = true
                            }

                            RatingHelper.signifcantEventOccurred(canPromptForReview: true)

                        })
                    )
                })
            StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: "Done", isHorizontal: true)
                .padding()
                .alert(isPresented: $isShowingRatingAlert, content: {
                    Alert(
                        title: Text("Please Rate Easy PECS"),
                        message: Text("Your rating will help other users to find this app more easily."),
                        primaryButton: .default(Text("Rate"), action: {
                            isShowingRatingAlert = false
                            SKStoreReviewController.requestReviewInCurrentScene()
                            RatingHelper.setRatingResponse(RatingResponse.rate)
                            }),
                        secondaryButton: .cancel(Text("No Thanks"), action: {
                            isShowingRatingAlert = false
                            RatingHelper.setRatingResponse(RatingResponse.no)
                        })

                    )
                })
            Spacer()


        }
        //.frame(maxWidth: .infinity)
        .navigationBarTitle(Text("Print"), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))
        .sheet(isPresented: $isShowingShareSheet, content: {
            ActivityViewController(activityItems:
                                    //[pageLayoutState.createPrintableCollage(from: pageLayoutState.photoData)]
                                   [pageLayoutState.createPDF(from: pageLayoutState.photoData) as Any]

            ) { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            
                let saveToFilesActivityType = UIActivity.ActivityType("com.apple.DocumentManagerUICore.SaveToFiles")
                
                if completed {
                    switch activityType {
                    case UIActivity.ActivityType.saveToCameraRoll:
                        successMessage = "PECS layout saved to your photo library."
                        isShowingSuccessAlert = true
                    case UIActivity.ActivityType.print:
                        successMessage = "PECS layout sent to the printer."
                        isShowingSuccessAlert = true
                    case saveToFilesActivityType:
                        successMessage = "PECS layout saved."
                        isShowingSuccessAlert = true
                    default:
                        return
                    }
                }
                
                //Cleanup.
                pageLayoutState.deleteTempFiles()
                
            }
        })

        
    }
}

//struct PreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        PagePreviewView(isVertical: true)
//    }
//}
