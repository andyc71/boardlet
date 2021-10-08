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

var rowCount = 2
var colCount = 2


struct PagePreviewView: View {
    
    @ObservedObject var pageLayoutState: PageLayoutState
    
    @State var isVertical: Bool
    
    @State var isShowingShareSheet: Bool = false

    @State var isShowingSuccessAlert: Bool = false
    
    @State var successMessage: String = ""
    
    func createCollage() -> UIImage {
        
        let gridSize = pageLayoutState.pageLayout
        let pageMeasurements = pageLayoutState.pageMeasurements
        print("Page Measurements for grid layout: \(pageMeasurements)")

        
        guard let image = CollageFactory.createCollage(from: getPhotos(from: pageLayoutState.photoData), gridSize: gridSize, pageSize: pageMeasurements.size, cellFillColor: UIColor.systemBackground) else {
            return UIImage()
        }
        
        //return pageLayoutState.createCollage(from: pageLayoutState.photoData)
        
        return image
        
    }
    
    var dismissAction: ()->()
    
    
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
            ActivityViewController(activityItems: [pageLayoutState.createCollage(from: pageLayoutState.photoData)]) { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            
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
                    RatingHelper.signifcantEventOccurred(canPromptForReview: true)

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
