//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine
import SharedSwiftUI

struct ContentView: View {
    
    //    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    //    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @ObservedObject var pageLayoutState = PageLayoutState()

    
    var body: some View {
        NavigationView {
            //ConditionalStack(verticalAlignment: .top, /*isHorizonalStack: pageLayoutState.orientation == .landscape*/ isHorizonalStack: false) {
            ScrollView {
                
                //MessageView(heading: "Done", subheading: "Save/Print Complete", animation: MicroAnimations.tickAnimation)
                
                //Create our own psuedo nav bar header. We're doing this beacuse it's hard
                //to get the right padding with the default nav bar.
                Text("Easy PECS")
                    //.font(.largeTitle)
                    .font(Theme.headerFontHomePage)
                    .foregroundColor(Color(Theme.headerTextColor))
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
            .frame(maxWidth: .infinity)
            //.background(Theme.backgroundColor)
            .background(Theme.backgroundColor.ignoresSafeArea(edges: .all))
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
//        .popover(isPresented: $showRatingPrompt) {
//            RatingPromptView(dismissAction: { self.showRatingPrompt = false} )
//        }

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
