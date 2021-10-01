//
//  CreditsRow.swift
//  SwiftUI Settings Screen
//
//  Created by Andy Clynes on 08/09/20.
//  Copyright © 2020 Andy Clynes. All rights reserved.
//

import SwiftUI
import LogFramework

struct CreditsRow: View {
    var title: String
    var owner: String?
    var url: String

    var body: some View {
        Button(action: {
            guard let urlObj = URL(string: self.url) else {
                logger.logError(.general, "Failed to create url for \(self.url)")
                return
            }
            FeedbackManager.mediumFeedback()
            UIApplication.shared.open(urlObj)
        }) {
            HStack() {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if owner != nil {
                        Text(owner!)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.vertical, 10)
        }
        //.customHoverEffect()
    }
}

struct CreditsRow_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LicenceRow(licenceName: "MIT Licence", licenceSubheading: "Items below are used under MIT Licence", licenceFile: "www.mit.org")
            CreditsRow(title: "Stars View", owner: "Andy Clynes", url: "www.myfamilyapp.org")
            CreditsRow(title: "Stripes View", owner: "Andy Clynes", url: "www.myfamilyapp.org")
        }
    }
}
