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
    
   
    var headerFontSize = UIFont.preferredFont(forTextStyle: .title1).pointSize
    
    let headerIcontTextStyle = Font.TextStyle.title3

    init() {
        //Use this if NavigationBarTitle is with Large Font
        //UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "Georgia-Bold", size: 20)!]
        
        //Use this if NavigationBarTitle is with displayMode = .inline
//        UINavigationBar.appearance().titleTextAttributes = [
//            .font : UIFont(name: "Marker Felt", size: 24)!,
//            .foregroundColor : UIColor(named: "mfBrightBlue") as Any
//        ]
//        UINavigationBar.appearance().backgroundColor = UIColor(named: "mfLightYellow")
        
                
        let titleTextAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor : UIColor(named: Theme.headerTextColorName) as Any,
            .strokeColor : UIColor(named: Theme.headerTextOutlineColorName) as Any,
            .strokeWidth : Theme.headerTextOutlineWidth as Any,
            .font : UIFont(name: Theme.headerFontName, size: Theme.headerFontSize) as Any
        ]
        
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = UIColor(named: Theme.headerBackgroundColorName)
        coloredAppearance.titleTextAttributes = titleTextAttributes
        coloredAppearance.largeTitleTextAttributes = titleTextAttributes

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        
    }
    
    var body: some View {
        NavigationView {
            //ConditionalStack(verticalAlignment: .top, /*isHorizonalStack: pageLayoutState.orientation == .landscape*/ isHorizonalStack: false) {
            VStack {
                MainMenuView(pageLayoutState: pageLayoutState)
                Spacer()
            }
            .padding()
            .navigationBarTitle(Text("Easy PECS"), displayMode: .inline)
            /*
             .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(AppInformation.appName ?? "Easy PECS")
                            .font(Theme.headerFont)
                            .foregroundColor(Color(Theme.headerForegroundColorName))
                                //.font(.largeTitle)
                                //Text("Subtitle").font(.subheadline)
                    }
                }
            }*/
            
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


