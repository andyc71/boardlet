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

///Flow:
///1. User taps Print which launches the ActivityViewController with an AVC completion handler
///2. User selects Save to Camera Roll or Print, and the ActivityViewController calls the AVC completion handler
///3. AVC completion handler sets a successMessage to say what was done, and isShowingSuccessAlert=true to cause the Success message box alert to appear.
///4. Success message box alert is dismissed, and RatingHelper.signifcantEventOccurred is called with a callback that sets isShowingSuccessAlert=true to cause the Rating alert message box to appear.
///5. Rating alert message box asks the user if they want to rate the app, and if so, calls SKStoreReviewController.requestReviewInCurrentScene; otherwise just records that the user doesn't want to rate.

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
        setupRatingHelper()
    }
    
    func setupRatingHelper() {
        
        if CommandLine.arguments.contains(LaunchArguments.noRatings) {
            return
        }
        
        #if DEBUG
        RatingHelper.reset()
        #endif

        RatingHelper.setup()
        RatingHelper.minimumReviewWorthyActionCount = 1
    }
    
    func createCollage() -> UIImage {
        
        let gridSize = pageLayoutState.pageLayout
        let pageMeasurements = pageLayoutState.pageMeasurements2.convertToScreenMeasurements(.large)
        print("Page Measurements for grid layout: \(pageMeasurements)")

        guard let image = CollageFactory.createCollage(from: getPhotos(from: pageLayoutState.photoData), gridSize: gridSize, pageSize: pageMeasurements, cellFillColor: UIColor.systemBackground) else {
            return UIImage()
        }
        
        //return pageLayoutState.createCollage(from: pageLayoutState.photoData)
        
        return image
        
    }
    
    var body: some View {
        VStack(alignment: .center) {
            
            
            Image(uiImage: createCollage())
            //Image(systemName: "music.note")
                .resizable()
                .aspectRatio( pageLayoutState.aspectRatio, contentMode: .fit )
                .border(Color(UIColor.secondaryLabel), width: 1)
                .padding()

            
            //StandardButton(action: { isShowingShareSheet = true }, systemIconName: "printer", text: "Save or Print", isHorizontal: true)
            MainMenuButton(action: { isShowingShareSheet = true }, systemIconName: "printer", text: "Save or Print")
                .padding()

            StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: "Done", isHorizontal: true)
                .padding()

            Spacer()
            
        }
        //.frame(maxWidth: .infinity)
        .navigationBarTitle(Text("Print"), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundColor)
        .sheet(isPresented: $isShowingShareSheet, content: {
            ActivityViewController(activityItems: [pageLayoutState.createPrintableCollage(from: pageLayoutState.photoData)]) { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            
                if completed {
                    switch activityType {
                    case UIActivity.ActivityType.saveToCameraRoll, UIActivity.ActivityType.print:
                        if activityType == .saveToCameraRoll {
                            successMessage = "PECS layout saved to your photo library."
                        }
                        else {
                            successMessage = "PECS layout sent to the printer."
                        }
                        isShowingSuccessAlert = true
                    default:
                        return
                    }
                }
            }
        })
        .alert(isPresented: $isShowingSuccessAlert, content: {
            Alert(
                title: Text("Success"),
                message: Text(successMessage),
                dismissButton: .default(Text("OK"), action: {
                    isShowingSuccessAlert = false
                    dismissAction()
                    
                    RatingHelper.promptForRatingCallback = {
                        (ratingStatus: RatingStatus) in
                            self.isShowingSuccessAlert = true
                    }

                    RatingHelper.signifcantEventOccurred(canPromptForReview: true)

                })
            )
        })
        .alert(isPresented: $isShowingSuccessAlert, content: {
            Alert(
                title: Text("Please Rate Easy PECS"),
                message: Text("Your rating will help other users to find this app more easily."),
                primaryButton: .default(Text("Rate"), action: {
                    isShowingSuccessAlert = false
                    SKStoreReviewController.requestReviewInCurrentScene()
                    RatingHelper.setRatingResponse(RatingResponse.rate)
                    }),
                secondaryButton: .cancel(Text("No Thanks"), action: {
                    isShowingSuccessAlert = false
                    RatingHelper.setRatingResponse(RatingResponse.no)
                })

            )
        })

        
    }
}

//struct PreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        PagePreviewView(isVertical: true)
//    }
//}
