//
//  SettingsRow.swift
//  SwiftUI Settings Screen
//
//  Created by Rudrank Riyam on 18/04/20.
//  Copyright © 2020 Rudrank Riyam. All rights reserved.
//

import SwiftUI

struct SettingsRow: View {
    var imageName: String
    var title: String
    var hasChevron = true
    var action: (()->()) = {}
    
    var body: some View {
        Button(action: {
            self.action()
            FeedbackManager.mediumFeedback()
        }) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: imageName)
                    .font(.system(size: settingsRowIconSize))
                    .foregroundColor(Color(settingsRowIconColor))
                    .frame(width: settingsRowIconSize, alignment: .center)
                    .accessibility(hidden: true)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                if hasChevron {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.vertical, 10)
        }
        //.customHoverEffect()
    }
}

struct SettingsRow2<Content>: View where Content: View {
    var imageName: String
    var title: String
    var hasChevron = true
    var destination: () -> Content

    init(imageName: String, title: String, hasChevron: Bool = true, @ViewBuilder destination: @escaping () -> Content) {
        self.imageName = imageName
        self.title = title
        self.hasChevron = hasChevron
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink(
            destination: destination) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: imageName)
                        .font(.system(size: settingsRowIconSize))
                        .foregroundColor(Color(settingsRowIconColor))
                        .frame(width: settingsRowIconSize, alignment: .center)
                        .accessibility(hidden: true)
                    Text(title)
                        .foregroundColor(.primary)
                    Spacer()
                    if hasChevron {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.vertical, 10)
            }
        
        
        
        //.customHoverEffect()
    }
}


struct SettingsRow_Previews: PreviewProvider {
    static var previews: some View {
        SettingsRow(imageName: "wand.and.stars", title: "Feature request")
    }
}
