//
//  CreditsView.swift
//  SwiftUI Settings Screen
//
//  Created by Rudrank Riyam on 19/04/20.
//  Copyright © 2020 Rudrank Riyam. All rights reserved.
//

import SwiftUI

struct CreditsView: View {
    var body: some View {
        VStack {
            
//            SimpleCard {
//                LicenceRow(licenceName: "Apache-2.0 License", licenceSubheading: "Items below are used under Apache 2.0 License", licenceFile: "apache-2.0")
//                CreditsRow(title: "Lottie animations library", owner: "Airbnb", url: "https://github.com/airbnb/lottie-ios")
//            }
//            .padding()
            
            SimpleCard {
                LicenceRow(licenceName: "MIT License", licenceSubheading: "Items below are used under MIT License", licenceFile: "mit")
//                CreditsRow(title: "Cosmos star rating control", owner: "Evgenii Neumerzhitckii", url: "https://github.com/evgenyneu/Cosmos")
//                CreditsRow(title: "SDWebImage", owner: nil, url: "https://github.com/airbnb/lottie-ios")
//                CreditsRow(title: "SwifUI-Refresh", owner: nil, url: "https://github.com/siteline/SwiftUIRefresh")
                CreditsRow(title: "Inspiration for the settings screen", owner: "Rudrank Riyam", url:  "https://github.com/rudrankriyam/SwiftUI-Settings-Screen")
                CreditsRow(title: "SwiftUI exensions", owner: "Vatsal Manot", url:  "https://github.com/SwiftUIX/SwiftUIX")

            }
            .padding()
            
            Spacer()
        }
        .navigationBarTitle(Text("Credits"), displayMode: .inline)
        .padding()
        .background {
            Theme.backgroundColor
        }
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
