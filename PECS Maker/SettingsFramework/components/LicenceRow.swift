//
//  CreditsRow.swift
//  SwiftUI Settings Screen
//
//  Created by Andy Clynes on 08/09/20.
//  Copyright © 2020 Andy Clynes. All rights reserved.
//

import SwiftUI

struct LicenceRow: View {
    var licenceName: String
    var licenceSubheading: String
    var licenceFile: String
    @State var isExpanded: Bool = false
    
    var action: (()->()) = {}

    var body: some View {
        Button(action: {
            self.isExpanded.toggle()
            self.action()
            FeedbackManager.mediumFeedback()
        }) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(licenceName)
                        .font(.title)
                        .foregroundColor(.primary)
                    if isExpanded {
                        LicenceView(licenceFile: licenceFile)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    else {
                        Text(licenceSubheading)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            }
            //.padding(.vertical, 10)
        }
        //.customHoverEffect()
    }
}


struct LicenceRow_Previews: PreviewProvider {
    static var previews: some View {
        LicenceRow(licenceName: "MIT Licence", licenceSubheading: "Items below are used under MIT Licence:", licenceFile: "mit.txt")
    }
}
