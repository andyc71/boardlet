//
//  SelectionHeading.swift
//  PECS Maker
//
//  Created by Andy on 30/09/2021.
//

import SwiftUI

struct SelectionHeading : View {
    var text: String
    var body: some View {
        VStack {
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                //.cornerRadius(10)
        }
        .background(Color(ColorNames.brightBlue))
        .cornerRadius(10, corners: [.topLeft, .topRight])
    }
}

