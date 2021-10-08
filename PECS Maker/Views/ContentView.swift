//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine
import SharedUI
import StoreKit

struct ContentView: View {
    
    //    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    //    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @ObservedObject var pageLayoutState = PageLayoutState()
    
    @Binding var showRatingPrompt: Bool
    
    init(showRatingPrompt: Binding<Bool>) {
        self._showRatingPrompt = showRatingPrompt
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
        
        RatingHelper.promptForRatingCallback = {
            (ratingStatus: RatingStatus) in

                self.showRatingPrompt = true
        }
    }

    

    var body: some View {
        NavigationView {
            //ConditionalStack(verticalAlignment: .top, /*isHorizonalStack: pageLayoutState.orientation == .landscape*/ isHorizonalStack: false) {
            VStack {
                
                //Create our own psuedo nav bar header. We're doing this beacuse it's hard
                //to get the right padding with the default nav bar.
                Text("Easy PECS")
                    //.font(.largeTitle)
                    .font(Theme.headerFontHomePage)
                    .foregroundColor(Color(Theme.headerTextColorName))
                    .padding()
                
                
                MainMenuView(pageLayoutState: pageLayoutState)
                    //Maxwidth of 400 ensures that iPhone portrait button can be full width, which looks fine,
                    //but it doesn't take up the full width on wider devices like iPad because that looks odd.
                    .frame(minWidth: 0, maxWidth: AppSettings.maxViewWidth)
                


                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            //.navigationBarTitle(Text("Easy PECS"), displayMode: .inline)
            
            //.navigationBarTitle(Text("Easy PECS"))

            //.navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    VStack {
//                        Spacer(minLength: 40)
//                        Text(AppInformation.appName ?? "Easy PECS")
//                            //.font(Theme.headerFont)
//                            .foregroundColor(Color(Theme.headerTextColorName))
//                                //.font(.largeTitle)
//                            .font(Font.custom("Marker Felt", size: 50))
//
//                                //Text("Subtitle").font(.subheadline)
//                        Spacer(minLength: 20)
//                    }
//                }
//            }
            
            /*
            .toolbar {
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    
                    Button(
                        action: {
                            //self.shareImage()
                        })
                    {
                        ZStack {
                            Image(systemName:"square.and.arrow.up")
                                .renderingMode(.original)
                                .font(.system(headerIcontTextStyle))
                                //.font(headerIcontTextStyle))
                                //.font(Font.body.weight(.regular))
                            //activityViewController
                        }
                    }
                    
                    
                }
            }*/
            .maxWidth(.infinity)
            .background(Theme.backgroundColor)
            
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
//        .popover(isPresented: $showRatingPrompt) {
//            RatingPromptView(dismissAction: { self.showRatingPrompt = false} )
//        }
        .alert(isPresented: $showRatingPrompt, content: {
            Alert(
                title: Text("Please Rate Easy PECS"),
                message: Text("Your rating will help other users to find this app more easily."),
                primaryButton: .default(Text("Rate"), action: {
                    showRatingPrompt = false
                    SKStoreReviewController.requestReviewInCurrentScene()
                    RatingHelper.setRatingResponse(RatingResponse.rate)
                    }),
                secondaryButton: .cancel(Text("No Thanks"), action: {
                    showRatingPrompt = false
                    RatingHelper.setRatingResponse(RatingResponse.no)
                })

            )
        })

    }
}

//struct ContentView_Previews: PreviewProvider {
//
//    @State static var showRatingPrompt: Bool = false
//
//    static var previews: some View {
//        ContentView(showRatingPrompt: showRatingPrompt)
//        //ContentView(showRatingPrompt: .constant(false))
//    }
//}
//
//
