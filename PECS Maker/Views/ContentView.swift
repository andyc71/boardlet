//
//  ContentView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    //    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    //    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @ObservedObject var pageLayoutState = PageLayoutState()
    
    init() {
        //Set up the default nav bar which will be used by all the child pages.
        //For this page, we will hide the default nav bar and display our own title.
        NavigationBar.configure()
    }
    
    var body: some View {
        NavigationView {
            //ConditionalStack(verticalAlignment: .top, /*isHorizonalStack: pageLayoutState.orientation == .landscape*/ isHorizonalStack: false) {
            VStack {
                
                //Create our own psuedo nav bar header. We're doing this beacuse it's hard
                //to get the right padding with the default nav bar.
                Text("PECS Maker")
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


