//
//  CreditsView.swift
//  SwiftUI Settings Screen
//
//  Created by Rudrank Riyam on 19/04/20.
//  Copyright © 2020 Rudrank Riyam. All rights reserved.
//

import SwiftUI
import SharedSwiftUI
import SettingsFramework

struct CreditsView: View {
    
    @EnvironmentObject private var currentTheme: SharedUITheme
    
    var body: some View {
        Form {
            
//            SimpleCard {
//                LicenceRow(licenceName: "Apache-2.0 License", licenceSubheading: "Items below are used under Apache 2.0 License", licenceFile: "apache-2.0")

            LicenceRow(licenceName: "MIT License", licenceSubheading: "Items below are used under MIT License", licenceFile: "mit")

            Section {
                CreditsRow(title: "Kingfisher", owner: "Wei Wang", url:  "https://github.com/onevcat/Kingfisher/")
                CreditsRow(title: "SwiftUI exensions", owner: "Vatsal Manot", url:  "https://github.com/SwiftUIX/SwiftUIX")
                CreditsRow(title: "Popovers library", owner: "Andrew Zheng", url: "https://github.com/aheze/Popovers")
                CreditsRow(title: "ZL Photo Browser", owner: "Longitachi", url: "https://github.com/longitachi/ZLPhotoBrowser")
            }
            
            LicenceRow(licenceName: "Apache-2.0 License", licenceSubheading: "Items below are used under Apache 2.0 License", licenceFile: "apache-2.0")

            Section {
                CreditsRow(title: "Firebase", owner: "Google", url:  "https://firebase.google.com")
                CreditsRow(title: "Lottie animations library", owner: "Airbnb", url: "https://github.com/airbnb/lottie-ios")
                CreditsRow(title: "Nimble testing library", owner: "Quick", url: "https://github.com/Quick/Nimble.git")
            }
            

            
        }
        .navigationBarTitle(Text("Acknowledgements"), displayMode: .inline)
        .frame(maxWidth: AppSettings.maxViewWidth)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentTheme.backgroundColor))
   }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
