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
    
    @State var isShowingRatingAlert: Bool = false
    
    @State var isShowingFormatting: Bool = false
    
    @State var successMessage: String = ""
    
    var dismissAction: ()->()
    
    init(pageLayoutState: PageLayoutState, dismissAction: @escaping ()->() ) {
        self.pageLayoutState = pageLayoutState
        self.dismissAction = dismissAction
        MFAnalytics.logScreenView(screenName: "PagePreview")
    }
    
    var body: some View {
        //GeometryReader { geometry in
            
            ScrollView {
                
                //let collageSize = pageLayoutState.calculateCollageSizeForScreen(maxWidth: min(AppSettings.maxViewWidth, UIScreen.main.bounds.width - 20))
                let collageSize = pageLayoutState.calculateCollageSizeForScreen2()
                let collage = pageLayoutState.createCollageForScreen(maxWidth: collageSize.width)
                TabView {
                    ForEach(collage.indices, id:\.self) { i in
                    //ForEach(collage, id:\.self) { image in
                        let image = collage[i]
                        Image(uiImage: image)
                        //.resizable()
                            .aspectRatio( pageLayoutState.aspectRatio, contentMode: .fit )
                            .border(Color(UIColor.secondaryLabel), width: 1)
                            .padding()
                            .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.previewImage(for: i))
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(width: collageSize.width, height: collageSize.height)
                .id(UUID())
                .padding()

                
                //Image(uiImage: pageLayoutState.collageForScreen.first!)
                //Image(systemName: "music.note")
                //                .resizable()
                //                .aspectRatio( pageLayoutState.aspectRatio, contentMode: .fit )
                //                .border(Color(UIColor.secondaryLabel), width: 1)
                //                .padding()
                
                if pageLayoutState.canRepeatSinglePhoto {
                    Toggle(L10n.PreviewPage.repeatButton, isOn: $pageLayoutState.repeatSinglePhoto)
                    //.toggleStyle(CheckboxToggleStyle(style: .square))
                    //.foregroundColor(.blue)
                        .toggleStyle(SwitchToggleStyle(tint: Color("mfBrightBlue") ))
                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.repeatImageButton)
                        .padding()
                }
                
                //MARK: Formatting button and nav link
                
                StandardButton(action: { isShowingFormatting = true }, systemIconName: "paintbrush", text: "Formatting", isHorizontal: true)
                    .padding()
                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.formattingButton)
                
                let formattingView = LazyView(FormattingView())
                NavigationLink(destination: formattingView, isActive: $isShowingFormatting) {
                    EmptyView()
                }
                
                //StandardButton(action: { isShowingShareSheet = true }, systemIconName: "printer", text: "Save or Print", isHorizontal: true)
                MainMenuButton(action: { isShowingShareSheet = true }, systemIconName: "printer", text: L10n.PreviewPage.saveButton)
                    .padding()
                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
                /*
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
                    })*/
                
                StandardButton(action: { dismissAction() }, /*systemIconName: "checkmark",*/ text: L10n.doneButton, isHorizontal: true)
                    .padding()
                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.doneButton)
                    .ratingAlert(isPresented:  $isShowingRatingAlert)
                
                Spacer()
                
                
            }
            //.frame(maxWidth: .infinity)
            .navigationBarTitle(L10n.PreviewPage.title, displayMode: .inline)
            .frame(maxWidth: AppSettings.maxViewWidth)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(currentTheme.backgroundColor).ignoresSafeArea(edges: .all))
            //.onDisappear { dismissAction() }
            .sheet(isPresented: $isShowingShareSheet, content: {

                if let pdf = pageLayoutState.createPDF() {
                    
                    ActivityViewController(activityItems: [pdf as Any]
                                           //[pageLayoutState.createPrintableCollage(from: pageLayoutState.photoData)]
                                           
                    ) { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                        
                        
                        
                        let saveToFilesActivityType = UIActivity.ActivityType("com.apple.DocumentManagerUICore.SaveToFiles")
                        
                        ////Users/andy/Library/Developer/CoreSimulator/Devices/79F23C03-EA23-424E-A86F-EF734A231E96/data/Containers/Shared/AppGroup/D42B885A-9F13-488B-88B6-E543AA40FED3/File Provider Storage/PECS.pdf
                        ///
                        //NSHomeDirectory()
                        
                        if completed {
                            DispatchQueue.main.async {
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
                        }
                        
                        //Cleanup.
                        pageLayoutState.deleteTempFiles()
                    }
                }
                else {
                    EmptyView()
                }
            })
            .if(isShowingSuccessAlert) { view in
                
                view.overlay {
                    MicroAnimationView(animation: MicroAnimations.tickAnimation) {
                            DispatchQueue.main.async {
                                self.isShowingSuccessAlert = false
                                //Important to dispatch this separately or rating alert doesn't go away
                                DispatchQueue.main.async {
                                    self.isShowingRatingAlert = true
                                }
                        }
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.doneAnimation)
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityLabel("Done")
//
//
//                        MessageView(heading: "Done", subheading: "Save/Print Complete", animation: MicroAnimations.tickAnimation) {
//                            DispatchQueue.main.async {
//                                self.isShowingSuccessAlert = false
//                                self.isShowingRatingAlert = true
//                        }
                    
                }
            }

        
    }
}

//struct PreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        PagePreviewView(isVertical: true)
//    }
//}
