//
//  AppVersionRow.swift
//  SwiftUI Settings Screen
//
//  Created by Rudrank Riyam on 18/04/20.
//  Copyright © 2020 Rudrank Riyam. All rights reserved.
//

import SwiftUI

struct AppVersionRow: View {
    var imageName: String
    var title: String
    var version: String
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: imageName)
                .font(.system(size: settingsRowIconSize))
                //.font(.headline)
                .foregroundColor(Color(settingsRowIconColor))
                .frame(width: settingsRowIconSize, alignment: .center)
                .accessibility(hidden: true)

            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(version)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .padding(.vertical, 10)
    }
}

struct AppVersionRow_Previews: PreviewProvider {
    static var previews: some View {
        AppVersionRow(imageName: "info.circle", title: "App version", version: "2.0")
    }
}
