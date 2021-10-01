//
//  DoneButton.swift
//  PECS Maker
//
//  Created by Andy on 29/09/2021.
//

import SwiftUI

struct DoneButton : View {
    
    var action: ()->()

    var body: some View {
        
        Button(action: { action() }) {
            VStack {
                //Image(systemName: "photo")
                //.font(buttonFontImage)
                //    .padding(2)
                Text("Done")
                //.font(buttonFontTitle)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color(ColorNames.brightBlue))
            .cornerRadius(40)
        }
        
    }
}
